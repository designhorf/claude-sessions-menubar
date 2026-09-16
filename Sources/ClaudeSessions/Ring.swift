import SwiftUI

/// A small progress ring for the folded usage card.
struct Ring: View {
    let percent: Int
    var isCritical = false
    var isStale = false

    private var fraction: CGFloat { CGFloat(min(max(percent, 0), 100)) / 100 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Palette.meterTrack, lineWidth: Theme.Size.ringLine)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(isCritical ? Theme.Palette.critical : Theme.Palette.ring,
                        style: StrokeStyle(lineWidth: Theme.Size.ringLine, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(isStale ? Theme.Opacity.staleMeter : 1)
        }
        .frame(width: Theme.Size.ring, height: Theme.Size.ring)
    }
}
