import SwiftUI

/// A thin rounded bar. The gradient runs inside the filled part; it turns red only
/// when the data marks the limit critical.
struct Meter: View {
    let percent: Int
    var isCritical = false
    var isStale = false

    private var fraction: CGFloat { CGFloat(min(max(percent, 0), 100)) / 100 }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.meterTrack)
                Capsule()
                    .fill(LinearGradient(
                        colors: isStale ? [Theme.Palette.stale, Theme.Palette.stale]
                            : isCritical ? Theme.Palette.meterCritical : Theme.Palette.meter,
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    // A 0% bar still shows a sliver, so an empty meter reads as a meter.
                    .frame(width: max(Theme.Size.meter, geometry.size.width * fraction))
            }
        }
        .frame(height: Theme.Size.meter)
    }
}
