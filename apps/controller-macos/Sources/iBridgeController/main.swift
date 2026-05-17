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

struct ValueOption: Identifiable, Hashable {
    let id: String
    let title: String
    let value: String
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

private let signalOptions = [
    ValueOption(id: "5k", title: "5K Retina Quality", value: "5120x2880"),
    ValueOption(id: "imac4k", title: "iMac 4K Native", value: "4096x2304"),
    ValueOption(id: "uhd", title: "UHD Quality", value: "3840x2160"),
    ValueOption(id: "qhd", title: "1440p Smooth", value: "2560x1440"),
    ValueOption(id: "custom", title: "Custom", value: "")
]

private let bitrateOptions = [
    ValueOption(id: "80", title: "80 Mbps Smooth", value: "80"),
    ValueOption(id: "160", title: "160 Mbps Quality", value: "160"),
    ValueOption(id: "220", title: "220 Mbps 4K Quality", value: "220"),
    ValueOption(id: "280", title: "280 Mbps 5K Quality", value: "280"),
    ValueOption(id: "custom", title: "Custom", value: "")
]

private let durationOptions = [
    ValueOption(id: "10m", title: "10 min", value: "600"),
    ValueOption(id: "30m", title: "30 min", value: "1800"),
    ValueOption(id: "1h", title: "1 hour", value: "3600"),
    ValueOption(id: "custom", title: "Custom", value: "")
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
    @Published var signalOptionID: String
    @Published var bitrateOptionID: String
    @Published var durationOptionID: String

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
        signalOptionID = signalOptions.first { $0.value == preset.resolution }?.id ?? "custom"
        bitrateOptionID = bitrateOptions.first { $0.value == preset.bitrateMbps }?.id ?? "custom"
        durationOptionID = durationOptions.first { $0.value == preset.duration }?.id ?? "custom"
    }

    func apply(_ preset: ReceiverPreset) {
        name = preset.name
        receiverIP = preset.receiverIP
        displayName = preset.displayName
        profile = preset.profile
        receiverScript = preset.receiverScript
        receiverKey = preset.receiverKey
        setResolution(preset.resolution)
        setBitrate(preset.bitrateMbps)
        setDuration(preset.duration)
    }

    func setResolution(_ value: String) {
        resolution = value
        signalOptionID = signalOptions.first { $0.value == value }?.id ?? "custom"
    }

    func setBitrate(_ value: String) {
        bitrateMbps = value
        bitrateOptionID = bitrateOptions.first { $0.value == value }?.id ?? "custom"
    }

    func setDuration(_ value: String) {
        duration = value
        durationOptionID = durationOptions.first { $0.value == value }?.id ?? "custom"
    }
}

@MainActor
final class ControllerModel: ObservableObject {
    @Published var sessions: [DisplaySession] = [
        DisplaySession(preset: presets[0])
    ]
    @Published var receiverPort = "48320"
    @Published var receiverTitle = "iBridge Receiver"
    @Published var log = "Ready.\n"
    @Published var runningSenderIDs = Set<UUID>()
    @Published var busyReceiverIDs = Set<UUID>()
    @Published var isListingDisplays = false

    private var senderProcesses: [UUID: Process] = [:]
    private var receiverProcesses: [UUID: Process] = [:]

    func addSession(preset: ReceiverPreset = presets[2]) {
        let session = DisplaySession(preset: preset)
        sessions.append(session)
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
            command: "apps/primary-macos/.build/release/ibridge-primary --list-displays",
            label: "Displays"
        ) { [weak self] in
            self?.isListingDisplays = false
        }
    }

    func startRemoteReceiver(_ session: DisplaySession) {
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
        let command = """
        apps/receiver-macos/.build/release/ibridge-receiver-macos \
        --port '\(shellEscape(receiverPort))' \
        --fullscreen \
        --hide-status \
        --title '\(shellEscape(receiverTitle))'
        """
        append("Starting local receiver.")
        _ = runOneShot(command: command, label: "Local Receiver")
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
            TabView {
                SenderTab(model: model)
                    .tabItem {
                        Label("Sender", systemImage: "macbook.and.iphone")
                    }
                ReceiverTab(model: model)
                    .tabItem {
                        Label("Receiver", systemImage: "display")
                    }
                LogTab(model: model)
                    .tabItem {
                        Label("Logs", systemImage: "list.bullet.rectangle")
                    }
            }
            .padding(.top, 4)
        }
        .frame(minWidth: 1100, minHeight: 720)
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
                Text("Use retired iMacs as software Retina displays")
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

            Button(role: .destructive) {
                model.stopAllSenders()
            } label: {
                Label("Stop All", systemImage: "stop.fill")
            }
        }
        .padding(16)
    }
}

