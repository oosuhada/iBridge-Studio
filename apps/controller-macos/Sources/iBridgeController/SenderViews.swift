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
                    Label("Add iMac Display", systemImage: "plus")
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
    @State private var advancedSettingsExpanded = false

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                header
                setupChecklist
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
                title: statusTitle,
                color: statusColor
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
        VStack(alignment: .leading, spacing: 12) {
            basicConfiguration

            DisclosureGroup("Advanced Settings", isExpanded: $advancedSettingsExpanded) {
                advancedConfiguration
                    .padding(.top, 10)
            }
        }
        .textFieldStyle(.roundedBorder)
    }

    private var basicConfiguration: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                connectionFields
                displayField
            }

            GridRow {
                signalPresetField
                signalField
            }

            GridRow {
                bitrateFields
                cursorField
            }
        }
    }

    private var statusTitle: String {
        if model.isSenderRunning(session) { return "Streaming" }
        if model.validationIssues(for: session).contains(where: \.blocksStart) { return "Not Ready" }
        return "Ready"
    }

    private var statusColor: Color {
        if model.isSenderRunning(session) { return .green }
        if model.validationIssues(for: session).contains(where: \.blocksStart) { return .orange }
        return .blue
    }

    private var setupChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Setup Checklist")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    model.refreshPermissions()
                    model.testReceiverConnection(session)
                    model.listDisplays()
                } label: {
                    Label("Test Connection", systemImage: "checkmark.seal")
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                GridRow {
                    checklistItem("Receiver", ok: !session.receiverIP.isEmpty || !session.discoveryHost.isEmpty)
                    checklistItem("Virtual display", ok: displayLooksConfigured)
                }
                GridRow {
                    checklistItem("Screen Recording", ok: model.screenRecordingAllowed)
                    checklistItem("Accessibility", ok: model.accessibilityAllowed)
                }
            }

            if let status = model.receiverProbeStatus[session.id] {
                Text(status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ForEach(model.validationIssues(for: session)) { issue in
                Text(issue.message)
                    .font(.caption2)
                    .foregroundStyle(issue.severity == .error ? .red : .secondary)
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func checklistItem(_ title: String, ok: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(ok ? .green : .orange)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var displayLooksConfigured: Bool {
        if model.availableDisplayNames.isEmpty {
            return !session.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return model.availableDisplayNames.contains(session.displayName)
    }

    private var advancedConfiguration: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
            GridRow {
                profileField
                durationField
            }

            GridRow {
                durationSecondsField
                discoveryField
            }

            GridRow {
                wakeFields
            }
        }
        .frame(minWidth: 860, alignment: .leading)
    }

    private var compactConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            receiverField
            discoveryField
            displayField
            profileField
            signalPresetField
            signalField
            bitrateFields
            durationField
            cursorField
            durationSecondsField
            wakeFields
        }
    }

    private var receiverField: some View {
        LabeledField("Receiver IP") {
            TextField("Receiver IP", text: $session.receiverIP)
                .frame(minWidth: 220)
        }
    }

    private var connectionFields: some View {
        VStack(alignment: .leading, spacing: 6) {
            receiverField
            if !session.discoveryHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Discovery host is tried first; Receiver IP is the manual fallback.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var discoveryField: some View {
        LabeledField("Discovery host") {
            TextField("SSH host or user@host", text: $session.discoveryHost)
                .frame(minWidth: 220)
        }
    }

    private var displayField: some View {
        LabeledField("Display") {
            if model.availableDisplayNames.isEmpty {
                TextField("Virtual display name", text: $session.displayName)
                    .frame(minWidth: 260)
            } else {
                Picker("Virtual display", selection: $session.displayName) {
                    ForEach(model.availableDisplayNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .labelsHidden()
                .frame(minWidth: 260)
            }
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
            .onChange(of: session.signalOptionID) { newValue in
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
            .onChange(of: session.bitrateOptionID) { newValue in
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
        LabeledField("Session timeout") {
            Picker("Session timeout", selection: $session.durationOptionID) {
                ForEach(durationOptions) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .labelsHidden()
            .help("The sender stops automatically after this time.")
            .onChange(of: session.durationOptionID) { newValue in
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

    private var cursorField: some View {
        LabeledField("Cursor") {
            Picker("Cursor", selection: $session.cursorModeID) {
                ForEach(cursorOptions) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .labelsHidden()
            .frame(minWidth: 220)
        }
    }

    private var wakeFields: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .bottom, spacing: 10) {
                wakeMACField
                wakeBroadcastField
                autoWakeToggle
            }
            VStack(alignment: .leading, spacing: 10) {
                wakeMACField
                wakeBroadcastField
                autoWakeToggle
            }
        }
    }

    private var wakeMACField: some View {
        LabeledField("Wake MAC") {
            TextField("AA:BB:CC:DD:EE:FF", text: $session.wakeMAC)
                .frame(minWidth: 190)
        }
    }

    private var wakeBroadcastField: some View {
        LabeledField("Wake broadcast") {
            TextField("Broadcast IPs", text: $session.wakeBroadcast)
                .frame(minWidth: 220)
        }
    }

    private var autoWakeToggle: some View {
        Toggle("Auto wake", isOn: $session.autoWake)
            .toggleStyle(.checkbox)
            .padding(.bottom, 4)
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                model.wakeReceiver(session)
            } label: {
                Label("Wake", systemImage: "power")
            }
            .disabled(session.wakeMAC.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

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
