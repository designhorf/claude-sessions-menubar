import AppKit
import SwiftUI

struct PanelView: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var usage: UsageStore
    @State private var showAllIdle: Bool
    @State private var flashID: String?
    @State private var flashText = ""
    @State private var contentHeight: CGFloat = 0
    @AppStorage("usageFolded") private var usageFolded = false
    @AppStorage(PanelAppearance.storageKey) private var appearance: PanelAppearance = .light

    init(store: SessionStore, usage: UsageStore, showAllIdle: Bool = false) {
        self.store = store
        self.usage = usage
        _showAllIdle = State(initialValue: showAllIdle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            header
            ScrollView {
                PanelBody(store: store, usage: usage, usageFolded: $usageFolded,
                          flashID: $flashID, flashText: $flashText, showAllIdle: $showAllIdle)
                    .padding(.bottom, Theme.Space.sm)
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
        .padding(Theme.Space.panel)
        .frame(width: Theme.panelWidth)
        // The panel window is a vibrant material, so it samples whatever sits behind it
        // and a dark window turns the panel grey. An opaque fill is what makes it light.
        .background(Theme.Palette.surface)
        .preferredColorScheme(appearance.colorScheme)
        // Whether a MenuBarExtra window re-runs onAppear on every open is not something
        // to rely on, so the window becoming key counts as an open too. The store
        // collapses the two into one request.
        .onAppear { usage.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            usage.refresh()
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Space.lg) {
            Text("Claude Sessions")
                .font(Theme.Typography.panelName)
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
            appearanceToggle
            settingsMenu
        }
        .padding(.horizontal, Theme.Space.xs)
    }

    private var appearanceToggle: some View {
        Button {
            appearance = appearance.toggled
            appearance.apply()
        } label: {
            RoundGlyph(symbol: appearance.toggleSymbol, diameter: Theme.Size.settingsButton,
                       glyphSize: Theme.IconSize.settings)
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
            RoundGlyph(symbol: "gearshape", diameter: Theme.Size.settingsButton,
                       glyphSize: Theme.IconSize.settings)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

/// Everything below the header. Kept apart from the scroll view and the menu, which
/// `ImageRenderer` cannot draw, so the render harness can draw this for real.
struct PanelBody: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var usage: UsageStore
    @Binding var usageFolded: Bool
    @Binding var flashID: String?
    @Binding var flashText: String
    @Binding var showAllIdle: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            UsageSection(store: usage, folded: $usageFolded)
            if store.sessions.isEmpty {
                SectionHeader(title: "Sessions", count: 0)
                BubbleRow(
                    bubble: IconBubble(symbol: "terminal"),
                    title: "No sessions running",
                    subtitle: "Start Claude Code in a terminal."
                )
                .softCard()
            } else {
                SessionList(store: store, flashID: $flashID, flashText: $flashText,
                            showAllIdle: $showAllIdle)
            }
        }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
