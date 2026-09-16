import SwiftUI

/// Session and weekly limit in one card. The Usage row stays put in both states and the
/// whole row folds the card: folded, it carries a ring per limit; open, the fetch time
/// and a refresh button, with each limit's bar and reset time sliding in below.
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
                    .padding(.horizontal, Theme.Space.xxl)
                    .padding(.bottom, Theme.Space.xl)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .softCard(horizontalPadding: 0, verticalPadding: 0)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
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
                Text("Usage")
                    .font(Theme.Typography.rowTitle)
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
                    .allowsHitTesting(false)
            }
        }
        .frame(height: Theme.Size.usageRow)
        .padding(.horizontal, Theme.Space.xxl)
        .padding(.vertical, Theme.Space.xl)
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
                .font(Theme.Typography.rowSub)
                .foregroundStyle(Theme.Palette.textSecondary)
            Text(UsageText.percent(limit))
                .font(Theme.Typography.ringValue)
                .monospacedDigit()
                .foregroundStyle(valueColor(limit))
                .opacity(store.isStale ? Theme.Opacity.staleValue : 1)
        }
        .padding(.leading, Theme.Space.sm)
    }

    private var statusAndRefresh: some View {
        HStack(spacing: Theme.Space.md) {
            status.allowsHitTesting(false)
            Button { store.refresh(manual: true) } label: {
                RoundGlyph(
                    symbol: "arrow.clockwise",
                    diameter: Theme.Size.refreshButton,
                    glyphSize: Theme.IconSize.refresh,
                    fill: Theme.Palette.bubble,
                    tint: Theme.Palette.textPrimary,
                    spinning: store.phase == .updating,
                    fillOnHover: true
                )
            }
            .buttonStyle(.plain)
            .help(store.failure?.reason ?? "Refresh usage")
        }
    }

    @ViewBuilder
    private var status: some View {
        switch store.phase {
        case .updating:
            statusText("Updating", color: Theme.Palette.textTertiary)
        case .failed(let failure):
            HStack(spacing: Theme.Space.sm) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: Theme.IconSize.status))
                statusText(UsageText.status(failure.short, lastGood: usage), color: Theme.Palette.critical)
            }
            .foregroundStyle(Theme.Palette.critical)
        case .idle:
            if let usage {
                statusText(UsageText.clock(usage.fetchedAt), color: Theme.Palette.textTertiary)
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
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .padding(.top, Theme.Space.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Theme.Palette.divider).frame(height: 1)
                    }
            }
        }
    }

    private func limitRow(_ name: String, _ limit: Usage.Limit) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(name)
                    .font(Theme.Typography.rowSub)
                    .foregroundStyle(Theme.Palette.textSecondary)
                Spacer()
                Text(UsageText.percent(limit))
                    .font(Theme.Typography.rowValue)
                    .monospacedDigit()
                    .foregroundStyle(valueColor(limit))
                    .opacity(store.isStale ? Theme.Opacity.staleValue : 1)
            }
            Meter(percent: limit.percent, isCritical: limit.isCritical, isStale: store.isStale)
            if let resetsAt = limit.resetsAt {
                Text(UsageText.reset(resetsAt, now: now))
                    .font(Theme.Typography.meta)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Palette.textTertiary)
            }
        }
    }

    // MARK: - Helpers

    private func toggleFold() {
        withAnimation(Theme.Motion.fold) { folded.toggle() }
    }

    private func valueColor(_ limit: Usage.Limit?) -> Color {
        limit?.isCritical == true ? Theme.Palette.critical : Theme.Palette.textPrimary
    }
}
