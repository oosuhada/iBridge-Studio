import SwiftUI

@main
struct IBridgeControllerApp: App {
    @StateObject private var model = ControllerModel()

    var body: some Scene {
        WindowGroup("iBridge Studio", id: "main") {
            ContentView()
                .environmentObject(model)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandMenu("iBridge Studio") {
                Button("Previous Display") {
                    model.moveMouseToPreviousDisplay()
                }
                .keyboardShortcut(.leftArrow, modifiers: [.control, .option])

                Button("Next Display") {
                    model.moveMouseToNextDisplay()
                }
                .keyboardShortcut(.rightArrow, modifiers: [.control, .option])

                Divider()

                Button("Show Console Overlay") {
                    model.showConsoleOverlay()
                }
                .keyboardShortcut("c", modifiers: [.control, .option])
            }
        }

        MenuBarExtra("iBridge Studio", systemImage: "display.2") {
            MenuBarView()
                .environmentObject(model)
        }
    }
}
