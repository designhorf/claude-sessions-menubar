import SwiftUI

/// Closed points right, open turns a quarter turn and points down. Used by every
/// disclosure in the panel so the gesture reads the same everywhere.
struct DisclosureChevron: View {
    let expanded: Bool
    var size: CGFloat = Theme.IconSize.chevron

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(Theme.Palette.textPrimary)
            .rotationEffect(.degrees(expanded ? 90 : 0))
    }
}
