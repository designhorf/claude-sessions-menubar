import SwiftUI

/// Kept apart from the panel chrome so it can be rendered on its own.
struct SessionList: View {
    @ObservedObject var store: SessionStore
    @Binding var flashID: String?
    @Binding var flashText: String
    @Binding var showAllIdle: Bool

    /// Enough to see what was touched last while the usage cards stay on screen.
    static let idlePreviewCount = 3

    private var visibleIdle: [Session] {
        showAllIdle ? store.idle : Array(store.idle.prefix(Self.idlePreviewCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            workingSection
            idleSection
        }
    }

    @ViewBuilder
    private var workingSection: some View {
        SectionHeader(title: "Working", count: store.busy.count)
        if store.busy.isEmpty {
            BubbleRow(
                bubble: IconBubble(symbol: "clock"),
                title: "Nothing is working",
                subtitle: "Sessions show here while Claude runs."
            )
            .softCard()
        } else {
            ForEach(store.busy) { card(for: $0) }
        }
    }

    @ViewBuilder
    private var idleSection: some View {
        if !store.idle.isEmpty {
            let foldable = store.idle.count > Self.idlePreviewCount
            SectionHeader(
                title: "Idle",
                count: store.idle.count,
                actionTitle: foldable ? (showAllIdle ? "Show less" : "Show all") : nil,
                action: foldable ? { showAllIdle.toggle() } : nil
            )
            ForEach(visibleIdle) { card(for: $0) }
        }
    }

    private func card(for session: Session) -> some View {
        SessionCard(session: session, flashID: $flashID, flashText: $flashText)
    }
}
