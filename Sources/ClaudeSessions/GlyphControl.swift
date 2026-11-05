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

    @State private var turning = false
    @State private var hovering = false

    var body: some View {
        IconView(icon: icon, size: glyph, tint: tint)
            .rotationEffect(.degrees(turning ? 360 : 0))
            .animation(
                spinning ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default,
                value: turning
            )
            .frame(width: box, height: box)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Theme.Palette.controlHover)
                    .opacity(hovering ? 1 : 0)
            )
            .contentShape(RoundedRectangle(cornerRadius: radius))
            .onHover { hovering = $0 }
            .onAppear { turning = spinning }
            .onChange(of: spinning) { turning = $0 }
    }
}
