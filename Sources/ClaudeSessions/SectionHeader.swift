import SwiftUI

struct SectionHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    let count: Int
    var collapsible: Bool = false
    var expanded: Bool = false
    var toggle: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.Space.md) {
            Image(systemName: icon)
                .font(.system(size: Theme.IconSize.sectionState, weight: .medium))
                .foregroundStyle(iconColor)
            Text(title)
                .font(Theme.Typography.section)
                .foregroundStyle(Theme.Palette.textPrimary)
            Text("\(count)")
                .font(Theme.Typography.meta)
                .monospacedDigit()
                .foregroundStyle(Theme.Palette.textTertiary)
            Spacer()
            if collapsible {
                DisclosureChevron(expanded: expanded)
            }
        }
        .padding(.horizontal, Theme.Space.sm)
        .padding(.vertical, Theme.Space.md)
        .contentShape(Rectangle())
        .onTapGesture { toggle?() }
    }
}
