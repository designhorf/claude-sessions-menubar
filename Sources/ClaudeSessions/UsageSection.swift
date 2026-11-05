import SwiftUI

/// Session and weekly limit, inside the raised top. The Usage row stays put in both
/// states and the whole row folds it: folded, it carries a ring per limit; open, the
/// fetch time and a refresh button, with each limit's bar and reset time sliding in below.
struct UsageSection: View {
    @ObservedObject var store: UsageStore
    @Binding var folded: Bool
    var now = Date()

    private var usage: Usage? { store.usage }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row
            if !folded {
                details
                    .padding(.horizontal, Theme.Space.xl)
                    .padding(.top, Theme.Space.xs)
                    .padding(.bottom, Theme.Space.xl)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipped()
    }

    // MARK: - The Usage row

    /// A plain button spans the row and takes the click wherever it lands; the content
    /// sits on top without taking hits, except the refresh button, which is its own
    /// target. A button rather than a tap gesture, because a gesture can miss the first
    /// click in a panel that is not yet key.
    private var row: some View {
        ZStack {
            Button(action: toggleFold) {
                Color.clear.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(folded ? "Show reset times" : "Fold usage")

            HStack(spacing: Theme.Space.lg) {
                IconView(icon: .clock)
                    .allowsHitTesting(false)
                Text("Usage")
                    .font(Theme.Typography.section)
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .allowsHitTesting(false)
                Spacer(minLength: Theme.Space.sm)
                ZStack(alignment: .trailing) {
                    if folded {
                        rings.transition(.opacity)
                    } else {
                        statusAndRefresh.transition(.opacity)
                    }
                }
                DisclosureChevron(expanded: !folded)
                    .frame(width: Theme.Size.miniButton, height: Theme.Size.miniButton)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: Theme.Size.usageRow)
        .padding(.leading, Theme.Space.xl)
        .padding(.trailing, Theme.Space.lg)
        .contentShape(Rectangle())
    }

    private var rings: some View {
        HStack(spacing: Theme.Space.lg) {
            ringStat("Session", usage?.session)
            ringStat("Week", usage?.weekly)
        }
        .allowsHitTesting(false)
    }

    private func ringStat(_ name: String, _ limit: Usage.Limit?) -> some View {
        HStack(spacing: Theme.Space.md) {
            Ring(percent: limit?.percent ?? 0, isCritical: limit?.isCritical ?? false, isStale: store.isStale)
            Text(name)
                .font(Theme.Typography.ringName)
                .foregroundStyle(Theme.Palette.textSecondary)
            Text(UsageText.percent(limit))
                .font(Theme.Typography.ringValue)
                .monospacedDigit()
                .foregroundStyle(valueColor(limit))
        }
        .padding(.leading, Theme.Space.sm)
    }

    private var statusAndRefresh: some View {
        HStack(spacing: Theme.Space.md) {
            status.allowsHitTesting(false)
            Button { store.refresh(manual: true) } label: {
                GlyphControl(icon: .refresh, spinning: store.phase == .updating)
            }
            .buttonStyle(.plain)
            .help(store.failure?.reason ?? "Refresh usage")
        }
    }

    @ViewBuilder
    private var status: some View {
        switch store.phase {
        case .updating:
            statusText("Updating", color: Theme.Palette.textSecondary)
        case .failed(let failure):
            HStack(spacing: Theme.Space.sm) {
                IconView(icon: .alert, size: Theme.IconSize.status, tint: Theme.Palette.critical)
                statusText(UsageText.status(failure.short, lastGood: usage), color: Theme.Palette.critical)
            }
        case .idle:
            if let usage {
                statusText(UsageText.clock(usage.fetchedAt), color: Theme.Palette.textSecondary)
            }
        }
    }

    private func statusText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(Theme.Typography.status)
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
    }

    // MARK: - Details

    private var details: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            if let session = usage?.session { limitRow("Session", session) }
            if let weekly = usage?.weekly { limitRow("Week · all models", weekly) }
            if let share = usage?.claudeCodeShare {
                Text(UsageText.share(share))
                    .font(Theme.Typography.meta)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .padding(.top, Theme.Space.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .top) { Hairline() }
            }
        }
    }

    private func limitRow(_ name: String, _ limit: Usage.Limit) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(Theme.Typography.limitName)
                    .foregroundStyle(Theme.Palette.textSecondary)
                Spacer()
                Text(UsageText.percent(limit))
                    .font(Theme.Typography.limitValue)
                    .monospacedDigit()
                    .foregroundStyle(valueColor(limit))
            }
            Meter(percent: limit.percent, isCritical: limit.isCritical, isStale: store.isStale)
            if let resetsAt = limit.resetsAt {
                Text(UsageText.reset(resetsAt, now: now))
                    .font(Theme.Typography.meta)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
        }
    }

    // MARK: - Helpers

    private func toggleFold() {
        withAnimation(Theme.Motion.fold) { folded.toggle() }
    }

    private func valueColor(_ limit: Usage.Limit?) -> Color {
        if store.isStale { return Theme.Palette.textSecondary }
        return limit?.isCritical == true ? Theme.Palette.critical : Theme.Palette.textPrimary
    }
}
