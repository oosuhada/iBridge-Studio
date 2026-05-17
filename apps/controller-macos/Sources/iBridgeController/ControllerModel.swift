import Combine
import AppKit
import ApplicationServices
import Darwin
import Foundation

enum LogLevel: String, CaseIterable, Identifiable {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"

    var id: String { rawValue }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String

    var formattedLine: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "[\(formatter.string(from: timestamp))] [\(level.rawValue)] \(message)"
    }
}

@MainActor
final class ControllerModel: ObservableObject {
    @Published var sessions: [DisplaySession] {
        didSet {
            refreshSessionObservers()
            saveStateSoon()
        }
    }
    @Published var receiverPort: String {
        didSet { saveStateSoon() }
    }
    @Published var receiverTitle: String {
        didSet { saveStateSoon() }
    }
    @Published private(set) var logEntries: [LogEntry] = [
        LogEntry(timestamp: Date(), level: .info, message: "Ready.")
    ]
    @Published var runningSenderIDs = Set<UUID>()
    @Published var busyReceiverIDs = Set<UUID>()
    @Published var localReceiverRunning = false
    @Published var remoteReceiverLastStartedAt: [UUID: Date] = [:]
    @Published var receiverProbeStatus: [UUID: String] = [:]
    @Published var availableDisplayNames: [String] = []
    @Published var localReceiverAddresses: [String] = []
    @Published var screenRecordingAllowed = false
    @Published var accessibilityAllowed = false
    @Published var isListingDisplays = false
    @Published var selectedTab: StudioTab {
        didSet { saveStateSoon() }
    }

    private var senderProcesses: [UUID: Process] = [:]
    private var receiverProcesses: [UUID: Process] = [:]
    private var localReceiverProcess: Process?
    private var sessionCancellables: [UUID: AnyCancellable] = [:]
    private var saveStateTask: Task<Void, Never>?
    private var isLoadingState = false
    private static let defaultsKey = "dev.oosu.iBridgeStudio.control.state.v2"
    private static let legacyDefaultsKeys = [
        "dev.oosu.iBridgeStudio.control.state.v1",
        "dev.oosu.iBridge.control.state.v1"
    ]
    private let defaultsKey = ControllerModel.defaultsKey
    private let maxLogEntries = 2_000

    var logText: String {
        logEntries.map(\.formattedLine).joined(separator: "\n") + "\n"
    }

    var activeStreamingCount: Int {
        runningSenderIDs.count
    }

    var hasActiveProcesses: Bool {
        !runningSenderIDs.isEmpty || localReceiverRunning
    }

    init() {
        if let state = Self.loadState() {
            receiverPort = state.receiverPort
            receiverTitle = state.receiverTitle
            selectedTab = StudioTab(rawValue: state.selectedTab) ?? .sender
            let restoredSessions = state.sessions.map { DisplaySession(stored: $0) }
            sessions = restoredSessions.isEmpty ? [DisplaySession(preset: presets[0])] : restoredSessions
        } else {
            sessions = [DisplaySession(preset: presets[0])]
            receiverPort = "48320"
            receiverTitle = "iBridge Studio Receiver"
            selectedTab = .sender
        }
        refreshSessionObservers()
        refreshPermissions()
        refreshLocalReceiverAddresses()
    }

    func addSession(preset: ReceiverPreset = presets[2], focus tab: StudioTab? = .sender) {
        let session = DisplaySession(preset: preset)
        sessions.append(session)
        if let tab {
            selectedTab = tab
        }
        append("Added sender session: \(session.name)")
    }

    func removeSession(_ session: DisplaySession) {
        stopSender(session)
        receiverProcesses[session.id]?.terminate()
        receiverProcesses[session.id] = nil
        sessions.removeAll { $0.id == session.id }
        append("Removed sender session: \(session.name)")
    }

    func listDisplays() {
        isListingDisplays = true
        runOneShot(
            command: "\(primaryCommand()) --list-displays",
            label: "Displays",
            onOutput: { [weak self] text in
                self?.captureDisplayNames(from: text)
            }
        ) { [weak self] in
            self?.isListingDisplays = false
        }
    }

