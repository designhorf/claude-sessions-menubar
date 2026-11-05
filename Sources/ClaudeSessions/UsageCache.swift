import Foundation

/// The last usage Claude Code itself fetched, from `~/.claude.json`. Read on launch so
/// the panel has numbers before the first live request returns. Never written.
enum UsageCache {

    private static var file: URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: ".claude.json")
    }

    static func load() -> Usage? {
        guard let data = try? Data(contentsOf: file),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cached = root["cachedUsageUtilization"] as? [String: Any],
              let utilization = cached["utilization"] as? [String: Any],
              let fetchedMs = cached["fetchedAtMs"] as? Double
        else { return nil }
        return Usage(utilization: utilization, fetchedAt: Date(timeIntervalSince1970: fetchedMs / 1000))
    }
}
