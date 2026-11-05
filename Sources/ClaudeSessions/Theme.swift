import AppKit
import SwiftUI

/// Every colour, size and radius in the panel comes from here. Nothing downstream
/// hardcodes a value. The look follows `docs/usage-design.html`: borderless soft grey
/// cards on white, icon bubbles, meters with a warm gradient.
enum Theme {

    /// Each colour carries a light and a dark value and resolves against the appearance
    /// the panel is drawn in, so no view has to know which mode is on.
    enum Palette {
        static let surface        = Color(light: 0xFFFFFF, dark: 0x1C1C1E)
        static let card           = Color(light: 0xF2F2F3, dark: 0x2C2C2E)
        static let cardHover      = Color(light: 0xEAEAEC, dark: 0x343437)
        static let bubble         = Color(light: 0xE3E3E6, dark: 0x3A3A3C)
        static let meterTrack     = Color(light: 0xDDDDE0, dark: 0x48484A)
        static let divider        = Color(light: 0xE3E3E6, dark: 0x3A3A3C)

        static let textPrimary    = Color(light: 0x111113, dark: 0xF5F5F7)
        static let textSecondary  = Color(light: 0x6E6E73, dark: 0xA1A1A6)
        static let textTertiary   = Color(light: 0x8E8E93, dark: 0x7C7C80)

        static let meter          = [Color(light: 0xFFD84D, dark: 0xFFD84D), Color(light: 0xFF8A1F, dark: 0xFF8A1F)]
        /// A ring is too short for a gradient to read, so it takes the gradient's end.
        static let ring           = Color(light: 0xFF8A1F, dark: 0xFF8A1F)
        static let meterCritical  = [Color(light: 0xFF8A5B, dark: 0xFF8A5B), Color(light: 0xE5383B, dark: 0xFF4D4F)]
        static let critical       = Color(light: 0xD6333A, dark: 0xFF6B6B)

        /// Green means running and nothing else, so no other element uses it.
        static let running        = Color(light: 0x22A55A, dark: 0x34C76A)
        static let runningTint    = Color(light: 0xDDF3E5, dark: 0x1E3A28)
        static let stopped        = Color(light: 0x8E8E93, dark: 0x8E8E93)
        static let stoppedTint    = Color(light: 0xE3E3E6, dark: 0x3A3A3C)
    }

    enum Space {
        static let xs: CGFloat = 2
        static let sm: CGFloat = 4
        static let md: CGFloat = 6
        static let lg: CGFloat = 8
        static let xl: CGFloat = 12
        static let xxl: CGFloat = 14
        static let panel: CGFloat = 16
    }

    enum Size {
        static let bubble: CGFloat = 34
        static let meter: CGFloat = 6
        static let ring: CGFloat = 16
        static let ringLine: CGFloat = 2.4
        static let settingsButton: CGFloat = 28
        static let refreshButton: CGFloat = 24
        /// The Usage row keeps this height open and folded, so nothing in it moves.
        static let usageRow: CGFloat = 24
        static let chevronHitArea: CGFloat = 20
        /// A button trailing a card row, such as stopping a server.
        static let rowAction: CGFloat = 26
    }

    enum IconSize {
        static let bubbleGlyph: CGFloat = 15
        static let stateGlyph: CGFloat = 12
        static let chevron: CGFloat = 12
        static let settings: CGFloat = 13
        static let refresh: CGFloat = 11
        static let status: CGFloat = 11
        static let rowAction: CGFloat = 12
    }

    enum Radius {
        static let card: CGFloat = 14
    }

    enum Motion {
        static let fold = Animation.easeInOut(duration: 0.22)
    }

    enum Opacity {
        /// Values that are waiting for a refresh, or left over from a failed one.
        static let staleValue: Double = 0.4
        static let staleMeter: Double = 0.35
    }

    enum Typography {
        static let panelName  = Font.system(size: 16, weight: .semibold)
        static let meta       = Font.system(size: 11, weight: .regular)
        static let rowTitle   = Font.system(size: 14, weight: .semibold)
        static let rowSub     = Font.system(size: 13, weight: .regular)
        static let rowValue   = Font.system(size: 14, weight: .bold)
        static let section    = Font.system(size: 13, weight: .semibold)
        static let count      = Font.system(size: 13, weight: .regular)
        static let textButton = Font.system(size: 13, weight: .semibold)
        static let ringValue  = Font.system(size: 13, weight: .bold)
        static let status     = Font.system(size: 12, weight: .regular)
    }

    static let panelWidth: CGFloat = 400
    static let listMaxHeight: CGFloat = 640
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green:   CGFloat((hex >> 8)  & 0xFF) / 255,
            blue:    CGFloat( hex        & 0xFF) / 255,
            alpha: 1
        )
    }
}