    func refreshPermissions() {
        screenRecordingAllowed = CGPreflightScreenCaptureAccess()
        accessibilityAllowed = AXIsProcessTrusted()
    }

    func openScreenRecordingSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    func restoreWindowsToMacBook() {
        let command = """
        osascript <<'APPLESCRIPT'
        tell application "System Events"
          repeat with proc in application processes
            try
              if background only of proc is false then
                set procName to name of proc
                if procName is not "iBridge Studio" and procName is not "iBridge Control" and procName is not "iBridge Studio Receiver" then
                  repeat with win in windows of proc
                    try
                      set position of win to {120, 120}
                      set size of win to {1280, 820}
                    end try
                  end repeat
                end if
              end if
            end try
          end repeat
        end tell
        APPLESCRIPT
        """
        append("Restoring visible app windows to the MacBook display area.")
        append("If nothing moves, grant Accessibility permission to iBridge Studio.")
        runOneShot(command: command, label: "Restore Windows")
    }

    func startRemoteReceiver(_ session: DisplaySession) {
        guard validationIssues(for: session).filter({ $0.blocksStart }).isEmpty else {
            append("Remote receiver start skipped for \(session.name): fix validation issues first.", level: .warning)
            return
        }
        saveState()
        busyReceiverIDs.insert(session.id)
        let keyPrefix = session.receiverKey.isEmpty ? "" : "RECEIVER_KEY='\(shellEscape(expandedPath(session.receiverKey)))' "
        let command = "\(keyPrefix)\(session.receiverScript)"
        append("Starting remote receiver: \(session.name)")
        remoteReceiverLastStartedAt[session.id] = Date()
        receiverProcesses[session.id] = runOneShot(
            command: command,
            label: "\(session.name) Receiver",
            onExit: { [weak self, weak session] in
                guard let session else { return }
                self?.busyReceiverIDs.remove(session.id)
                self?.receiverProcesses[session.id] = nil
                self?.testReceiverConnection(session)
            }
        )
    }

    func repairLocalSystemSettings() {
        append("Repairing System Settings on this Mac.")
        runOneShot(command: "scripts/repair_system_settings.sh", label: "Repair Local System Settings")
    }

