import AppKit
import SwiftUI

/// The panel is light regardless of the system setting. Forcing the appearance on the
/// application is what actually reaches the AppKit window behind the panel, which a
/// SwiftUI color scheme on its own does not always do.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .aqua)
    }
}

@main
struct ClaudeSessionsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var store = SessionStore()

    var body: some Scene {
        MenuBarExtra {
            PanelView(store: store)
        } label: {
            HStack(spacing: Theme.Space.sm) {
                Image(systemName: "sparkle")
                // Working over total. With nothing running at all the ratio would say
                // nothing, so the icon stands alone.
                if !store.sessions.isEmpty {
                    Text("\(store.busy.count)/\(store.sessions.count)")
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
