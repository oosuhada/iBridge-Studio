import Combine
import Foundation

@MainActor
final class ControllerModel: ObservableObject {
    @Published var sessions: [DisplaySession] {
        didSet {
            refreshSessionObservers()
            saveState()
        }
    }
    @Published var receiverPort: String {
        didSet { saveState() }
    }
    @Published var receiverTitle: String {
        didSet { saveState() }
    }
    @Published var log = "Ready.\n"
    @Published var runningSenderIDs = Set<UUID>()
    @Published var busyReceiverIDs = Set<UUID>()
    @Published var isListingDisplays = false
    @Published var selectedTab: StudioTab {
        didSet { saveState() }
    }

    private var senderProcesses: [UUID: Process] = [:]
    private var receiverProcesses: [UUID: Process] = [:]
    private var sessionCancellables: [UUID: AnyCancellable] = [:]
    private var isLoadingState = false
    private static let defaultsKey = "dev.oosu.iBridgeStudio.control.state.v1"
    private static let legacyDefaultsKey = "dev.oosu.iBridge.control.state.v1"
    private let defaultsKey = ControllerModel.defaultsKey

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
            label: "Displays"
        ) { [weak self] in
            self?.isListingDisplays = false
        }
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
        saveState()
        busyReceiverIDs.insert(session.id)
        let keyPrefix = session.receiverKey.isEmpty ? "" : "RECEIVER_KEY=\(session.receiverKey) "
        let command = "\(keyPrefix)\(session.receiverScript)"
        append("Starting remote receiver: \(session.name)")
        receiverProcesses[session.id] = runOneShot(
            command: command,
            label: "\(session.name) Receiver"
        ) { [weak self, weak session] in
            guard let session else { return }
            self?.busyReceiverIDs.remove(session.id)
        }
    }

    func startLocalReceiver() {
        saveState()
        let command = """
        \(receiverCommand()) \
        --port '\(shellEscape(receiverPort))' \
        --fullscreen \
        --hide-status \
        --title '\(shellEscape(receiverTitle))'
        """
        append("Starting local receiver.")
        runOneShot(command: command, label: "Local Receiver")
    }

    func startSender(_ session: DisplaySession) {
        saveState()
        stopSender(session)
        let command = """
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
        process.terminate()
        senderProcesses[session.id] = nil
        runningSenderIDs.remove(session.id)
    }

    func stopAllSenders() {
        for session in sessions {
            stopSender(session)
        }
    }

    func isSenderRunning(_ session: DisplaySession) -> Bool {
        runningSenderIDs.contains(session.id)
    }

    func isReceiverBusy(_ session: DisplaySession) -> Bool {
        busyReceiverIDs.contains(session.id)
    }

    @discardableResult
    private func runOneShot(
        command: String,
        label: String,
        onExit: (@MainActor @Sendable () -> Void)? = nil
    ) -> Process {
        append("$ \(label): \(command)")
        let process = makeProcess(command: command, label: label)
        process.terminationHandler = { [weak self] process in
            Task { @MainActor in
                self?.append("\(label) exited with status \(process.terminationStatus)")
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

    private func makeProcess(command: String, label: String) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "cd '\(repoRoot.path)' && \(command)"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                self?.appendOutput(text, label: label)
            }
        }
        return process
    }

    private func appendOutput(_ text: String, label: String) {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines where !line.isEmpty {
            log += "[\(label)] \(line)\n"
        }
    }

    private func append(_ text: String) {
        log += text.hasSuffix("\n") ? text : "\(text)\n"
    }

    private func shellEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\\''")
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
        Task { @MainActor in
            saveState()
        }
    }

    private func saveState() {
        guard !isLoadingState else { return }
        let state = StoredControllerState(
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
        guard let data = defaults.data(forKey: defaultsKey) ?? defaults.data(forKey: legacyDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(StoredControllerState.self, from: data)
    }
}
