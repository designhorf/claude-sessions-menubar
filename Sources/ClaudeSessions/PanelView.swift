import SwiftUI

struct PanelView: View {
    @ObservedObject var store: SessionStore
    @State private var showIdle: Bool
    @State private var flashID: String?
    @State private var flashText = ""

    init(store: SessionStore, expandIdle: Bool = false) {
        self.store = store
        _showIdle = State(initialValue: expandIdle)
    }

    /// With nothing working, a folded list would leave the panel saying only that
    /// nothing is happening.
    private var idleIsOpen: Binding<Bool> {
        Binding(
            get: { showIdle || store.busy.isEmpty },
            set: { showIdle = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if store.sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    SessionList(store: store, flashID: $flashID, flashText: $flashText, showIdle: idleIsOpen)
                        .padding(.bottom, Theme.Space.lg)
                }
                .frame(maxHeight: Theme.listMaxHeight)
            }
        }
        .padding(Theme.Space.xl)
        .frame(width: Theme.panelWidth)
        // The panel window is a vibrant material, so it samples whatever sits behind it
        // and a dark window turns the panel grey. An opaque fill is what makes it light.
        .background(Theme.Palette.surface)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: Theme.Space.lg) {
            Text("Claude Sessions")
                .font(Theme.Typography.panelName)
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
            settingsMenu
        }
        .padding(.horizontal, Theme.Space.sm)
        .padding(.bottom, Theme.Space.lg)
    }

    private var settingsMenu: some View {
        Menu {
            Toggle("Open at login", isOn: $store.launchAtLogin)
            Divider()
            Button("Quit Claude Sessions") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: Theme.IconSize.settings, weight: .regular))
                .foregroundStyle(Theme.Palette.textSecondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 18)
    }

    private var emptyState: some View {
        Text("No sessions running")
            .font(Theme.Typography.title)
            .foregroundStyle(Theme.Palette.textSecondary)
            .padding(.horizontal, Theme.Space.sm)
            .padding(.vertical, Theme.Space.xl)
    }
}
