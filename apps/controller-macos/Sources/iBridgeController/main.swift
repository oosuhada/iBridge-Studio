import AppKit
import Foundation
import SwiftUI

private let repoRoot = URL(fileURLWithPath: "/Users/gabriel/Development/iBridge", isDirectory: true)

struct ReceiverPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let receiverIP: String
    let displayName: String
    let profile: String
    let resolution: String
    let bitrateMbps: String
    let duration: String
    let receiverScript: String
    let receiverKey: String
}

private let presets: [ReceiverPreset] = [
    ReceiverPreset(
        id: "imac-2015-quality",
        name: "2015 iMac 5K Quality",
        receiverIP: "169.254.99.112",
        displayName: "iMac 27inch 2015",
        profile: "lan-60hz",
        resolution: "5120x2880",
        bitrateMbps: "280",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    ),
    ReceiverPreset(
        id: "imac-2015-smooth",
        name: "2015 iMac Smooth",
        receiverIP: "169.254.99.112",
        displayName: "iMac 27inch 2015",
        profile: "lan-60hz",
        resolution: "2560x1440",
        bitrateMbps: "80",
        duration: "600",
        receiverScript: "scripts/start_2015_imac_receiver_macos.sh",
        receiverKey: "$HOME/.ssh/id_ed25519"
    ),
    ReceiverPreset(
        id: "imac-2017-quality",
        name: "2017 iMac 4K Quality",
        receiverIP: "169.254.70.114",
        displayName: "iMac 21.5inch 2017",
        profile: "imac4k-quality",
        resolution: "4096x2304",
        bitrateMbps: "220",
        duration: "600",
        receiverScript: "scripts/start_2017_imac_receiver_macos.sh",
        receiverKey: ""
    )
]

@MainActor
final class DisplaySession: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var receiverIP: String
    @Published var displayName: String
    @Published var profile: String
    @Published var resolution: String
    @Published var bitrateMbps: String
    @Published var duration: String
    @Published var receiverScript: String
    @Published var receiverKey: String

    init(preset: ReceiverPreset) {
        name = preset.name
        receiverIP = preset.receiverIP
        displayName = preset.displayName
        profile = preset.profile
        resolution = preset.resolution
        bitrateMbps = preset.bitrateMbps
        duration = preset.duration
        receiverScript = preset.receiverScript
        receiverKey = preset.receiverKey
    }

    func apply(_ preset: ReceiverPreset) {
        name = preset.name
        receiverIP = preset.receiverIP
        displayName = preset.displayName
        profile = preset.profile
        resolution = preset.resolution
        bitrateMbps = preset.bitrateMbps
        duration = preset.duration
        receiverScript = preset.receiverScript
        receiverKey = preset.receiverKey
    }
}

@MainActor
final class ControllerModel: ObservableObject {
    @Published var sessions: [DisplaySession] = [
        DisplaySession(preset: presets[0])
    ]
    @Published var log = "Ready.\n"
    @Published var runningSenderIDs = Set<UUID>()
    @Published var busyReceiverIDs = Set<UUID>()
    @Published var isListingDisplays = false

    private var senderProcesses: [UUID: Process] = [:]
    private var receiverProcesses: [UUID: Process] = [:]

    func addSession(preset: ReceiverPreset = presets[2]) {
        let session = DisplaySession(preset: preset)
        sessions.append(session)
        append("Added session: \(session.name)")
    }

    func removeSession(_ session: DisplaySession) {
        stopSender(session)
        receiverProcesses[session.id]?.terminate()
        receiverProcesses[session.id] = nil
        sessions.removeAll { $0.id == session.id }
        append("Removed session: \(session.name)")
    }

    func listDisplays() {
        isListingDisplays = true
        runOneShot(
            command: "apps/primary-macos/.build/release/ibridge-primary --list-displays",
            label: "List Displays"
        ) { [weak self] in
            self?.isListingDisplays = false
        }
    }

    func startReceiver(_ session: DisplaySession) {
        busyReceiverIDs.insert(session.id)
        let keyPrefix = session.receiverKey.isEmpty ? "" : "RECEIVER_KEY=\(session.receiverKey) "
        let command = "\(keyPrefix)\(session.receiverScript)"
        append("Starting receiver: \(session.name)")
        receiverProcesses[session.id] = runOneShot(
            command: command,
            label: "\(session.name) Receiver"
        ) { [weak self, weak session] in
            guard let session else { return }
            self?.busyReceiverIDs.remove(session.id)
        }
    }

