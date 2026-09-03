import SwiftUI

/// Every colour, size and radius in the panel comes from here. Nothing downstream
/// hardcodes a value.
enum Theme {

    enum Palette {
        static let surface        = Color(hex: 0xFFFFFF)
        static let card           = Color(hex: 0xFBFBFC)
        static let cardHover      = Color(hex: 0xF4F4F6)
        static let border         = Color(hex: 0xE8E8EC)
        static let divider        = Color(hex: 0xEFEFF2)

        static let textPrimary    = Color(hex: 0x17171A)
        static let textSecondary  = Color(hex: 0x6C7078)
        static let textTertiary   = Color(hex: 0x9CA0A8)

        static let accent         = Color(hex: 0x5E6AD2)
        static let working        = Color(hex: 0xE0A22F)
        static let pillFill       = Color(hex: 0xF4F4F6)
    }

    /// Category colour is carried by the dot inside a pill, never by a bar on the
    /// edge of the card.
    static let projectColors: [Color] = [
        Color(hex: 0x5E6AD2),  // indigo
        Color(hex: 0x3E9EE3),  // blue
        Color(hex: 0x4CB782),  // green
        Color(hex: 0xE0A22F),  // amber
        Color(hex: 0xEB5757),  // red
        Color(hex: 0x9B7FE8),  // purple
        Color(hex: 0x2FB0AB),  // teal
        Color(hex: 0xE07AA8),  // pink
    ]

    /// Stable per project, so a folder keeps its colour between launches.
    static func projectColor(for key: String) -> Color {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in key.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100000001b3
        }
        return projectColors[Int(hash % UInt64(projectColors.count))]
    }

    enum Space {
        static let xs: CGFloat = 2
        static let sm: CGFloat = 4
        static let md: CGFloat = 6
        static let lg: CGFloat = 8
        static let xl: CGFloat = 12
    }

    enum IconSize {
        static let chevron: CGFloat = 10
        static let sectionState: CGFloat = 11
        static let settings: CGFloat = 12
    }

    enum Radius {
        static let card: CGFloat = 7
        static let pill: CGFloat = 999
        static let control: CGFloat = 5
    }

    enum Typography {
        static let meta      = Font.system(size: 11, weight: .regular)
        static let title     = Font.system(size: 13, weight: .medium)
        static let section   = Font.system(size: 11, weight: .semibold)
        static let pill      = Font.system(size: 11, weight: .medium)
        static let panelName = Font.system(size: 12, weight: .semibold)
    }

    static let panelWidth: CGFloat = 400
    static let listMaxHeight: CGFloat = 600
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: 1
        )
    }
}
