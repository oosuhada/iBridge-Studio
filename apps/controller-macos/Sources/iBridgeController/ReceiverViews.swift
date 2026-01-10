import Foundation
import SwiftUI

struct ReceiverTab: View {
    @EnvironmentObject private var model: ControllerModel

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Receiver")
                                .font(.title3.weight(.semibold))
                            Text("Run the receiver on an iMac, or start it remotely over SSH.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Menu {
                            PresetMenuItems { preset in
                                model.addSession(preset: preset, focus: .receiver)
                            }
                        } label: {
                            Label("Add Receiver iMac", systemImage: "plus")
                        }
                        .controlSize(.large)
                    }

                    if proxy.size.width < 980 {
                        VStack(alignment: .leading, spacing: 14) {
                            localReceiverPanel
                            remoteReceiverPanel
                        }
                    } else {
                        HStack(alignment: .top, spacing: 14) {
                            localReceiverPanel
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            remoteReceiverPanel
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    }
                }
                .padding(18)
                .frame(minWidth: proxy.size.width, alignment: .topLeading)
            }
        }
    }

    private var localReceiverPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("This Mac")
                    .font(.headline)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .bottom, spacing: 12) {
                        portField
                        titleField
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        portField
                        titleField
                    }
                }
                .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    StatusPill(
                        title: model.localReceiverRunning ? "Listening on :\(model.receiverPort)" : "Stopped",
                        color: model.localReceiverRunning ? .green : .gray
                    )

                    if model.localReceiverRunning {
                        Button(role: .destructive) {
                            model.stopLocalReceiver()
                        } label: {
                            Label("Stop Receiver", systemImage: "stop.fill")
                        }
                    } else {
                        Button {
                            model.startLocalReceiver()
                        } label: {
                            Label("Start Receiver on This Mac", systemImage: "play.rectangle")
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("This Mac addresses")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Button {
                            model.refreshLocalReceiverAddresses()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .labelStyle(.iconOnly)
                    }

                    if model.localReceiverAddresses.isEmpty {
                        Text("No active non-loopback IPv4 address detected.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.localReceiverAddresses, id: \.self) { address in
                            HStack {
                                Text(address)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    let ip = address.split(separator: " ").last.map(String.init) ?? address
                                    model.copyReceiverAddress(ip)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                .labelStyle(.iconOnly)
                            }
                        }
                    }
                }
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

                Text("To launch at login, add iBridge Studio in System Settings > General > Login Items on the receiver iMac.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button {
                    model.repairLocalSystemSettings()
                } label: {
                    Label("Repair System Settings", systemImage: "wrench.and.screwdriver")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var remoteReceiverPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Remote iMacs")
                    .font(.headline)

                Text("Remote targets currently reuse Sender sessions. TODO: split SenderConfig and ReceiverTarget when receiver-only options grow.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(model.sessions) { session in
                    remoteReceiverRow(session)

                    if session.id != model.sessions.last?.id {
                        Divider().opacity(0.65)
                    }
                }
            }
        }
    }

    private var portField: some View {
        LabeledField("Port") {
            TextField("Port", text: $model.receiverPort)
                .frame(width: 140)
        }
    }

    private var titleField: some View {
        LabeledField("Window title") {
            TextField("Window title", text: $model.receiverTitle)
                .frame(minWidth: 240)
                .frame(maxWidth: .infinity)
        }
    }

    private func remoteReceiverRow(_ session: DisplaySession) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                remoteReceiverSummary(session)
                Spacer(minLength: 12)
                remoteReceiverActions(session)
            }
            VStack(alignment: .leading, spacing: 10) {
                remoteReceiverSummary(session)
                remoteReceiverActions(session)
            }
        }
    }

    private func remoteReceiverSummary(_ session: DisplaySession) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(session.name)
                .font(.subheadline.weight(.semibold))
            Text(session.receiverIP)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(URL(fileURLWithPath: session.receiverScript).lastPathComponent)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
            if let startedAt = model.remoteReceiverLastStartedAt[session.id] {
                Text("Last start: \(startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func startRemoteButton(_ session: DisplaySession) -> some View {
        Button {
            model.startRemoteReceiver(session)
        } label: {
            Label("Start", systemImage: "play.fill")
        }
        .disabled(model.isReceiverBusy(session))
    }

    private func remoteReceiverActions(_ session: DisplaySession) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                startRemoteButton(session)
                testRemoteButton(session)
                repairRemoteButton(session)
            }
            VStack(alignment: .leading, spacing: 8) {
                startRemoteButton(session)
                testRemoteButton(session)
                repairRemoteButton(session)
            }
        }
    }

    private func testRemoteButton(_ session: DisplaySession) -> some View {
        Button {
            model.testReceiverConnection(session)
        } label: {
            Label("Test", systemImage: "network")
        }
        .disabled(session.receiverIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func repairRemoteButton(_ session: DisplaySession) -> some View {
        Button {
            model.repairRemoteSystemSettings(session)
        } label: {
            Label("Repair Settings", systemImage: "wrench.and.screwdriver")
        }
        .disabled(session.discoveryHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
