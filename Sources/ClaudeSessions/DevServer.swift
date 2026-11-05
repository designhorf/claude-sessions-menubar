import Foundation

/// A process started from a project folder that listens on a local TCP port: a dev
/// server, a preview, a static file server.
struct DevServer: Identifiable, Equatable {
    let pid: Int32
    let ports: [Int]
    let cwd: String
    let startedAt: Date
    /// Physical footprint of the server and everything it started, in bytes. The same
    /// figure Activity Monitor calls Memory.
    let footprint: UInt64

    var id: Int32 { pid }

    /// In a monorepo the server runs from `apps/ui`, and "ui" alone does not say which
    /// repo it is, so the repo name leads.
    var projectName: String {
        let parts = (cwd as NSString).pathComponents
        guard parts.count >= 3, Self.workspaceFolders.contains(parts[parts.count - 2]) else {
            return parts.last ?? cwd
        }
        return "\(parts[parts.count - 3])/\(parts[parts.count - 1])"
    }

    private static let workspaceFolders: Set<String> = ["apps", "packages", "examples", "services"]

    var shortPath: String {
        let parts = (cwd as NSString).pathComponents.filter { $0 != "/" }
        return parts.suffix(3).joined(separator: "/")
    }

    var age: String { Session.age(since: startedAt) }

    var memory: String {
        ByteCountFormatter.string(fromByteCount: Int64(footprint), countStyle: .memory)
    }

    var portList: String { ports.map { ":\($0)" }.joined(separator: " ") }

    var url: URL? { ports.first.flatMap { URL(string: "http://localhost:\($0)") } }
}
