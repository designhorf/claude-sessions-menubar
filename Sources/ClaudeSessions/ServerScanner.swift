import Darwin
import Foundation

/// Finds the local servers started from a project folder. Reads only.
enum ServerScanner {

    private static let home = FileManager.default.homeDirectoryForCurrentUser.path

    static func scan() -> [DevServer] {
        let table = ProcessTable.snapshot()
        var servers: [DevServer] = []
        for (pid, ports) in listeningPorts() {
            // Apps listen too (Figma, Adobe, Control Center), and so do system daemons.
            // What separates a dev server is that it runs from inside a folder the user
            // owns and is not part of an app bundle.
            guard let cwd = workingDirectory(of: pid), cwd.hasPrefix(home + "/"),
                  let executable = executablePath(of: pid), !executable.contains(".app/"),
                  let entry = table.entries[pid]
            else { continue }

            let tree = [pid] + table.descendants(of: pid)
            servers.append(DevServer(
                pid: pid,
                ports: ports,
                cwd: cwd,
                startedAt: entry.startedAt,
                footprint: tree.reduce(0) { $0 + footprint(of: $1) }
            ))
        }
        return servers.sorted { ($0.ports.first ?? 0) < ($1.ports.first ?? 0) }
    }

    // MARK: - Listening ports

    /// The kernel keeps socket state per file descriptor and walking every descriptor
    /// of every process from here would mean re-implementing lsof, so lsof is asked.
    /// It answers in a few tens of milliseconds and only runs while the panel is open.
    private static func listeningPorts() -> [Int32: [Int]] {
        let lsof = Process()
        lsof.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        lsof.arguments = ["-nP", "-iTCP", "-sTCP:LISTEN", "-Fpn"]
        let pipe = Pipe()
        lsof.standardOutput = pipe
        lsof.standardError = FileHandle.nullDevice
        guard (try? lsof.run()) != nil else { return [:] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        lsof.waitUntilExit()

        // -F output is one field per line: `p<pid>` opens a process, `n<addr>:<port>`
        // follows for each listening socket. IPv4 and IPv6 sockets repeat the port.
        var ports: [Int32: [Int]] = [:]
        var current: Int32?
        for line in String(decoding: data, as: UTF8.self).split(separator: "\n") {
            guard let tag = line.first else { continue }
            let value = line.dropFirst()
            if tag == "p" {
                current = Int32(value)
            } else if tag == "n", let pid = current,
                      let colon = value.lastIndex(of: ":"),
                      let port = Int(value[value.index(after: colon)...]),
                      !(ports[pid]?.contains(port) ?? false) {
                ports[pid, default: []].append(port)
            }
        }
        return ports.mapValues { $0.sorted() }
    }

    // MARK: - Per process

    private static func workingDirectory(of pid: Int32) -> String? {
        var info = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &info, size) == size else { return nil }
        return withUnsafeBytes(of: &info.pvi_cdir.vip_path) {
            String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    private static func executablePath(of pid: Int32) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return String(cString: buffer)
    }

    private static func footprint(of pid: Int32) -> UInt64 {
        var usage = rusage_info_v2()
        let result = withUnsafeMutablePointer(to: &usage) {
            $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_V2, $0)
            }
        }
        return result == 0 ? usage.ri_phys_footprint : 0
    }
}