    func startSender(_ session: DisplaySession) {
        stopSender(session)
        let command = """
        RECEIVER_IP='\(shellEscape(session.receiverIP))' \
        CAPTURE_DISPLAY_NAME='\(shellEscape(session.displayName))' \
        PROFILE='\(shellEscape(session.profile))' \
        RESOLUTION='\(shellEscape(session.resolution))' \
        BITRATE_MBPS='\(shellEscape(session.bitrateMbps))' \
        DURATION='\(shellEscape(session.duration))' \
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

    func openRepo() {
        NSWorkspace.shared.open(repoRoot)
    }

    func isSenderRunning(_ session: DisplaySession) -> Bool {
        runningSenderIDs.contains(session.id)
    }

    func isReceiverBusy(_ session: DisplaySession) -> Bool {
        busyReceiverIDs.contains(session.id)
    }

    @discardableResult
    private func runOneShot(command: String, label: String, onExit: (@MainActor @Sendable () -> Void)? = nil) -> Process {
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
}

struct ContentView: View {
    @StateObject private var model = ControllerModel()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(model: model)

            Divider()

            HStack(alignment: .top, spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(model.sessions) { session in
                            SessionCard(session: session, model: model)
                        }
                    }
                    .padding(16)
                }
                .frame(minWidth: 720)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Runtime Log")
                        .font(.headline)
                    TextEditor(text: $model.log)
                        .font(.system(.caption, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(16)
                .frame(minWidth: 420)
            }
        }
        .frame(minWidth: 1180, minHeight: 720)
    }
}

struct HeaderView: View {
    @ObservedObject var model: ControllerModel

    var body: some View {
        HStack(spacing: 16) {
            LogoMark()
            VStack(alignment: .leading, spacing: 2) {
                Text("iBridge Studio")
                    .font(.title3.weight(.semibold))
                Text("Multi-iMac display sessions from one MacBook")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                model.listDisplays()
            } label: {
                Label("Refresh Displays", systemImage: "display.2")
            }
            .disabled(model.isListingDisplays)

            Menu {
                ForEach(presets) { preset in
                    Button(preset.name) {
                        model.addSession(preset: preset)
                    }
                }
            } label: {
                Label("Add Session", systemImage: "plus")
            }

            Button(role: .destructive) {
                model.stopAllSenders()
            } label: {
                Label("Stop All", systemImage: "stop.fill")
            }
        }
        .padding(16)
    }
}

struct LogoMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.18))
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.blue, lineWidth: 2)
                    .frame(width: 18, height: 13)
                Capsule()
                    .fill(.blue)
                    .frame(width: 12, height: 3)
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.teal, lineWidth: 2)
                    .frame(width: 18, height: 13)
            }
        }
        .frame(width: 58, height: 42)
    }
}

struct SessionCard: View {
    @ObservedObject var session: DisplaySession
    @ObservedObject var model: ControllerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Session name", text: $session.name)
                        .font(.headline)
                        .textFieldStyle(.plain)
                    Text(session.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusPill(
                    title: model.isSenderRunning(session) ? "Streaming" : "Idle",
                    color: model.isSenderRunning(session) ? .green : .gray
                )

                Menu {
                    ForEach(presets) { preset in
                        Button(preset.name) {
                            session.apply(preset)
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }

                Button(role: .destructive) {
                    model.removeSession(session)
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(model.sessions.count <= 1)
            }

            HStack(alignment: .top, spacing: 12) {
                GroupBox("Receiver") {
                    Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                        GridRow {
                            Text("IP")
                            TextField("Receiver IP", text: $session.receiverIP)
                        }
                        GridRow {
                            Text("Start")
                            TextField("Receiver script", text: $session.receiverScript)
                        }
                        GridRow {
                            Text("SSH key")
                            TextField("Optional key", text: $session.receiverKey)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .font(.callout)

                    HStack {
                        Button {
                            model.startReceiver(session)
                        } label: {
                            Label("Start Receiver", systemImage: "play.rectangle")
                        }
                        .disabled(model.isReceiverBusy(session))
                        Spacer()
                    }
                    .padding(.top, 8)
                }

                GroupBox("Sender") {
                    Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                        GridRow {
                            Text("Display")
                            TextField("Virtual display name", text: $session.displayName)
                        }
                        GridRow {
                            Text("Profile")
                            TextField("Profile", text: $session.profile)
                        }
                        GridRow {
                            Text("Signal")
                            TextField("Resolution", text: $session.resolution)
                        }
                        GridRow {
                            Text("Mbps")
                            TextField("Bitrate", text: $session.bitrateMbps)
                        }
                        GridRow {
                            Text("Seconds")
                            TextField("Duration", text: $session.duration)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .font(.callout)

                    HStack {
                        Button {
                            model.startSender(session)
                        } label: {
                            Label("Start Sender", systemImage: "play.fill")
                        }
                        .disabled(model.isSenderRunning(session))

                        Button {
                            model.stopSender(session)
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .disabled(!model.isSenderRunning(session))

                        Spacer()
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

struct StatusPill: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }
}

@main
struct IBridgeControllerApp: App {
    var body: some Scene {
        WindowGroup("iBridge Studio") {
            ContentView()
        }
    }
}
