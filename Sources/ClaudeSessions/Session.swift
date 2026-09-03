import Foundation

/// One running Claude Code session, assembled from the pid record and the
/// transcript that belongs to it.
struct Session: Identifiable, Equatable {
    let id: String          // sessionId
    let pid: Int32
    let name: String
    let cwd: String
    let startedAt: Date
    let isBusy: Bool
    let title: String?
    let opening: String?
    let lastActivity: Date?

    var projectName: String {
        (cwd as NSString).lastPathComponent
    }

    var shortPath: String {
        let parts = (cwd as NSString).pathComponents.filter { $0 != "/" }
        return parts.suffix(2).joined(separator: "/")
    }

    var age: String { Session.age(since: startedAt) }

    static func age(since date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }

    var subject: String { title ?? "Untitled" }

    /// How long since the session last changed state, which for an idle session says
    /// more than how long ago it was started.
    var lastActivityAge: String? {
        guard let lastActivity else { return nil }
        return Session.age(since: lastActivity)
    }

    var resumeCommand: String { "claude --resume \(id)" }
}
