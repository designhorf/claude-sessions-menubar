import Foundation

/// The sentences the usage cards say. Kept apart from the views so the wording can be
/// checked without rendering anything.
enum UsageText {

    private static let dayLength: TimeInterval = 24 * 60 * 60

    /// A reset within a day reads as a clock time and a countdown; a later one as a
    /// weekday, because "in 3 d 14 h" is harder to picture than "Saturday".
    static func reset(_ date: Date, now: Date = Date()) -> String {
        let remaining = date.timeIntervalSince(now)
        if remaining <= 0 { return "Reset at \(clock(date))" }
        if remaining < dayLength { return "Resets \(clock(date)), in \(countdown(remaining))" }
        return "Resets \(weekday(date)) \(clock(date))"
    }

    static func share(_ percent: Int) -> String {
        "Claude Code used \(percent)% of this week."
    }

    /// "Offline · 12:34": what went wrong, and how old the numbers still on screen are.
    static func status(_ problem: String, lastGood: Usage?) -> String {
        guard let lastGood else { return problem }
        return "\(problem) · \(clock(lastGood.fetchedAt))"
    }

    static func percent(_ limit: Usage.Limit?) -> String {
        limit.map { "\($0.percent)%" } ?? "–"
    }

    /// The menu bar title: "A: 12% W: 25%", the 5-hour window and the weekly limit.
    static func menuBar(_ usage: Usage?) -> String? {
        guard let usage, usage.session != nil || usage.weekly != nil else { return nil }
        return "A: \(percent(usage.session)) W: \(percent(usage.weekly))"
    }

    // MARK: - Pieces

    static func countdown(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 1 { return "under a minute" }
        if minutes < 60 { return "\(minutes) min" }
        let rest = minutes % 60
        return rest == 0 ? "\(minutes / 60) h" : "\(minutes / 60) h \(rest) min"
    }

    static func clock(_ date: Date) -> String {
        formatter("HH:mm").string(from: date)
    }

    private static func weekday(_ date: Date) -> String {
        formatter("EEEE").string(from: date)
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }
}
