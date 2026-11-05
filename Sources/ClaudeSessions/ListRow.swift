import SwiftUI

/// Title on the left, quieter detail and age on the right. When both fit, neither is cut.
/// When they do not, the title keeps at least a share of the width and the detail
/// truncates first. Both sit on one text baseline.
struct RowLineLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let widths = columnWidths(total: proposal.width, subviews: subviews)
        let (height, _) = lineHeight(subviews: subviews, widths: widths)
        return CGSize(width: proposal.width ?? widths.reduce(Theme.Space.lg, +), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = columnWidths(total: bounds.width, subviews: subviews)
        let (_, baseline) = lineHeight(subviews: subviews, widths: widths)
        var x = bounds.minX
        for (subview, width) in zip(subviews, widths) {
            let size = ProposedViewSize(width: width, height: nil)
            let own = subview.dimensions(in: size)[.firstTextBaseline]
            subview.place(at: CGPoint(x: x, y: bounds.minY + baseline - own), proposal: size)
            x += width + Theme.Space.lg
        }
    }

    private func columnWidths(total: CGFloat?, subviews: Subviews) -> [CGFloat] {
        let titleIdeal = subviews[0].sizeThatFits(.unspecified).width
        let detailIdeal = subviews[1].sizeThatFits(.unspecified).width
        guard let total else { return [titleIdeal, detailIdeal] }
        let title = min(titleIdeal, max(total * Theme.Size.rowTitleShare, total - Theme.Space.lg - detailIdeal))
        return [title, max(0, total - title - Theme.Space.lg)]
    }

    private func lineHeight(subviews: Subviews, widths: [CGFloat]) -> (height: CGFloat, baseline: CGFloat) {
        let dimensions = zip(subviews, widths).map { $0.dimensions(in: ProposedViewSize(width: $1, height: nil)) }
        let ascent = dimensions.map { $0[.firstTextBaseline] }.max() ?? 0
        let descent = dimensions.map { $0.height - $0[.firstTextBaseline] }.max() ?? 0
        return (ascent + descent, ascent)
    }
}

/// One short row: leading icon, title, detail and age, and whatever trails it. The main
/// part is a button rather than a tap gesture, because a gesture can miss the first
/// click in a panel that is not yet key. `flash` replaces the detail in place for a
/// moment, so a click moves nothing.
struct ListRow<Trailing: View>: View {
    let icon: Icon
    var iconTint: Color = Theme.Palette.textSecondary
    let title: String
    let detail: String
    let age: String
    var flash: String?
    let action: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 0) {
            Button(action: action) {
                HStack(alignment: .top, spacing: Theme.Space.xl) {
                    IconView(icon: icon, tint: iconTint)
                    RowLineLayout {
                        Text(title)
                            .font(Theme.Typography.rowTitle)
                            .foregroundStyle(Theme.Palette.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        meta
                    }
                }
                .padding(.horizontal, Theme.Space.xl)
                .padding(.vertical, Theme.Space.rowVertical)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.control)
                        .fill(Theme.Palette.rowHover)
                        .opacity(hovering ? 1 : 0)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering = $0 }
            trailing()
                .padding(.trailing, Theme.Space.sm)
        }
    }

    private var meta: some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                Text(detail)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("·")
                    .fixedSize()
                Text(age)
                    .monospacedDigit()
                    .fixedSize()
            }
            .foregroundStyle(Theme.Palette.textSecondary)
            .opacity(flash == nil ? 1 : 0)
            if let flash {
                Text(flash)
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(1)
            }
        }
        .font(Theme.Typography.meta)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// What a section says when it has nothing to list.
struct EmptyRow: View {
    let icon: Icon
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.xl) {
            IconView(icon: icon)
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(title)
                    .font(Theme.Typography.rowTitle)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(subtitle)
                    .font(Theme.Typography.meta)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Space.xl)
        .padding(.top, Theme.Space.md)
        .padding(.bottom, Theme.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
