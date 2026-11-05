import AppKit
import SwiftUI

/// The panel starts in the appearance chosen last time, light by default.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        PanelAppearance.stored.apply()
    }
}

@main
struct ClaudeSessionsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var store: SessionStore
    @StateObject private var usage: UsageStore
    @StateObject private var servers = ServerStore()

    init() {
        let sessions = SessionStore()
        _store = StateObject(wrappedValue: sessions)
        _usage = StateObject(wrappedValue: UsageStore(pollingWhile: { !sessions.busy.isEmpty }))
    }

    var body: some Scene {
        MenuBarExtra {
            PanelView(store: store, usage: usage, servers: servers)
        } label: {
            HStack(spacing: Theme.Space.sm) {
                Image(systemName: "sparkle")
                // Working over total, then the plan usage. With nothing running at all the
                // ratio would say nothing, so it drops out. One Text, because the menu bar
                // does not lay out a second one reliably.
                if let title = menuBarTitle {
                    Text(title)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarTitle: String? {
        let ratio = store.sessions.isEmpty ? nil : "\(store.busy.count)/\(store.sessions.count)"
        let parts = [ratio, UsageText.menuBar(usage.usage)].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: "  ")
    }
}
