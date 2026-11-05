import AppKit
import SwiftUI

/// Every colour, size and radius in the panel comes from here. Nothing downstream
/// hardcodes a value. The look: a raised grey top holding the header and usage, short
/// rows split by hairlines below it, Carbon icons leading each row.
enum Theme {

    /// Each colour carries a light and a dark value and resolves against the appearance
    /// the panel is drawn in, so no view has to know which mode is on.
    enum Palette {
        static let surface        = Color(light: 0xFFFFFF, dark: 0x232326)
        static let raised         = Color(light: 0xF4F4F5, dark: 0x2C2C30)
        static let rowHover       = Color(light: 0xF4F4F5, dark: 0x2C2C30)
        static let controlHover   = Color(light: 0xE6E6E9, dark: 0x404044)
        static let meterTrack     = Color(light: 0xE4E4E7, dark: 0x4A4A4D)
        static let divider        = Color(light: 0xE6E6E9, dark: 0x38383C)

        static let textPrimary    = Color(light: 0x111113, dark: 0xF5F5F7)
        static let textSecondary  = Color(light: 0x66666B, dark: 0xA9A9AE)

        /// Dark enough to reach 3:1 against the track, which the earlier yellow start did not.
        static let meter          = [Color(light: 0xC8620C, dark: 0xF5A524), Color(light: 0xB04A08, dark: 0xFF8A1F)]
        /// A ring is too short for a gradient to read, so it takes the gradient's end.
        static let ring           = Color(light: 0xB04A08, dark: 0xFF8A1F)
        static let meterCritical  = [Color(light: 0xD6333A, dark: 0xFF8A5B), Color(light: 0xB81F26, dark: 0xFF4D4F)]
        static let critical       = Color(light: 0xB8222A, dark: 0xFF7B7B)
        /// Numbers left over from a failed refresh. A grey rather than an opacity, because
        /// an opacity takes the text under the contrast minimum.
        static let stale          = Color(light: 0x7C7C82, dark: 0x8E8E93)

        /// Green means running and nothing else, so no other element uses it.
        static let running        = Color(light: 0x157A3F, dark: 0x4AD07C)
    }

    enum Space {
        static let hairGap: CGFloat = 1
        static let xs: CGFloat = 2
        static let sm: CGFloat = 4
        static let md: CGFloat = 6
        static let lg: CGFloat = 8
        static let xl: CGFloat = 10
        /// Between the window edge and the raised top, so the two corners read as one.
        static let panelInset: CGFloat = 3
        static let rowVertical: CGFloat = 7
        /// Lines up an opened context line with the row title: icon plus gap.
        static let rowTextIndent: CGFloat = 36
    }

    enum Size {
        static let tile: CGFloat = 36
        static let meter: CGFloat = 5
        static let ring: CGFloat = 16
        static let ringLine: CGFloat = 2.2
        static let headerButton: CGFloat = 28
        static let miniButton: CGFloat = 24
        static let headerHeight: CGFloat = 52
        /// The Usage row keeps this height open and folded, so nothing in it moves.
        static let usageRow: CGFloat = 36
        static let hairline: CGFloat = 1
        /// The width a long title keeps when the row cannot fit it and the project name.
        static let rowTitleShare: CGFloat = 0.62
    }

    enum IconSize {
        static let row: CGFloat = 16
        static let tile: CGFloat = 18
        static let header: CGFloat = 16
        static let mini: CGFloat = 14
        static let chevron: CGFloat = 12
        static let status: CGFloat = 13
        static let menuBar: CGFloat = 15
    }

    enum Radius {
        static let raised: CGFloat = 12
        static let tile: CGFloat = 10
        static let control: CGFloat = 8
        static let mini: CGFloat = 6
    }

    enum Motion {
        static let fold = Animation.easeInOut(duration: 0.22)
        static let disclose = Animation.easeOut(duration: 0.18)
    }

    enum Opacity {
        /// A server row while it is being stopped.
        static let stopping: Double = 0.45
        static let tileShadow: Double = 0.06
    }

    enum Shadow {
        static let tileRadius: CGFloat = 1
        static let tileOffset: CGFloat = 1
    }

    enum Typography {
        static let panelName  = Font.system(size: 14, weight: .semibold)
        static let headerSub  = Font.system(size: 12, weight: .regular)
        static let section    = Font.system(size: 13, weight: .semibold)
        static let count      = Font.system(size: 13, weight: .regular)
        static let rowTitle   = Font.system(size: 13, weight: .medium)
        static let meta       = Font.system(size: 12, weight: .regular)
        static let limitName  = Font.system(size: 13, weight: .regular)
        static let limitValue = Font.system(size: 13, weight: .semibold)
        static let ringName   = Font.system(size: 12, weight: .regular)
        static let ringValue  = Font.system(size: 12, weight: .semibold)
        static let textButton = Font.system(size: 12, weight: .medium)
        static let status     = Font.system(size: 12, weight: .regular)
    }

    static let panelWidth: CGFloat = 400
    /// The rows scroll below the raised top, which stays on screen.
    static let listMaxHeight: CGFloat = 460
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
