import SwiftUI

struct ReceiverTab: View {
    @EnvironmentObject private var model: ControllerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Receiver")
                    .font(.title3.weight(.semibold))
                Text("Use this tab on an iMac, or start a remote receiver over SSH.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 14) {
                localReceiverPanel
                remoteReceiverPanel
            }

            Spacer()
        }
        .padding(18)
    }

    private var localReceiverPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("This Mac")
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                    GridRow {
                        LabeledField("Port") {
                            TextField("Port", text: $model.receiverPort)
                                .frame(width: 140)
                        }
                        LabeledField("Window title") {
                            TextField("Window title", text: $model.receiverTitle)
                                .frame(width: 280)
                        }
                    }
                }
                .textFieldStyle(.roundedBorder)

                Button {
                    model.startLocalReceiver()
                } label: {
                    Label("Start Receiver on This Mac", systemImage: "play.rectangle")
                }
            }
        }
        .frame(maxWidth: 520, alignment: .topLeading)
    }

    private var remoteReceiverPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Remote iMacs")
                    .font(.headline)

                ForEach(model.sessions) { session in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.name)
                                .font(.subheadline.weight(.semibold))
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
                        Divider().opacity(0.65)
                    }
                }
            }
        }
    }
}
