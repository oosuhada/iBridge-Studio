import SwiftUI

struct LogTab: View {
    @EnvironmentObject private var model: ControllerModel

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

                Button {
                    model.log = "Ready.\n"
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
            }

            TextEditor(text: $model.log)
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
}
