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
        VStack(alignment: .leading, spacing: 0) {
            workingSection
            idleSection
        }
    }

    @ViewBuilder
    private var workingSection: some View {
        SectionHeader(title: "Working", count: store.busy.count, isFirst: true)
        if store.busy.isEmpty {
            EmptyRow(
                icon: .clock,
                title: "Nothing is working",
                subtitle: "Sessions show here while Claude runs."
            )
        } else {
            rows(store.busy)
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
                action: foldable ? { withAnimation(Theme.Motion.fold) { showAllIdle.toggle() } } : nil
            )
            rows(visibleIdle)
        }
    }

    private func rows(_ sessions: [Session]) -> some View {
        ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
            if index > 0 { Hairline() }
            card(for: session)
        }
    }

    private func card(for session: Session) -> some View {
        SessionCard(session: session, flashID: $flashID, flashText: $flashText)
    }
}
