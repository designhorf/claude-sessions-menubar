import AppKit
import SwiftUI

/// The panel's icons, from IBM Carbon (Apache-2.0, see README). Each is the original SVG
/// path data on Carbon's 32 grid. SF Symbols are not used, so every glyph comes from one
/// set. There is no asset catalog because the app is built by swiftc alone.
enum Icon: CaseIterable {
    case spark, play, stop, chevron, terminal, moon, sun, gear, server, power, clock, refresh, alert

    static let grid: CGFloat = 32

    private var pathData: [String] {
        switch self {
        case .spark:
            return [
            "m28.316 13.949l-.632-1.898L17 15.612V4h-2v11.612L4.316 12.051l-.632 1.898l10.684 3.561L7.2 27.066l1.6 1.201l7.2-9.6l7.2 9.6l1.6-1.201l-7.168-9.556z",
            ]
        case .play:
            return [
            "M7 28a1 1 0 0 1-1-1V5a1 1 0 0 1 1.482-.876l20 11a1 1 0 0 1 0 1.752l-20 11A1 1 0 0 1 7 28M8 6.69v18.62L24.925 16Z",
            ]
        case .stop:
            return [
            "M24 8v16H8V8zm0-2H8a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2",
            ]
        case .chevron:
            return [
            "M22 16L12 26l-1.4-1.4l8.6-8.6l-8.6-8.6L12 6z",
            ]
        case .terminal:
            return [
            "M26 4.01H6a2 2 0 0 0-2 2v20a2 2 0 0 0 2 2h20a2 2 0 0 0 2-2v-20a2 2 0 0 0-2-2m0 2v4H6v-4Zm-20 20v-14h20v14Z",
            "m10.76 16.18l2.82 2.83l-2.82 2.83l1.41 1.41l4.24-4.24l-4.24-4.24z",
            ]
        case .moon:
            return [
            "M13.503 5.414a15.076 15.076 0 0 0 11.593 18.194a11.1 11.1 0 0 1-7.975 3.39c-.138 0-.278.005-.418 0a11.094 11.094 0 0 1-3.2-21.584M14.98 3a1 1 0 0 0-.175.016a13.096 13.096 0 0 0 1.825 25.981c.164.006.328 0 .49 0a13.07 13.07 0 0 0 10.703-5.555a1.01 1.01 0 0 0-.783-1.565A13.08 13.08 0 0 1 15.89 4.38A1.015 1.015 0 0 0 14.98 3",
            ]
        case .sun:
            return [
            "M16 12.005a4 4 0 1 1-4 4a4.005 4.005 0 0 1 4-4m0-2a6 6 0 1 0 6 6a6 6 0 0 0-6-6M5.394 6.813L6.81 5.399l3.505 3.506L8.9 10.319zM2 15.005h5v2H2zm3.394 10.193L8.9 21.692l1.414 1.414l-3.505 3.506zM15 25.005h2v5h-2zm6.687-1.9l1.414-1.414l3.506 3.506l-1.414 1.414zm3.313-8.1h5v2h-5zm-3.313-6.101l3.506-3.506l1.414 1.414l-3.506 3.506zM15 2.005h2v5h-2z",
            ]
        case .gear:
            return [
            "M27 16.76v-1.53l1.92-1.68A2 2 0 0 0 29.3 11l-2.36-4a2 2 0 0 0-1.73-1a2 2 0 0 0-.64.1l-2.43.82a11 11 0 0 0-1.31-.75l-.51-2.52a2 2 0 0 0-2-1.61h-4.68a2 2 0 0 0-2 1.61l-.51 2.52a11.5 11.5 0 0 0-1.32.75l-2.38-.86A2 2 0 0 0 6.79 6a2 2 0 0 0-1.73 1L2.7 11a2 2 0 0 0 .41 2.51L5 15.24v1.53l-1.89 1.68A2 2 0 0 0 2.7 21l2.36 4a2 2 0 0 0 1.73 1a2 2 0 0 0 .64-.1l2.43-.82a11 11 0 0 0 1.31.75l.51 2.52a2 2 0 0 0 2 1.61h4.72a2 2 0 0 0 2-1.61l.51-2.52a11.5 11.5 0 0 0 1.32-.75l2.42.82a2 2 0 0 0 .64.1a2 2 0 0 0 1.73-1l2.28-4a2 2 0 0 0-.41-2.51ZM25.21 24l-3.43-1.16a8.9 8.9 0 0 1-2.71 1.57L18.36 28h-4.72l-.71-3.55a9.4 9.4 0 0 1-2.7-1.57L6.79 24l-2.36-4l2.72-2.4a8.9 8.9 0 0 1 0-3.13L4.43 12l2.36-4l3.43 1.16a8.9 8.9 0 0 1 2.71-1.57L13.64 4h4.72l.71 3.55a9.4 9.4 0 0 1 2.7 1.57L25.21 8l2.36 4l-2.72 2.4a8.9 8.9 0 0 1 0 3.13L27.57 20Z",
            "M16 22a6 6 0 1 1 6-6a5.94 5.94 0 0 1-6 6m0-10a3.91 3.91 0 0 0-4 4a3.91 3.91 0 0 0 4 4a3.91 3.91 0 0 0 4-4a3.91 3.91 0 0 0-4-4",
            ]
        case .server:
            return [
            "M24 3H8a2 2 0 0 0-2 2v22a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2m0 2v6H8V5ZM8 19v-6h16v6Zm0 8v-6h16v6Z",
            "M10 8a1 1 0 1 0 2 0a1 1 0 1 0 -2 0z",
            "M10 16a1 1 0 1 0 2 0a1 1 0 1 0 -2 0z",
            "M10 24a1 1 0 1 0 2 0a1 1 0 1 0 -2 0z",
            ]
        case .power:
            return [
            "m22.5 5.74l-1 1.73a11 11 0 1 1-11 0l-1-1.73a13 13 0 1 0 13 0",
            "M15 2h2v14h-2z",
            ]
        case .clock:
            return [
            "M16 30a14 14 0 1 1 14-14a14 14 0 0 1-14 14m0-26a12 12 0 1 0 12 12A12 12 0 0 0 16 4",
            "M20.59 22L15 16.41V7h2v8.58l5 5.01z",
            ]
        case .refresh:
            return [
            "M12 10H6.78A11 11 0 0 1 27 16h2A13 13 0 0 0 6 7.68V4H4v8h8Zm8 12h5.22A11 11 0 0 1 5 16H3a13 13 0 0 0 23 8.32V28h2v-8h-8Z",
            ]
        case .alert:
            return [
            "M16 2a14 14 0 1 0 14 14A14 14 0 0 0 16 2m0 26a12 12 0 1 1 12-12a12 12 0 0 1-12 12",
            "M15 8h2v11h-2zm1 14a1.5 1.5 0 1 0 1.5 1.5A1.5 1.5 0 0 0 16 22",
            ]
        }
    }

