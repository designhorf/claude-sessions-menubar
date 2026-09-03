import SwiftUI

/// Kept apart from the panel chrome so it can be rendered on its own.
struct SessionList: View {
    @ObservedObject var store: SessionStore
    @Binding var flashID: String?
    @Binding var flashText: String
    @Binding var showIdle: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            workingSection
            idleSection
        }
    }

    @ViewBuilder
    private var workingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionHeader(
                icon: "circle.lefthalf.filled",
                iconColor: Theme.Palette.working,
                title: "Working",
                count: store.busy.count
            )
            if store.busy.isEmpty {
                Text("Nothing is working right now")
                    .font(Theme.Typography.meta)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .padding(.horizontal, Theme.Space.sm)
                    .padding(.bottom, Theme.Space.sm)
            } else {
                ForEach(store.busy) { session in
                    SessionCard(session: session, flashID: $flashID, flashText: $flashText)
                }
            }
        }
    }

    @ViewBuilder
    private var idleSection: some View {
        if !store.idle.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Space.md) {
                SectionHeader(
                    icon: "circle",
                    iconColor: Theme.Palette.textTertiary,
                    title: "Idle",
                    count: store.idle.count,
                    collapsible: true,
                    expanded: showIdle,
                    toggle: { withAnimation(.easeOut(duration: 0.12)) { showIdle.toggle() } }
                )
                if showIdle {
                    ForEach(store.idle) { session in
                        SessionCard(session: session, flashID: $flashID, flashText: $flashText)
                    }
                }
            }
        }
    }
}
