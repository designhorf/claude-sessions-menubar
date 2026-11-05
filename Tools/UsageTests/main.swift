import Foundation

// Checks the pure usage logic: parsing both JSON shapes and the sentences the cards say.
// Run by scripts/check.sh. Exits non-zero on the first failed expectation.

var failures = 0
func expect(_ condition: Bool, _ label: String) {
    if !condition { print("  FAIL  \(label)"); failures += 1 }
}

let now = Date(timeIntervalSince1970: 1_789_550_000)

// The live endpoint and the cache share one shape: `limits` with severity, flat windows
// with float utilization, timestamps with six fractional digits.
let full: [String: Any] = [
    "five_hour": ["utilization": 3.0, "resets_at": "2026-09-16T14:50:00.147475+00:00"],
    "seven_day": ["utilization": 16.0, "resets_at": "2026-09-20T06:00:00.147501+00:00"],
    "limits": [
        ["kind": "session", "percent": 15, "severity": "critical", "resets_at": "2026-09-16T09:50:00.257411+00:00"],
        ["kind": "weekly_all", "percent": 16, "severity": "normal", "resets_at": "2026-09-20T06:00:00.257485+00:00"],
    ],
    "seven_day_breakdown": ["rows": [["key": "claude_code", "percent": 96], ["key": "chat", "percent": 4]]],
]
let parsed = Usage(utilization: full, fetchedAt: now)
expect(parsed?.session?.percent == 15, "limits win over the flat window")
expect(parsed?.session?.isCritical == true, "severity critical is critical")
expect(parsed?.weekly?.isCritical == false, "severity normal is not critical")
expect(parsed?.claudeCodeShare == 96, "Claude Code share is read")
expect(parsed?.session?.resetsAt == Date(timeIntervalSince1970: 1_789_552_200), "six fractional digits parse")

let flatOnly: [String: Any] = ["five_hour": ["utilization": 3.4, "resets_at": NSNull()]]
let flat = Usage(utilization: flatOnly, fetchedAt: now)
expect(flat?.session?.percent == 3, "flat window is the fallback, rounded")
expect(flat?.weekly == nil && flat?.session?.resetsAt == nil, "missing parts stay nil")
expect(Usage(utilization: [:], fetchedAt: now) == nil, "no limits at all is no usage")

expect(UsageText.countdown(30) == "under a minute", "countdown under a minute")
expect(UsageText.countdown(4 * 60) == "4 min", "countdown minutes")
expect(UsageText.countdown(72 * 60) == "1 h 12 min", "countdown hours and minutes")
expect(UsageText.countdown(120 * 60) == "2 h", "countdown whole hours")
expect(UsageText.reset(now.addingTimeInterval(-60), now: now).hasPrefix("Reset at "), "past reset")
expect(UsageText.reset(now.addingTimeInterval(4 * 60), now: now).hasSuffix(", in 4 min"), "reset within a day")
expect(!UsageText.reset(now.addingTimeInterval(3 * 86_400), now: now).contains(" in "), "later reset names a weekday")
expect(UsageText.status("Offline", lastGood: nil) == "Offline", "status without old values")
expect(UsageText.status("Offline", lastGood: parsed).hasPrefix("Offline · "), "status names the age of the old values")

expect(UsageText.menuBar(parsed) == "A: 15% W: 16%", "menu bar title names both limits")
expect(UsageText.menuBar(flat) == "A: 3% W: –", "menu bar title marks a missing limit")
expect(UsageText.menuBar(nil) == nil, "no usage, no menu bar title")

print(failures == 0 ? "  ok    usage logic" : "  \(failures) usage expectation(s) failed")
exit(failures == 0 ? 0 : 1)
