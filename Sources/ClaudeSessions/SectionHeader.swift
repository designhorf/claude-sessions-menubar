import SwiftUI

/// A section title with its count, and an optional text action on the right.
struct SectionHeader: View {
    let title: String
    let count: Int
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.md) {
            Text(title)
                .font(Theme.Typography.section)
                .foregroundStyle(Theme.Palette.textPrimary)
            Text("\(count)")
                .font(Theme.Typography.count)
                .monospacedDigit()
                .foregroundStyle(Theme.Palette.textTertiary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.plain)
                    .font(Theme.Typography.textButton)
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
        }
        .padding(.horizontal, Theme.Space.sm)
        .padding(.top, Theme.Space.xl)
    }
}
