import AppKit
import SwiftUI

struct PanelView: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var usage: UsageStore
    @ObservedObject var servers: ServerStore
    @State private var showAllIdle: Bool
    @State private var flashID: String?
    @State private var flashText = ""
    @State private var contentHeight: CGFloat = 0
    @AppStorage("usageFolded") private var usageFolded = false
    @AppStorage(PanelAppearance.storageKey) private var appearance: PanelAppearance = .light

    init(store: SessionStore, usage: UsageStore, servers: ServerStore, showAllIdle: Bool = false) {
        self.store = store
        self.usage = usage
        self.servers = servers
        _showAllIdle = State(initialValue: showAllIdle)
    }

    var body: some View {
        VStack(spacing: 0) {
            PanelTop(store: store, usage: usage, usageFolded: $usageFolded) {
                appearanceToggle
                settingsMenu
            }
            ScrollView {
                PanelBody(store: store, servers: servers, flashID: $flashID, flashText: $flashText,
                          showAllIdle: $showAllIdle)
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: ContentHeightKey.self, value: geometry.size.height)
                    })
            }
            // A ScrollView has no height of its own, so with only a maximum the menu bar
            // window shrank it to nothing and cut the list off. The measured content height
            // is the height, up to the maximum, past which it scrolls.
            .frame(height: min(contentHeight, Theme.listMaxHeight))
            .onPreferenceChange(ContentHeightKey.self) { contentHeight = $0 }
        }
        .padding(Theme.Space.panelInset)
        .frame(width: Theme.panelWidth)
        // The panel window is a vibrant material, so it samples whatever sits behind it
        // and a dark window turns the panel grey. An opaque fill is what makes it light.
        .background(Theme.Palette.surface)
        .preferredColorScheme(appearance.colorScheme)
        // Whether a MenuBarExtra window re-runs onAppear on every open is not something
        // to rely on, so the window becoming key counts as an open too. The store
        // collapses the two into one request.
        .onAppear { panelOpened() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            panelOpened()
        }
        // Closing the panel takes key away from its window, and that stops the scan.
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            servers.stopWatching()
        }
    }

    private func panelOpened() {
        usage.refresh()
        servers.startWatching()
    }

    private var appearanceToggle: some View {
        Button {
            appearance = appearance.toggled
            appearance.apply()
        } label: {
            PanelTop<EmptyView>.headerGlyph(appearance.toggleIcon)
        }
        .buttonStyle(.plain)
        .help(appearance.toggleHelp)
    }

    private var settingsMenu: some View {
        Menu {
            Toggle("Open at login", isOn: $store.launchAtLogin)
            Divider()
            Button("Quit Claude Sessions") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(nsImage: Icon.gear.tintedImage(size: Theme.IconSize.header, color: Theme.Palette.textSecondary))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .frame(width: Theme.Size.headerButton, height: Theme.Size.headerButton)
        .help("Settings")
    }
}

/// The raised top: the app's name, what is running, its controls and the usage. It
/// stays on screen while the rows below it scroll. The controls come from outside
/// because `ImageRenderer` cannot draw a Menu, so the render harness stands in for them.
struct PanelTop<Actions: View>: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var usage: UsageStore
    @Binding var usageFolded: Bool
    @ViewBuilder var actions: () -> Actions

    static func headerGlyph(_ icon: Icon) -> GlyphControl {
        GlyphControl(icon: icon, box: Theme.Size.headerButton, glyph: Theme.IconSize.header,
                     radius: Theme.Radius.control)
    }

    private var summary: String {
        store.sessions.isEmpty ? "No sessions" : "\(store.busy.count) working · \(store.idle.count) idle"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Space.xl) {
                tile
                VStack(alignment: .leading, spacing: 0) {
                    Text("Claude Sessions")
                        .font(Theme.Typography.panelName)
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Text(summary)
                        .font(Theme.Typography.headerSub)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
                Spacer(minLength: Theme.Space.sm)
                HStack(spacing: Theme.Space.xs) { actions() }
            }
            .padding(.leading, Theme.Space.xl)
            .padding(.trailing, Theme.Space.lg)
            .frame(height: Theme.Size.headerHeight)
            Hairline()
            UsageSection(store: usage, folded: $usageFolded)
        }
        .background(RoundedRectangle(cornerRadius: Theme.Radius.raised).fill(Theme.Palette.raised))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.raised).strokeBorder(Theme.Palette.divider, lineWidth: Theme.Size.hairline))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.raised))
    }

    private var tile: some View {
        IconView(icon: .spark, size: Theme.IconSize.tile, tint: Theme.Palette.textPrimary)
            .frame(width: Theme.Size.tile, height: Theme.Size.tile)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.tile)
                    .fill(Theme.Palette.surface)
                    .shadow(color: .black.opacity(Theme.Opacity.tileShadow),
                            radius: Theme.Shadow.tileRadius, y: Theme.Shadow.tileOffset)
            )
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.tile).strokeBorder(Theme.Palette.divider, lineWidth: Theme.Size.hairline))
    }
}

/// The rows below the raised top. Kept apart from the scroll view, which `ImageRenderer`
/// cannot draw, so the render harness can draw this for real.
struct PanelBody: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var servers: ServerStore
    @Binding var flashID: String?
    @Binding var flashText: String
    @Binding var showAllIdle: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if store.sessions.isEmpty {
                SectionHeader(title: "Sessions", count: 0, isFirst: true)
                EmptyRow(
                    icon: .terminal,
                    title: "No sessions running",
                    subtitle: "Start Claude Code in a terminal."
                )
            } else {
                SessionList(store: store, flashID: $flashID, flashText: $flashText,
                            showAllIdle: $showAllIdle)
            }
            ServerList(store: servers)
        }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
