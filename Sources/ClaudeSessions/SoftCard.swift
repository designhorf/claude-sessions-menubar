import SwiftUI

/// The borderless grey card every block in the panel sits on.
struct SoftCard: ViewModifier {
    var hoverable = false
    var horizontalPadding = Theme.Space.xxl
    var verticalPadding = Theme.Space.xxl
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(hoverable && hovering ? Theme.Palette.cardHover : Theme.Palette.card)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .onHover { hovering = $0 }
    }
}

extension View {
    func softCard(hoverable: Bool = false,
                  horizontalPadding: CGFloat = Theme.Space.xxl,
                  verticalPadding: CGFloat = Theme.Space.xxl) -> some View {
        modifier(SoftCard(hoverable: hoverable, horizontalPadding: horizontalPadding,
                          verticalPadding: verticalPadding))
    }
}
