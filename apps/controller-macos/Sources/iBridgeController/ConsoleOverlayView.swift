import AppKit
import SwiftUI

struct ConsoleOverlayView: View {
    @EnvironmentObject private var model: ControllerModel

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Button {
                    model.moveMouseToPreviousDisplay()
                } label: {
                    Label("Previous", systemImage: "arrow.left.to.line")
                }
                .keyboardShortcut(.leftArrow, modifiers: [.control, .option])

                Button {
                    model.moveMouseToNextDisplay()
                } label: {
                    Label("Next", systemImage: "arrow.right.to.line")
                }
                .keyboardShortcut(.rightArrow, modifiers: [.control, .option])

                Spacer()

                Button {
                    model.selectedTab = .logs
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("Logs", systemImage: "list.bullet.rectangle")
                }
            }

            TextEditor(text: .constant(model.recentLogText))
                .font(.system(.caption, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
        }
        .padding(12)
        .frame(minWidth: 520, minHeight: 260)
        .background(.ultraThinMaterial)
    }
}

final class ConsoleOverlayDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_: Notification) {
        onClose()
    }
}
