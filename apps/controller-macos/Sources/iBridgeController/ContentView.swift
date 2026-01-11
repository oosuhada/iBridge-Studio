import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: ControllerModel

    var body: some View {
        ZStack {
            StudioBackdrop()
            VStack(spacing: 0) {
                HeaderView()
                Divider().opacity(0.6)
                StudioTabPicker()
                Divider().opacity(0.45)
                Group {
                    switch model.selectedTab {
                    case .sender:
                        SenderTab()
                    case .receiver:
                        ReceiverTab()
                    case .logs:
                        LogTab()
                    }
                }
            }
        }
        .background(WindowChromeConfigurator())
        .frame(minWidth: 760, minHeight: 720)
    }
}

struct StudioTabPicker: View {
    @EnvironmentObject private var model: ControllerModel

    var body: some View {
        HStack {
            Spacer()

            Picker("Mode", selection: $model.selectedTab) {
                ForEach(StudioTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 360)
            .labelsHidden()

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.thinMaterial)
    }
}

struct HeaderView: View {
    @EnvironmentObject private var model: ControllerModel

    var body: some View {
        HStack(spacing: 14) {
            AppIconMark()
                .frame(width: 54, height: 54)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("iBridge Studio")
                    .font(.title3.weight(.semibold))
                Text("Turn your retired iMacs into Retina monitors")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HeaderButton("Refresh Displays", systemImage: "display.2") {
                model.listDisplays()
            }
            .disabled(model.isListingDisplays)

            HeaderButton("Restore Windows", systemImage: "rectangle.on.rectangle") {
                model.restoreWindowsToMacBook()
            }

            HeaderButton("Stop All", systemImage: "stop.fill", role: .destructive) {
                model.stopAllSenders()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            Rectangle()
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.07),
                            Color.white.opacity(0.02),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject private var model: ControllerModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Show iBridge Studio") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Button("Open Logs") {
            model.selectedTab = .logs
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Text("\(model.activeStreamingCount) streaming session\(model.activeStreamingCount == 1 ? "" : "s")")

        if model.sessions.isEmpty {
            Text("No sender sessions")
        } else {
            ForEach(model.sessions) { session in
                if model.isSenderRunning(session) {
                    Button {
                        model.stopSender(session)
                    } label: {
                        Label("Stop \(session.name)", systemImage: "stop.fill")
                    }
                } else {
                    Button {
                        model.startSender(session)
                    } label: {
                        Label("Start \(session.name)", systemImage: "play.fill")
                    }
                }
            }
        }

        Divider()

        if model.localReceiverRunning {
            Button {
                model.stopLocalReceiver()
            } label: {
                Label("Stop Receiver :\(model.receiverPort)", systemImage: "stop.fill")
            }
        } else {
            Button {
                model.startLocalReceiver()
            } label: {
                Label("Start Receiver :\(model.receiverPort)", systemImage: "play.rectangle")
            }
        }

        Divider()

        Button("Previous Display") {
            model.moveMouseToPreviousDisplay()
        }

        Button("Next Display") {
            model.moveMouseToNextDisplay()
        }

        Button("Show Console Overlay") {
            model.showConsoleOverlay()
        }

        Divider()

        Button("Refresh Displays") {
            model.listDisplays()
        }

        Button("Restore Windows to MacBook") {
            model.restoreWindowsToMacBook()
        }

        Divider()

        Menu("Add Sender") {
            ForEach(presets) { preset in
                Button(preset.name) {
                    model.addSession(preset: preset)
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }

        Button("Stop All Senders") {
            model.stopAllSenders()
        }

        Divider()

        Button("Quit iBridge Studio") {
            if model.hasActiveProcesses {
                model.stopEverything()
            }
            NSApp.terminate(nil)
        }
    }
}
