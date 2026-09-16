import SwiftUI

/// A glyph in a filled circle, leading a row.
struct IconBubble: View {
    let symbol: String
    var fill: Color = Theme.Palette.bubble
    var tint: Color = Theme.Palette.textPrimary
    var glyphSize: CGFloat = Theme.IconSize.bubbleGlyph

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: glyphSize, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: Theme.Size.bubble, height: Theme.Size.bubble)
            .background(Circle().fill(fill))
    }

    /// Green play while Claude runs, grey stop while it waits.
    static func sessionState(running: Bool) -> IconBubble {
        IconBubble(
            symbol: running ? "play.fill" : "stop.fill",
            fill: running ? Theme.Palette.runningTint : Theme.Palette.stoppedTint,
            tint: running ? Theme.Palette.running : Theme.Palette.stopped,
            glyphSize: Theme.IconSize.stateGlyph
        )
    }
}

/// Bubble, a one-line title over a quieter subtitle, and whatever trails the row.
struct BubbleRow<Trailing: View>: View {
    let bubble: IconBubble
    let title: String
    var subtitle: String?
    var subtitleColor: Color = Theme.Palette.textSecondary
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: Theme.Space.xl) {
            bubble
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(title)
                    .font(Theme.Typography.rowTitle)
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.rowSub)
                        .monospacedDigit()
                        .foregroundStyle(subtitleColor)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: Theme.Space.sm)
            trailing()
        }
    }
}

extension BubbleRow where Trailing == EmptyView {
    init(bubble: IconBubble, title: String, subtitle: String?) {
        self.init(bubble: bubble, title: title, subtitle: subtitle) { EmptyView() }
    }
}
