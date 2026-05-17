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
final class ControllerModel: ObservableObject {
    @Published var selectedPreset = presets[0]
    @Published var receiverIP = presets[0].receiverIP
    @Published var displayName = presets[0].displayName
    @Published var profile = presets[0].profile
    @Published var resolution = presets[0].resolution
    @Published var bitrateMbps = presets[0].bitrateMbps
    @Published var duration = presets[0].duration
    @Published var log = "Ready.\n"
    @Published var isSenderRunning = false
    @Published var isBusy = false

    private var senderProcess: Process?

    func applyPreset(_ preset: ReceiverPreset) {
        selectedPreset = preset
        receiverIP = preset.receiverIP
        displayName = preset.displayName
        profile = preset.profile
        resolution = preset.resolution
        bitrateMbps = preset.bitrateMbps
        duration = preset.duration
        append("Selected \(preset.name)")
    }

    func listDisplays() {
        runOneShot("apps/primary-macos/.build/release/ibridge-primary --list-displays")
    }

    func startReceiver() {
        let keyPrefix = selectedPreset.receiverKey.isEmpty ? "" : "RECEIVER_KEY=\(selectedPreset.receiverKey) "
        runOneShot("\(keyPrefix)\(selectedPreset.receiverScript)")
    }

    func startSender() {
        stopSender()
        let command = """
        RECEIVER_IP='\(shellEscape(receiverIP))' \
        CAPTURE_DISPLAY_NAME='\(shellEscape(displayName))' \
        PROFILE='\(shellEscape(profile))' \
        RESOLUTION='\(shellEscape(resolution))' \
        BITRATE_MBPS='\(shellEscape(bitrateMbps))' \
        DURATION='\(shellEscape(duration))' \
        scripts/start_ibridge_virtual_capture.sh
        """
        append("Starting sender: \(selectedPreset.name)")
        senderProcess = makeProcess(command: command)
        guard let senderProcess else { return }
        isSenderRunning = true
        senderProcess.terminationHandler = { [weak self] process in
            Task { @MainActor in
                self?.isSenderRunning = false
                self?.append("Sender exited with status \(process.terminationStatus)")
            }
        }
        do {
            try senderProcess.run()
        } catch {
            isSenderRunning = false
            append("Failed to start sender: \(error.localizedDescription)")
        }
    }

    func stopSender() {
        guard let senderProcess else { return }
        append("Stopping sender.")
        senderProcess.terminate()
        self.senderProcess = nil
        isSenderRunning = false
    }

    func openRepoInTerminal() {
        NSWorkspace.shared.open(repoRoot)
    }

    private func runOneShot(_ command: String) {
        isBusy = true
        append("$ \(command)")
        let process = makeProcess(command: command)
        process.terminationHandler = { [weak self] process in
            Task { @MainActor in
                self?.isBusy = false
                self?.append("Command exited with status \(process.terminationStatus)")
            }
        }
        do {
            try process.run()
        } catch {
            isBusy = false
            append("Failed: \(error.localizedDescription)")
        }
    }

    private func makeProcess(command: String) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "cd '\(repoRoot.path)' && \(command)"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in self?.append(text) }
        }
        return process
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
            HStack {
                Picker("Preset", selection: $model.selectedPreset) {
                    ForEach(presets) { preset in
                        Text(preset.name).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: model.selectedPreset) { _, newPreset in
                    model.applyPreset(newPreset)
                }

                Spacer()

                Circle()
                    .fill(model.isSenderRunning ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                Text(model.isSenderRunning ? "Streaming" : "Idle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text("Receiver IP")
                    TextField("Receiver IP", text: $model.receiverIP)
                }
                GridRow {
                    Text("Display")
                    TextField("Capture display name", text: $model.displayName)
                }
                GridRow {
                    Text("Profile")
                    TextField("Profile", text: $model.profile)
                }
                GridRow {
                    Text("Resolution")
                    TextField("Resolution", text: $model.resolution)
                }
                GridRow {
                    Text("Bitrate")
                    TextField("Mbps", text: $model.bitrateMbps)
                }
                GridRow {
                    Text("Duration")
                    TextField("Seconds", text: $model.duration)
                }
            }
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)

            HStack {
                Button("List Displays") { model.listDisplays() }
                Button("Start Receiver") { model.startReceiver() }
                Button("Start Sender") { model.startSender() }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(model.isSenderRunning)
                Button("Stop Sender") { model.stopSender() }
                    .disabled(!model.isSenderRunning)
                Spacer()
                Button("Open Repo") { model.openRepoInTerminal() }
            }
            .padding()

            TextEditor(text: $model.log)
                .font(.system(.caption, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .border(Color.gray.opacity(0.25))
                .padding([.horizontal, .bottom])
        }
        .frame(minWidth: 780, minHeight: 620)
    }
}

@main
struct IBridgeControllerApp: App {
    var body: some Scene {
        WindowGroup("iBridge Control") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