    private static let paths: [Icon: CGPath] = Dictionary(
        uniqueKeysWithValues: allCases.map { icon in
            let path = CGMutablePath()
            icon.pathData.forEach { SVGPath.append($0, to: path) }
            return (icon, path)
        }
    )

    var cgPath: CGPath { Icon.paths[self] ?? CGMutablePath() }

    /// A menu bar label takes only an image or text, not a shape, and a template image
    /// is what lets the system tint it for the menu bar behind it.
    func templateImage(size: CGFloat) -> NSImage {
        let image = drawnImage(size: size, color: .black)
        image.isTemplate = true
        return image
    }

    /// A borderless Menu's label is drawn by AppKit, which keeps only an image or text and
    /// drops a SwiftUI shape without a word. The colour resolves while drawing, so it
    /// follows the panel's appearance.
    func tintedImage(size: CGFloat, color: Color) -> NSImage {
        drawnImage(size: size, color: NSColor(color))
    }

    private func drawnImage(size: CGFloat, color: NSColor) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.scaleBy(x: size / Icon.grid, y: size / Icon.grid)
            context.addPath(cgPath)
            context.setFillColor(color.cgColor)
            context.fillPath()
            return true
        }
    }
}

struct IconShape: Shape {
    let icon: Icon

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / Icon.grid
        return Path(icon.cgPath).applying(
            CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: scale, y: scale)
        )
    }
}

struct IconView: View {
    let icon: Icon
    var size: CGFloat = Theme.IconSize.row
    var tint: Color = Theme.Palette.textSecondary

    var body: some View {
        IconShape(icon: icon)
            .fill(tint)
            .frame(width: size, height: size)
    }
}
