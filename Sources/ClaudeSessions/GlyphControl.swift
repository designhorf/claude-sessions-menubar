import SwiftUI

/// An icon in a small rounded box: the header buttons and the row actions. While
/// `spinning` the icon turns, for a request in flight. The box only appears under the
/// pointer, so a quiet control does not look pressed.
struct GlyphControl: View {
    let icon: Icon
    var box: CGFloat = Theme.Size.miniButton
    var glyph: CGFloat = Theme.IconSize.mini
    var radius: CGFloat = Theme.Radius.mini
    var tint: Color = Theme.Palette.textSecondary
    var spinning = false

    @State private var hovering = false

    /// The turn is computed from the clock, not animated. A `repeatForever` animation
    /// also captures every layout change of the icon, so the row sliding in when the
    /// panel opens kept replaying as an endless bounce.
    var body: some View {
        TimelineView(.animation(paused: !spinning)) { context in
            IconView(icon: icon, size: glyph, tint: tint)
                .rotationEffect(.degrees(spinning ? angle(at: context.date) : 0))
        }
        .frame(width: box, height: box)
        .background(
            RoundedRectangle(cornerRadius: radius)
                .fill(Theme.Palette.controlHover)
                .opacity(hovering ? 1 : 0)
        )
        .contentShape(RoundedRectangle(cornerRadius: radius))
        .onHover { hovering = $0 }
    }

    private func angle(at date: Date) -> Double {
        let period = 0.9
        return date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period * 360
    }
}