struct SenderTab: View {
    @ObservedObject var model: ControllerModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Sender Sessions")
                    .font(.title3.weight(.semibold))
                Spacer()
                Menu {
                    ForEach(presets) { preset in
                        Button(preset.name) {
                            model.addSession(preset: preset)
                        }
                    }
                } label: {
                    Label("Add Sender", systemImage: "plus")
                }
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(model.sessions) { session in
                        SenderSessionCard(session: session, model: model)
                    }
                }
            }
        }
        .padding(16)
    }
}

struct ReceiverTab: View {
    @ObservedObject var model: ControllerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receiver Setup")
                .font(.title3.weight(.semibold))

            GroupBox("This Mac as Receiver") {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("Port")
                        TextField("Port", text: $model.receiverPort)
                            .frame(width: 140)
                    }
                    GridRow {
                        Text("Title")
                        TextField("Window title", text: $model.receiverTitle)
                            .frame(width: 280)
                    }
                }
                .textFieldStyle(.roundedBorder)

                Button {
                    model.startLocalReceiver()
                } label: {
                    Label("Start Receiver on This Mac", systemImage: "play.rectangle")
                }
                .padding(.top, 8)
            }

            GroupBox("Remote Receiver Shortcuts") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.sessions) { session in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(session.name)
                                    .font(.headline)
                                Text("\(session.receiverIP) / \(session.receiverScript)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                model.startRemoteReceiver(session)
                            } label: {
                                Label("Start", systemImage: "play.fill")
                            }
                            .disabled(model.isReceiverBusy(session))
                        }
                        if session.id != model.sessions.last?.id {
                            Divider()
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(16)
    }
}

struct LogTab: View {
    @ObservedObject var model: ControllerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Runtime Log")
                .font(.title3.weight(.semibold))
            TextEditor(text: $model.log)
                .font(.system(.caption, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(16)
    }
}

struct LogoMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [.blue.opacity(0.95), .teal.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.white, lineWidth: 2)
                    .frame(width: 17, height: 12)
                Capsule()
                    .fill(.white)
                    .frame(width: 12, height: 3)
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.white, lineWidth: 2)
                    .frame(width: 17, height: 12)
            }
        }
        .frame(width: 48, height: 36)
    }
}

struct SenderSessionCard: View {
    @ObservedObject var session: DisplaySession
    @ObservedObject var model: ControllerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
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

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text("Receiver")
                    TextField("Receiver IP", text: $session.receiverIP)
                    Text("Display")
                    TextField("Virtual display name", text: $session.displayName)
                }
                GridRow {
                    Text("Preset")
                    Picker("Signal preset", selection: $session.signalOptionID) {
                        ForEach(signalOptions) { option in
                            Text(option.title).tag(option.id)
                        }
                    }
                    .onChange(of: session.signalOptionID) { _, newValue in
                        if let option = signalOptions.first(where: { $0.id == newValue }), option.id != "custom" {
                            session.resolution = option.value
                        }
                    }
                    Text("Signal")
                    TextField("Resolution", text: $session.resolution)
                        .disabled(session.signalOptionID != "custom")
                }
                GridRow {
                    Text("Profile")
                    TextField("Profile", text: $session.profile)
                    Text("Bitrate")
                    HStack {
                        Picker("Bitrate", selection: $session.bitrateOptionID) {
                            ForEach(bitrateOptions) { option in
                                Text(option.title).tag(option.id)
                            }
                        }
                        .onChange(of: session.bitrateOptionID) { _, newValue in
                            if let option = bitrateOptions.first(where: { $0.id == newValue }), option.id != "custom" {
                                session.bitrateMbps = option.value
                            }
                        }
                        TextField("Mbps", text: $session.bitrateMbps)
                            .frame(width: 70)
                            .disabled(session.bitrateOptionID != "custom")
                    }
                }
                GridRow {
                    Text("Duration")
                    Picker("Duration", selection: $session.durationOptionID) {
                        ForEach(durationOptions) { option in
                            Text(option.title).tag(option.id)
                        }
                    }
                    .onChange(of: session.durationOptionID) { _, newValue in
                        if let option = durationOptions.first(where: { $0.id == newValue }), option.id != "custom" {
                            session.duration = option.value
                        }
                    }
                    Text("Seconds")
                    TextField("Seconds", text: $session.duration)
                        .disabled(session.durationOptionID != "custom")
                }
            }
            .textFieldStyle(.roundedBorder)

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
