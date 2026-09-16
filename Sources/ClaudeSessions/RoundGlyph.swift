import SwiftUI

/// A symbol in a small circle: the settings gear and the refresh button. While
/// `spinning` the symbol turns, for a request in flight. With `fillOnHover` the circle
/// only appears under the pointer, so a quiet control does not look pressed.
struct RoundGlyph: View {
    let symbol: String
    let diameter: CGFloat
    let glyphSize: CGFloat
    var fill: Color = Theme.Palette.card
    var tint: Color = Theme.Palette.textSecondary
    var spinning = false
    var fillOnHover = false

    @State private var turning = false
    @State private var hovering = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: glyphSize, weight: .semibold))
            .foregroundStyle(tint)
            .rotationEffect(.degrees(turning ? 360 : 0))
            .animation(
                spinning ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default,
                value: turning
            )
            .frame(width: diameter, height: diameter)
            .background(Circle().fill(fill).opacity(!fillOnHover || hovering ? 1 : 0))
            .contentShape(Circle())
            .onHover { hovering = $0 }
            .onAppear { turning = spinning }
            .onChange(of: spinning) { turning = $0 }
    }
}
