import SwiftUI

/// The dot carries the colour so the label stays readable at every tint.
struct Pill: View {
    let label: String
    var dot: Color?

    var body: some View {
        HStack(spacing: Theme.Space.sm) {
            if let dot {
                Circle()
                    .fill(dot)
                    .frame(width: 6, height: 6)
            }
            Text(label)
                .font(Theme.Typography.pill)
                .foregroundStyle(Theme.Palette.textSecondary)
        }
        .padding(.horizontal, Theme.Space.md)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.pill)
                .fill(Theme.Palette.pillFill)
        )
    }
}
