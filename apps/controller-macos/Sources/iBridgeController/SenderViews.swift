import SwiftUI

struct SenderTab: View {
    @EnvironmentObject private var model: ControllerModel

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sender Sessions")
                        .font(.title3.weight(.semibold))
                    Text("One session per virtual display / receiver iMac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    PresetMenuItems { preset in
                        model.addSession(preset: preset, focus: .sender)
                    }
                } label: {
                    Label("Add Sender", systemImage: "plus")
                }
                .controlSize(.large)
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(model.sessions) { session in
                        SenderSessionCard(session: session)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .padding(18)
    }
}

struct SenderSessionCard: View {
    @EnvironmentObject private var model: ControllerModel
    @ObservedObject var session: DisplaySession

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                header
                Divider().opacity(0.65)
                configurationFields
                actionRow
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
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
                PresetMenuItems { preset in
                    session.apply(preset)
                }
            } label: {
                Label("Preset", systemImage: "slider.horizontal.3")
            }
            .labelStyle(.iconOnly)

            Button(role: .destructive) {
                model.removeSession(session)
            } label: {
                Label("Remove", systemImage: "minus")
            }
            .labelStyle(.iconOnly)
            .disabled(model.sessions.count <= 1)
        }
    }

    private var configurationFields: some View {
        ViewThatFits(in: .horizontal) {
            wideConfiguration
            compactConfiguration
        }
        .textFieldStyle(.roundedBorder)
    }

    private var wideConfiguration: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                receiverField
                displayField
            }

            GridRow {
                signalPresetField
                signalField
            }

            GridRow {
                profileField
                bitrateFields
            }

            GridRow {
                durationField
                durationSecondsField
            }
        }
        .frame(minWidth: 860, alignment: .leading)
    }

    private var compactConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            receiverField
            displayField
            signalPresetField
            signalField
            profileField
            bitrateFields
            durationField
            durationSecondsField
        }
    }

    private var receiverField: some View {
        LabeledField("Receiver") {
            TextField("Receiver IP", text: $session.receiverIP)
                .frame(minWidth: 220)
        }
    }

    private var displayField: some View {
        LabeledField("Display") {
            TextField("Virtual display name", text: $session.displayName)
                .frame(minWidth: 260)
        }
    }

    private var signalPresetField: some View {
        LabeledField("Signal preset") {
            Picker("Signal preset", selection: $session.signalOptionID) {
                ForEach(signalOptions) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .labelsHidden()
            .onChange(of: session.signalOptionID) { _, newValue in
                if let option = signalOptions.first(where: { $0.id == newValue }), option.id != "custom" {
                    session.resolution = option.value
                }
            }
        }
    }

    private var signalField: some View {
        LabeledField("Signal") {
            TextField("Resolution", text: $session.resolution)
                .disabled(session.signalOptionID != "custom")
        }
    }

    private var profileField: some View {
        LabeledField("Profile") {
            TextField("Profile", text: $session.profile)
        }
    }

    private var bitrateFields: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .bottom, spacing: 10) {
                bitratePresetField
                bitrateCustomField
            }
            VStack(alignment: .leading, spacing: 10) {
                bitratePresetField
                bitrateCustomField
            }
        }
    }

    private var bitratePresetField: some View {
        LabeledField("Bitrate preset") {
            Picker("Bitrate", selection: $session.bitrateOptionID) {
                ForEach(bitrateOptions) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .labelsHidden()
            .frame(minWidth: 220)
            .onChange(of: session.bitrateOptionID) { _, newValue in
                if let option = bitrateOptions.first(where: { $0.id == newValue }), option.id != "custom" {
                    session.bitrateMbps = option.value
                }
            }
        }
    }

    private var bitrateCustomField: some View {
        LabeledField("Custom Mbps") {
            TextField("Mbps", text: $session.bitrateMbps)
                .frame(width: 120)
                .disabled(session.bitrateOptionID != "custom")
        }
    }

    private var durationField: some View {
        LabeledField("Duration") {
            Picker("Duration", selection: $session.durationOptionID) {
                ForEach(durationOptions) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .labelsHidden()
            .onChange(of: session.durationOptionID) { _, newValue in
                if let option = durationOptions.first(where: { $0.id == newValue }), option.id != "custom" {
                    session.duration = option.value
                }
            }
        }
    }

    private var durationSecondsField: some View {
        LabeledField("Custom seconds") {
            TextField("Seconds", text: $session.duration)
                .disabled(session.durationOptionID != "custom")
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
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

            Button {
                model.restoreWindowsToMacBook()
            } label: {
                Label("Restore Windows", systemImage: "rectangle.on.rectangle")
            }
        }
    }
}

struct PresetMenuItems: View {
    let action: (ReceiverPreset) -> Void

    var body: some View {
        ForEach(presetCategoryOrder, id: \.self) { category in
            Menu(category) {
                ForEach(presets(in: category)) { preset in
                    Button(preset.name) {
                        action(preset)
                    }
                }
            }
        }
    }
}
