import Darwin
import Foundation

/// The one place the app sends a signal. It stops dev servers and nothing else: a
/// Claude session, a shell or an app is never a target.
enum ServerStopper {

    /// What starts a dev server and stays in front of it: `pnpm dev` runs a script that
    /// runs `next dev` that forks the server. Stopping only the process on the port can
    /// leave a launcher that starts it again, so the stop climbs through these.
    private static let launchers: Set<String> = [
        "node", "pnpm", "npm", "npx", "yarn", "bun", "deno", "tsx",
        "python", "python3", "uv", "ruby", "bundle",
    ]

    private static let graceSeconds = 3.0

    /// SIGTERM to the launcher chain and everything under it, then SIGKILL to whatever
    /// is still the same process three seconds later.
    static func stop(_ server: DevServer) {
        let table = ProcessTable.snapshot()
        guard let listener = table.entries[server.pid],
              abs(listener.startedAt.timeIntervalSince(server.startedAt)) < 1
        else { return }

        var root = listener
        while let parent = table.entries[root.parent], parent.pid > 1,
              launchers.contains(parent.command) {
            root = parent
        }

        let ownPid = getpid()
        let targets = ([root.pid] + table.descendants(of: root.pid))
            .compactMap { table.entries[$0] }
            .filter { $0.pid > 1 && $0.pid != ownPid }

        for target in targets { kill(target.pid, SIGTERM) }

        DispatchQueue.global().asyncAfter(deadline: .now() + graceSeconds) {
            let now = ProcessTable.snapshot()
            for target in targets {
                guard let still = now.entries[target.pid], still.startedAt == target.startedAt else { continue }
                kill(target.pid, SIGKILL)
            }
        }
    }
}
