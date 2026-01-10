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

        MenuBarExtra("iBridge Studio", systemImage: "display.2") {
            MenuBarView()
                .environmentObject(model)
        }
    }
}
