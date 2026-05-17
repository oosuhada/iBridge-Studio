import AppKit
import SwiftUI

struct LogTab: View {
    @EnvironmentObject private var model: ControllerModel
    @State private var selectedLevel = "All"
    @State private var selectedSession = "All"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Runtime Log")
                        .font(.title3.weight(.semibold))
                    Text("Sender, receiver, display listing, and restore actions appear here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Level", selection: $selectedLevel) {
                    Text("All Levels").tag("All")
                    ForEach(LogLevel.allCases) { level in
                        Text(level.rawValue).tag(level.rawValue)
                    }
                }
                .labelsHidden()
                .frame(width: 130)

                Picker("Session", selection: $selectedSession) {
                    Text("All Sessions").tag("All")
                    ForEach(model.sessions) { session in
                        Text(session.name).tag(session.name)
                    }
                }
                .labelsHidden()
                .frame(width: 180)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(filteredText, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Button {
                    model.exportSupportBundle()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

                Button {
                    model.clearLog()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
            }

            TextEditor(text: .constant(filteredText))
                .font(.system(.caption, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                )
        }
        .padding(18)
    }

    private var filteredText: String {
        let level = LogLevel.allCases.first { $0.rawValue == selectedLevel }
        let session = selectedSession == "All" ? nil : selectedSession
        return model.filteredLogText(level: level, sessionName: session)
    }
}
