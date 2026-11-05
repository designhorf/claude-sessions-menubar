import Foundation

/// Plan usage as `/usage` reports it: the 5-hour session window and the weekly limit.
struct Usage: Equatable {
    let session: Limit?
    let weekly: Limit?
    /// Claude Code's share of this week's usage, in percent.
    let claudeCodeShare: Int?
    let fetchedAt: Date

    struct Limit: Equatable {
        let percent: Int
        let resetsAt: Date?
        let isCritical: Bool
    }
}

extension Usage {

    /// Reads the JSON the usage endpoint returns. Claude Code stores the same object in
    /// `~/.claude.json`, so the cache and the live response go through this one door.
    /// `limits` is preferred because it carries a severity; the flat windows are the
    /// fallback, so a response missing one still shows a number.
    init?(utilization json: [String: Any], fetchedAt: Date) {
        let limits = json["limits"] as? [[String: Any]] ?? []
        let session = Usage.limit(kind: "session", in: limits) ?? Usage.window("five_hour", in: json)
        let weekly = Usage.limit(kind: "weekly_all", in: limits) ?? Usage.window("seven_day", in: json)
        guard session != nil || weekly != nil else { return nil }

        let rows = (json["seven_day_breakdown"] as? [String: Any])?["rows"] as? [[String: Any]] ?? []
        let share = rows.first { $0["key"] as? String == "claude_code" }
            .flatMap { Usage.integer($0["percent"]) }

        self.init(session: session, weekly: weekly, claudeCodeShare: share, fetchedAt: fetchedAt)
    }

    private static func limit(kind: String, in limits: [[String: Any]]) -> Limit? {
        guard let entry = limits.first(where: { $0["kind"] as? String == kind }),
              let percent = integer(entry["percent"])
        else { return nil }
        return Limit(
            percent: percent,
            resetsAt: date(entry["resets_at"]),
            isCritical: isCritical(severity: entry["severity"] as? String)
        )
    }

    private static func window(_ key: String, in json: [String: Any]) -> Limit? {
        guard let window = json[key] as? [String: Any],
              let percent = integer(window["utilization"])
        else { return nil }
        return Limit(percent: percent, resetsAt: date(window["resets_at"]), isCritical: false)
    }

    /// The panel turns red only when the data says so; it does not pick its own
    /// threshold. Only "normal" has been seen so far, so the match is deliberately loose.
    static func isCritical(severity: String?) -> Bool {
        guard let severity = severity?.lowercased() else { return false }
        return ["critical", "exceeded", "limited", "blocked"].contains { severity.contains($0) }
    }

    /// Percentages arrive as `15` in `limits` and as `15.0` in the flat windows.
    private static func integer(_ value: Any?) -> Int? {
        (value as? NSNumber).map { Int($0.doubleValue.rounded()) }
    }

    /// The timestamps carry six fractional digits, which `ISO8601DateFormatter` rejects
    /// even with `.withFractionalSeconds`, so the fraction is dropped before parsing.
    static func date(_ value: Any?) -> Date? {
        guard let text = value as? String else { return nil }
        let trimmed = text.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
        return ISO8601DateFormatter().date(from: trimmed)
    }
}