    func repairRemoteSystemSettings(_ session: DisplaySession) {
        guard !session.discoveryHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            append("Repair skipped for \(session.name): no Discovery host configured.")
            return
        }
        let keyOption = session.receiverKey.isEmpty ? "" : "-i '\(shellEscape(expandedPath(session.receiverKey)))' "
        let command = """
        ssh \(keyOption)'\(shellEscape(session.discoveryHost))' 'bash -s' < scripts/repair_system_settings.sh
        """
        append("Repairing System Settings on remote iMac: \(session.name)")
        runOneShot(command: command, label: "\(session.name) Repair System Settings")
    }

    func wakeReceiver(_ session: DisplaySession) {
        guard validationIssues(for: session).filter({ $0.kind == .wakeMAC || $0.kind == .wakeBroadcast }).isEmpty else {
            append("Wake skipped for \(session.name): fix Wake MAC or broadcast settings.", level: .warning)
            return
        }
        guard !session.wakeMAC.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            append("Wake skipped for \(session.name): no Wake MAC configured.")
            return
        }
        let command = """
        WAKE_MAC='\(shellEscape(session.wakeMAC))' \
        WAKE_BROADCAST='\(shellEscape(session.wakeBroadcast))' \
        WAKE_REPEAT='3' \
        scripts/wake_receiver.sh
        """
        append("Sending Wake-on-LAN packet: \(session.name)")
        runOneShot(command: command, label: "\(session.name) Wake")
    }

    func startLocalReceiver() {
        guard validateReceiverPort() else { return }
        saveState()
        stopLocalReceiver()
        let command = """
        \(receiverCommand()) \
        --port '\(shellEscape(receiverPort))' \
        --fullscreen \
        --hide-status \
        --title '\(shellEscape(receiverTitle))'
        """
        append("Starting local receiver.")
        localReceiverRunning = true
        localReceiverProcess = runOneShot(command: command, label: "Local Receiver", onExit: { [weak self] in
            self?.localReceiverRunning = false
            self?.localReceiverProcess = nil
        })
    }

    func stopLocalReceiver() {
        guard let process = localReceiverProcess else { return }
        append("Stopping local receiver.")
        terminateProcessTree(process)
        localReceiverProcess = nil
        localReceiverRunning = false
    }

    func startSender(_ session: DisplaySession) {
        refreshPermissions()
        let issues = validationIssues(for: session).filter(\.blocksStart)
        guard issues.isEmpty else {
            let message = issues.map(\.message).joined(separator: " ")
            append("Sender start blocked for \(session.name): \(message)", level: .error)
            return
        }
        saveState()
        stopSender(session)
        let runRoot = "benchmarks/runs/$(date +%Y-%m-%d_%H%M%S)_\(session.id.uuidString)_ibridge_virtual_capture"
        let command = """
        \(wakeCommandPrefix(for: session))
        echo 'Checking receiver readiness...';
        RESOLVED_RECEIVER_IP="$(RECEIVER_IP='\(shellEscape(session.receiverIP))' \
        RECEIVER_DISCOVERY_HOST='\(shellEscape(session.discoveryHost))' \
        RECEIVER_KEY='\(shellEscape(expandedPath(session.receiverKey)))' \
        RECEIVER_PORT='\(shellEscape(receiverPort))' \
        scripts/resolve_receiver_ip.sh)" && \
        RECEIVER_IP="$RESOLVED_RECEIVER_IP" \
        CAPTURE_DISPLAY_NAME='\(shellEscape(session.displayName))' \
        PROFILE='\(shellEscape(session.profile))' \
        RESOLUTION='\(shellEscape(session.resolution))' \
        BITRATE_MBPS='\(shellEscape(session.bitrateMbps))' \
        DURATION='\(shellEscape(session.duration))' \
        CAPTURE_SHOW_CURSOR='\(shellEscape(session.captureShowCursor))' \
        RUN_ROOT='\(runRoot)' \
        scripts/start_ibridge_virtual_capture.sh
        """
        append("Starting sender: \(session.name)")
        let process = makeProcess(command: command, label: "\(session.name) Sender")
        senderProcesses[session.id] = process
        runningSenderIDs.insert(session.id)
        process.terminationHandler = { [weak self, weak session] process in
            Task { @MainActor in
                guard let session else { return }
                self?.senderProcesses[session.id] = nil
                self?.runningSenderIDs.remove(session.id)
                self?.append("\(session.name) sender exited with status \(process.terminationStatus)")
            }
        }
        do {
            try process.run()
        } catch {
            senderProcesses[session.id] = nil
            runningSenderIDs.remove(session.id)
            append("Failed to start \(session.name) sender: \(error.localizedDescription)")
        }
    }

    func stopSender(_ session: DisplaySession) {
        guard let process = senderProcesses[session.id] else { return }
        append("Stopping sender: \(session.name)")
        terminateProcessTree(process)
        senderProcesses[session.id] = nil
        runningSenderIDs.remove(session.id)
    }

    func stopAllSenders() {
        for session in sessions {
            stopSender(session)
        }
    }

    func stopEverything() {
        stopAllSenders()
        stopLocalReceiver()
    }

    func isSenderRunning(_ session: DisplaySession) -> Bool {
        runningSenderIDs.contains(session.id)
    }

    func isReceiverBusy(_ session: DisplaySession) -> Bool {
        busyReceiverIDs.contains(session.id)
    }

    func validationIssues(for session: DisplaySession) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        let hasReceiver = !session.receiverIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDiscovery = !session.discoveryHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !hasReceiver && !hasDiscovery {
            issues.append(ValidationIssue(kind: .receiver, severity: .error, message: "Receiver IP or Discovery host is required.", blocksStart: true))
        }
        if hasReceiver && !isLikelyHost(session.receiverIP) {
            issues.append(ValidationIssue(kind: .receiver, severity: .warning, message: "Receiver IP looks unusual.", blocksStart: false))
        }
        if !isValidPort(receiverPort) {
            issues.append(ValidationIssue(kind: .port, severity: .error, message: "Receiver port must be 1-65535.", blocksStart: true))
        }
        if !isResolution(session.resolution) {
            issues.append(ValidationIssue(kind: .resolution, severity: .error, message: "Resolution must look like 2560x1440.", blocksStart: true))
        }
        if !isInteger(session.bitrateMbps, range: 1...500) {
            issues.append(ValidationIssue(kind: .bitrate, severity: .error, message: "Bitrate must be 1-500 Mbps.", blocksStart: true))
        }
        if !isInteger(session.duration, range: 1...86_400) {
            issues.append(ValidationIssue(kind: .duration, severity: .error, message: "Session timeout must be 1-86400 seconds.", blocksStart: true))
        }
        let wakeMAC = session.wakeMAC.trimmingCharacters(in: .whitespacesAndNewlines)
        if !wakeMAC.isEmpty && !isWakeMAC(wakeMAC) {
            issues.append(ValidationIssue(kind: .wakeMAC, severity: .error, message: "Wake MAC must be 12 hex digits.", blocksStart: true))
        }
        if session.autoWake && wakeMAC.isEmpty {
            issues.append(ValidationIssue(kind: .wakeMAC, severity: .warning, message: "Auto wake is on but Wake MAC is empty.", blocksStart: false))
        }
        if session.autoWake && session.wakeBroadcast.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(ValidationIssue(kind: .wakeBroadcast, severity: .error, message: "Wake broadcast is required when Auto wake is on.", blocksStart: true))
        }
        if !screenRecordingAllowed {
            issues.append(ValidationIssue(kind: .permission, severity: .warning, message: "Screen Recording permission is not granted.", blocksStart: false))
        }
        if !accessibilityAllowed {
            issues.append(ValidationIssue(kind: .permission, severity: .warning, message: "Accessibility permission is not granted.", blocksStart: false))
        }
        return issues
    }

    func testReceiverConnection(_ session: DisplaySession) {
        guard !session.receiverIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            receiverProbeStatus[session.id] = "No manual Receiver IP to test."
            append("Receiver test skipped for \(session.name): no manual Receiver IP.", level: .warning)
            return
        }
        receiverProbeStatus[session.id] = "Checking..."
        let command = "nc -G 2 -z '\(shellEscape(session.receiverIP))' '\(shellEscape(receiverPort))'"
        runOneShot(command: command, label: "\(session.name) Receiver Probe", onExit: { [weak self, weak session] in
            guard let self, let session else { return }
            // Process status is logged by runOneShot; this text is intentionally conservative.
            self.receiverProbeStatus[session.id] = "Probe finished. Check Logs for the exact nc status."
        })
    }

    func copyReceiverAddress(_ address: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("\(address):\(receiverPort)", forType: .string)
        append("Copied receiver address \(address):\(receiverPort)")
    }

    func filteredLogText(level: LogLevel?, sessionName: String?) -> String {
        let filtered = logEntries.filter { entry in
            let levelMatches = level == nil || entry.level == level
            let sessionMatches = sessionName == nil || entry.message.contains("[\(sessionName!)]")
            return levelMatches && sessionMatches
        }
        return filtered.map { maskSensitive($0.formattedLine) }.joined(separator: "\n") + "\n"
    }

    func exportSupportBundle() {
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
            .appendingPathComponent("iBridge-Studio-Diagnostics-\(timestamp)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let text = filteredLogText(level: nil, sessionName: nil)
            try text.write(to: directory.appendingPathComponent("runtime-log.txt"), atomically: true, encoding: .utf8)
            let summary = """
            iBridge Studio diagnostics
            Generated: \(Date())
            Version: 0.1.1-alpha
            Sessions: \(sessions.count)
            Receiver port: \(receiverPort)
            Screen Recording: \(screenRecordingAllowed ? "granted" : "missing")
            Accessibility: \(accessibilityAllowed ? "granted" : "missing")
            """
            try summary.write(to: directory.appendingPathComponent("summary.txt"), atomically: true, encoding: .utf8)
            append("Exported diagnostics to \(directory.path)")
        } catch {
            append("Failed to export diagnostics: \(error.localizedDescription)", level: .error)
        }
    }

    @discardableResult
    private func runOneShot(
        command: String,
        label: String,
        onOutput: (@MainActor @Sendable (String) -> Void)? = nil,
        onExit: (@MainActor @Sendable () -> Void)? = nil
    ) -> Process {
        append("$ \(label): \(command)")
        let process = makeProcess(command: command, label: label, onOutput: onOutput)
        process.terminationHandler = { [weak self] process in
            Task { @MainActor in
                let level: LogLevel = process.terminationStatus == 0 ? .info : .error
                self?.append("\(label) exited with status \(process.terminationStatus)", level: level)
                onExit?()
            }
        }
        do {
            try process.run()
        } catch {
            append("Failed \(label): \(error.localizedDescription)")
            onExit?()
        }
        return process
    }

    private func makeProcess(
        command: String,
        label: String,
        onOutput: (@MainActor @Sendable (String) -> Void)? = nil
    ) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.currentDirectoryURL = repoRoot
        process.arguments = [
            "-lc",
            """
            trap 'status=$?; trap - TERM INT EXIT; pkill -TERM -P $$ 2>/dev/null || true; exit $status' TERM INT EXIT
            \(command)
            """
        ]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            guard let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                self?.appendOutput(text, label: label)
                onOutput?(text)
            }
        }
        return process
    }

    private func terminateProcessTree(_ process: Process) {
        let pid = process.processIdentifier
        process.terminate()
        if pid > 0 {
            _ = kill(pid_t(pid), SIGTERM)
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            task.arguments = ["-TERM", "-P", "\(pid)"]
            try? task.run()
        }
    }

    private func appendOutput(_ text: String, label: String) {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines where !line.isEmpty {
            append("[\(label)] \(line)")
        }
    }

    func clearLog() {
        logEntries = [LogEntry(timestamp: Date(), level: .info, message: "Ready.")]
    }

    private func append(_ text: String, level: LogLevel = .info) {
        let cleanText = text.trimmingCharacters(in: .newlines)
        guard !cleanText.isEmpty else { return }
        logEntries.append(LogEntry(timestamp: Date(), level: level, message: cleanText))
        if logEntries.count > maxLogEntries {
            logEntries.removeFirst(logEntries.count - maxLogEntries)
        }
    }

    private func shellEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\\''")
    }

    private func wakeCommandPrefix(for session: DisplaySession) -> String {
        guard session.autoWake,
              !session.wakeMAC.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }
        return """
        WAKE_MAC='\(shellEscape(session.wakeMAC))' \
        WAKE_BROADCAST='\(shellEscape(session.wakeBroadcast))' \
        WAKE_REPEAT='3' \
        WAKE_WAIT_HOST='\(shellEscape(session.receiverIP))' \
        WAKE_WAIT_PORT='\(shellEscape(receiverPort))' \
        WAKE_WAIT_TIMEOUT='30' \
        scripts/wake_receiver.sh || true;
        """
    }

    private func validateReceiverPort() -> Bool {
        guard isValidPort(receiverPort) else {
            append("Receiver port must be 1-65535.", level: .error)
            return false
        }
        return true
    }

    private func captureDisplayNames(from text: String) {
        let pattern = #"name="([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let names = regex.matches(in: text, range: range).compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
        let merged = Array(Set(availableDisplayNames + names)).sorted()
        if !merged.isEmpty {
            availableDisplayNames = merged
        }
    }

    func refreshLocalReceiverAddresses() {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "ifconfig | awk '/^[a-z0-9]+:/ { iface=$1; sub(\":\", \"\", iface) } /inet / && $2 !~ /^127\\./ { print iface \" \" $2 }'"]
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? ""
            localReceiverAddresses = text
                .split(separator: "\n")
                .map(String.init)
                .filter { !$0.isEmpty }
        } catch {
            localReceiverAddresses = []
        }
    }

    private func expandedPath(_ value: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return value
            .replacingOccurrences(of: "$HOME", with: home)
            .replacingOccurrences(of: "~", with: home, options: [.anchored])
    }

    private func primaryCommand() -> String {
        if FileManager.default.isExecutableFile(atPath: repoRoot.appendingPathComponent("bin/ibridge-primary").path) {
            return "bin/ibridge-primary"
        }
        return "apps/primary-macos/.build/release/ibridge-primary"
    }

    private func receiverCommand() -> String {
        if FileManager.default.isExecutableFile(atPath: repoRoot.appendingPathComponent("bin/ibridge-receiver-macos-universal").path) {
            return "bin/ibridge-receiver-macos-universal"
        }
        return "apps/receiver-macos/.build/release/ibridge-receiver-macos"
    }

    private func refreshSessionObservers() {
        let currentIDs = Set(sessions.map(\.id))
        sessionCancellables = sessionCancellables.filter { currentIDs.contains($0.key) }

        for session in sessions where sessionCancellables[session.id] == nil {
            sessionCancellables[session.id] = session.objectWillChange.sink { [weak self] _ in
                Task { @MainActor in
                    self?.saveStateSoon()
                }
            }
        }
    }

    private func saveStateSoon() {
        guard !isLoadingState else { return }
        saveStateTask?.cancel()
        saveStateTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.saveState()
            }
        }
    }

    private func saveStateNow() {
        saveStateTask?.cancel()
        saveStateTask = nil
        saveState()
    }

    private func saveState() {
        guard !isLoadingState else { return }
        let state = StoredControllerState(
            schemaVersion: StoredControllerState.currentSchemaVersion,
            selectedTab: selectedTab.rawValue,
            receiverPort: receiverPort,
            receiverTitle: receiverTitle,
            sessions: sessions.map { $0.stored() }
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private static func loadState() -> StoredControllerState? {
        let defaults = UserDefaults.standard
        let candidateKeys = [defaultsKey] + legacyDefaultsKeys
        for key in candidateKeys {
            guard let data = defaults.data(forKey: key),
                  let state = try? JSONDecoder().decode(StoredControllerState.self, from: data) else {
                continue
            }
            return migrate(state)
        }
        return nil
    }

    private static func migrate(_ state: StoredControllerState) -> StoredControllerState {
        guard state.schemaVersion < StoredControllerState.currentSchemaVersion else {
            return state
        }
        return StoredControllerState(
            schemaVersion: StoredControllerState.currentSchemaVersion,
            selectedTab: state.selectedTab,
            receiverPort: state.receiverPort,
            receiverTitle: state.receiverTitle,
            sessions: state.sessions
        )
    }

    deinit {
        saveStateTask?.cancel()
    }
}

enum ValidationKind {
    case receiver
    case port
    case resolution
    case bitrate
    case duration
    case wakeMAC
    case wakeBroadcast
    case permission
}

struct ValidationIssue: Identifiable {
    let id = UUID()
    let kind: ValidationKind
    let severity: LogLevel
    let message: String
    let blocksStart: Bool
}

private func isInteger(_ value: String, range: ClosedRange<Int>) -> Bool {
    guard let intValue = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) else { return false }
    return range.contains(intValue)
}

private func isValidPort(_ value: String) -> Bool {
    isInteger(value, range: 1...65_535)
}

private func isResolution(_ value: String) -> Bool {
    value.range(of: #"^\d{3,5}x\d{3,5}$"#, options: .regularExpression) != nil
}

private func isWakeMAC(_ value: String) -> Bool {
    let compact = value.replacingOccurrences(of: #"[^0-9A-Fa-f]"#, with: "", options: .regularExpression)
    return compact.count == 12
}

private func isLikelyHost(_ value: String) -> Bool {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.range(of: #"^[A-Za-z0-9._:-]+$"#, options: .regularExpression) != nil
}

private func maskSensitive(_ value: String) -> String {
    var output = value
    output = output.replacingOccurrences(
        of: #"([A-Za-z0-9._%+-]+)@([A-Za-z0-9._-]+)"#,
        with: "<user>@$2",
        options: .regularExpression
    )
    output = output.replacingOccurrences(
        of: #"([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}"#,
        with: "<mac-address>",
        options: .regularExpression
    )
    output = output.replacingOccurrences(
        of: #"/Users/[^/\s']+"#,
        with: "/Users/<user>",
        options: .regularExpression
    )
    return output
}
