import SwiftUI

/// A section title with its count, and an optional text action on the right. Every
/// section but the first is set off by a hairline.
struct SectionHeader: View {
    let title: String
    let count: Int
    var isFirst = false
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if !isFirst {
                Hairline()
                    .padding(.top, Theme.Space.xs)
            }
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.md) {
                Text(title)
                    .font(Theme.Typography.section)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("\(count)")
                    .font(Theme.Typography.count)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Palette.textSecondary)
                Spacer()
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.plain)
                        .font(Theme.Typography.textButton)
                        .foregroundStyle(Theme.Palette.textPrimary)
                }
            }
            .padding(.horizontal, Theme.Space.xl)
            .padding(.top, Theme.Space.rowVertical)
            .padding(.bottom, Theme.Space.xs)
        }
    }
}
