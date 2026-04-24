import AppKit
import SwiftUI

@main
struct CCCPMacPlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var playerStore = PlayerStore()

    var body: some Scene {
        WindowGroup("CCCP Player") {
            ContentView(store: playerStore)
                .frame(minWidth: 980, minHeight: 620)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    OpenFileRouter.shared.handler = { [weak playerStore] urls in
                        playerStore?.open(urls: urls)
                    }
                }
        }
        .commands {
            PlayerCommands(store: playerStore)
        }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            OpenFileRouter.shared.open(urls)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
