import CoreGraphics
import Foundation

/// The subset of SVG path data the icons use: M L H V C A Z, absolute and relative.
enum SVGPath {
    static func append(_ data: String, to path: CGMutablePath) {
        var scanner = Scanner(data)
        var command: Character = "M"
        var current = CGPoint.zero
        var start = CGPoint.zero

        while let next = scanner.peekCommand() ?? (scanner.isAtEnd ? nil : command) {
            if scanner.peekCommand() != nil { scanner.advance() }
            command = next
            let relative = command.isLowercase
            let base = relative ? current : .zero

            switch Character(command.uppercased()) {
            case "M":
                guard let point = scanner.point(base) else { return }
                path.move(to: point)
                current = point
                start = point
                command = relative ? "l" : "L"
            case "L":
                guard let point = scanner.point(base) else { return }
                path.addLine(to: point)
                current = point
            case "H":
                guard let x = scanner.number() else { return }
                current = CGPoint(x: x + base.x, y: current.y)
                path.addLine(to: current)
            case "V":
                guard let y = scanner.number() else { return }
                current = CGPoint(x: current.x, y: y + base.y)
                path.addLine(to: current)
            case "C":
                guard let c1 = scanner.point(base), let c2 = scanner.point(base),
                      let end = scanner.point(base) else { return }
                path.addCurve(to: end, control1: c1, control2: c2)
                current = end
            case "A":
                guard let rx = scanner.number(), let ry = scanner.number(), let rotation = scanner.number(),
                      let large = scanner.flag(), let sweep = scanner.flag(),
                      let end = scanner.point(base) else { return }
                addArc(to: path, from: current, to: end, rx: abs(rx), ry: abs(ry),
                       rotation: rotation * .pi / 180, large: large, sweep: sweep)
                current = end
            case "Z":
                path.closeSubpath()
                current = start
            default:
                return
            }
        }
    }

    /// SVG gives an arc by its endpoints and CoreGraphics wants a centre, so this is the
    /// conversion from section F.6.5 of the SVG specification, drawn as cubic segments.
    private static func addArc(to path: CGMutablePath, from p0: CGPoint, to p1: CGPoint, rx rx0: CGFloat, ry ry0: CGFloat,
                               rotation phi: CGFloat, large: Bool, sweep: Bool) {
        guard rx0 > 0, ry0 > 0, p0 != p1 else {
            path.addLine(to: p1)
            return
        }
        let cosPhi = cos(phi), sinPhi = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1 = cosPhi * dx + sinPhi * dy
        let y1 = -sinPhi * dx + cosPhi * dy

        var rx = rx0, ry = ry0
        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lambda > 1 {
            rx *= lambda.squareRoot()
            ry *= lambda.squareRoot()
        }
        let numerator = max(0, rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1)
        let denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1
        let factor = (large == sweep ? -1 : 1) * (numerator / denominator).squareRoot()
        let cx1 = factor * rx * y1 / ry
        let cy1 = -factor * ry * x1 / rx
        let cx = cosPhi * cx1 - sinPhi * cy1 + (p0.x + p1.x) / 2
        let cy = sinPhi * cx1 + cosPhi * cy1 + (p0.y + p1.y) / 2

        let theta = atan2((y1 - cy1) / ry, (x1 - cx1) / rx)
        var delta = atan2((-y1 - cy1) / ry, (-x1 - cx1) / rx) - theta
        if sweep, delta < 0 { delta += 2 * .pi }
        if !sweep, delta > 0 { delta -= 2 * .pi }

        let segments = max(1, Int(ceil(abs(delta) / (.pi / 2))))
        let step = delta / CGFloat(segments)
        let handle = 4 / 3 * tan(step / 4)
        let point = { (x: CGFloat, y: CGFloat) in
            CGPoint(x: cx + cosPhi * rx * x - sinPhi * ry * y, y: cy + sinPhi * rx * x + cosPhi * ry * y)
        }
        for index in 0..<segments {
            let a = theta + CGFloat(index) * step
            let b = a + step
            let last = index == segments - 1
            path.addCurve(
                to: last ? p1 : point(cos(b), sin(b)),
                control1: point(cos(a) - handle * sin(a), sin(a) + handle * cos(a)),
                control2: point(cos(b) + handle * sin(b), sin(b) - handle * cos(b))
            )
        }
    }

    private struct Scanner {
        private let bytes: [Character]
        private var index = 0

        init(_ text: String) { bytes = Array(text) }

        var isAtEnd: Bool {
            var probe = index
            while probe < bytes.count, Scanner.isSeparator(bytes[probe]) { probe += 1 }
            return probe >= bytes.count
        }

        mutating func peekCommand() -> Character? {
            skipSeparators()
            guard index < bytes.count, bytes[index].isLetter else { return nil }
            return bytes[index]
        }

        mutating func advance() { index += 1 }

        mutating func point(_ base: CGPoint) -> CGPoint? {
            guard let x = number(), let y = number() else { return nil }
            return CGPoint(x: x + base.x, y: y + base.y)
        }

        /// An arc flag is one character, and minified data runs it into the next number.
        mutating func flag() -> Bool? {
            skipSeparators()
            guard index < bytes.count, bytes[index] == "0" || bytes[index] == "1" else { return nil }
            defer { index += 1 }
            return bytes[index] == "1"
        }

        /// Minified data has no separator before a sign or a second decimal point.
        mutating func number() -> CGFloat? {
            skipSeparators()
            let begin = index
            if index < bytes.count, bytes[index] == "-" || bytes[index] == "+" { index += 1 }
            var seenPoint = false
            while index < bytes.count {
                let c = bytes[index]
                if c.isNumber {
                    index += 1
                } else if c == ".", !seenPoint {
                    seenPoint = true
                    index += 1
                } else {
                    break
                }
            }
            guard index > begin else { return nil }
            return Double(String(bytes[begin..<index])).map { CGFloat($0) }
        }

        private mutating func skipSeparators() {
            while index < bytes.count, Scanner.isSeparator(bytes[index]) { index += 1 }
        }

        private static func isSeparator(_ c: Character) -> Bool { c == " " || c == "," || c == "\n" }
    }
}
