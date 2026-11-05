import SwiftUI

/// Closed points right, open turns a quarter turn and points down. Used by every
/// disclosure in the panel so the gesture reads the same everywhere.
struct DisclosureChevron: View {
    let expanded: Bool

    var body: some View {
        IconView(icon: .chevron, size: Theme.IconSize.chevron)
            .rotationEffect(.degrees(expanded ? 90 : 0))
    }
}
