import Darwin
import Foundation

/// Every process on the machine at one moment, straight from the kernel. Cheaper than
/// spawning `ps`, and the start time doubles as an identity check, so a recycled pid
/// is never mistaken for the process that used to hold it.
struct ProcessTable {
    struct Entry {
        let pid: Int32
        let parent: Int32
        /// The executable name the kernel keeps, at most sixteen characters.
        let command: String
        let startedAt: Date
    }

    let entries: [Int32: Entry]

    static func snapshot() -> ProcessTable {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0, size > 0 else { return ProcessTable(entries: [:]) }

        var raw = [kinfo_proc](repeating: kinfo_proc(), count: size / MemoryLayout<kinfo_proc>.stride)
        guard sysctl(&mib, 4, &raw, &size, nil, 0) == 0 else { return ProcessTable(entries: [:]) }

        var entries: [Int32: Entry] = [:]
        for proc in raw[0 ..< (size / MemoryLayout<kinfo_proc>.stride)] {
            let started = proc.kp_proc.p_un.__p_starttime
            var name = proc.kp_proc.p_comm
            let command = withUnsafeBytes(of: &name) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
            entries[proc.kp_proc.p_pid] = Entry(
                pid: proc.kp_proc.p_pid,
                parent: proc.kp_eproc.e_ppid,
                command: command,
                startedAt: Date(timeIntervalSince1970: Double(started.tv_sec) + Double(started.tv_usec) / 1_000_000)
            )
        }
        return ProcessTable(entries: entries)
    }

    var starts: [Int32: Date] { entries.mapValues(\.startedAt) }

    /// Every process below `pid`, children before grandchildren.
    func descendants(of pid: Int32) -> [Int32] {
        var children: [Int32: [Int32]] = [:]
        for entry in entries.values { children[entry.parent, default: []].append(entry.pid) }

        var found: [Int32] = []
        var queue = children[pid] ?? []
        while let next = queue.first {
            queue.removeFirst()
            found.append(next)
            queue.append(contentsOf: children[next] ?? [])
        }
        return found
    }
}
