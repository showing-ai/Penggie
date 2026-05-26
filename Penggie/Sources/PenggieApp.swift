import SwiftUI

@main
struct PenggieApp: App {
    @StateObject private var session = PenggieSessionModel()

    var body: some Scene {
        WindowGroup("Penggie") {
            PenggieRootView()
                .environmentObject(session)
                .frame(minWidth: 720, minHeight: 560)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Chat") {
                    session.requestNewChat()
                }
                .keyboardShortcut("n", modifiers: [.command])
                .disabled(!session.canStartNewChat)
            }

            CommandMenu("Session") {
                Button("Create with Penggie") {
                    session.startWithCodex()
                }
                .disabled(!session.canStartConfiguredCodex)

                Button("Close Session") {
                    session.requestCloseSession()
                }
                .keyboardShortcut("w", modifiers: [.command])
                .disabled(!session.hasInspectableSession)
            }
        }
    }
}
