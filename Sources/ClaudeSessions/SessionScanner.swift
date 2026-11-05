import Darwin
import Foundation

/// Reads the session state Claude Code already writes to disk. Never writes.
enum SessionScanner {

    private static let home = FileManager.default.homeDirectoryForCurrentUser
    private static var sessionsDir: URL { home.appending(path: ".claude/sessions") }
    private static var projectsDir: URL { home.appending(path: ".claude/projects") }

    /// Transcript paths keyed by sessionId. Rebuilt only when a session is missing.
    private static var transcriptPaths: [String: URL] = [:]

    /// What a transcript says about itself, keyed by path and invalidated on size or
    /// mtime change.
    struct Details: Equatable {
        var title: String?
        var opening: String?
    }
    private static var detailCache: [String: (stamp: String, details: Details)] = [:]

    // MARK: - Entry point

    static func scan() -> [Session] {
        let running = ProcessTable.snapshot().starts
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: sessionsDir, includingPropertiesForKeys: nil
        ) else { return [] }

        var sessions: [Session] = []
        for file in files where file.pathExtension == "json" {
            guard let record = try? Data(contentsOf: file),
                  let json = try? JSONSerialization.jsonObject(with: record) as? [String: Any],
                  let pid = json["pid"] as? Int,
                  let id = json["sessionId"] as? String,
                  let cwd = json["cwd"] as? String,
                  let startedMs = json["startedAt"] as? Double
            else { continue }

            // A record only counts as live if the pid is still up AND it started when
            // the record says it did, so a recycled pid cannot resurrect a dead session.
            guard let processStart = running[Int32(pid)],
                  abs(processStart.timeIntervalSince1970 - startedMs / 1000) < 60
            else { continue }
            let details = details(for: id)
            let activityMs = (json["statusUpdatedAt"] as? Double) ?? (json["updatedAt"] as? Double)
            sessions.append(Session(
                id: id,
                pid: Int32(pid),
                name: json["name"] as? String ?? (cwd as NSString).lastPathComponent,
                cwd: cwd,
                startedAt: Date(timeIntervalSince1970: startedMs / 1000),
                isBusy: (json["status"] as? String) == "busy",
                title: details.title,
                opening: details.opening,
                lastActivity: activityMs.map { Date(timeIntervalSince1970: $0 / 1000) }
            ))
        }

        // One session per id: the same session can leave more than one pid record.
        var seen = Set<String>()
        return sessions
            .sorted { $0.startedAt > $1.startedAt }
            .filter { seen.insert($0.id).inserted }
    }

    // MARK: - What a transcript says about itself

    private static func details(for id: String) -> Details {
        guard let path = transcriptPath(for: id) else { return Details() }

        let attributes = try? FileManager.default.attributesOfItem(atPath: path.path)
        let size = (attributes?[.size] as? Int) ?? 0
        let modified = (attributes?[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        let stamp = "\(size)-\(modified)"

        if let cached = detailCache[path.path], cached.stamp == stamp { return cached.details }
        let details = Details(title: readTitle(from: path, size: size),
                              opening: readOpening(from: path))
        detailCache[path.path] = (stamp, details)
        return details
    }

    /// Claude Code appends an `ai-title` record and rewrites it as the conversation
    /// moves on, so the last one in the file is the current subject. Reading the tail
    /// keeps a multi-megabyte transcript from being parsed on every refresh.
    private static func readTitle(from path: URL, size: Int) -> String? {
        let tailBytes = 262_144
        guard let handle = try? FileHandle(forReadingFrom: path) else { return nil }
        defer { try? handle.close() }

        let seeking = size > tailBytes
        if seeking { try? handle.seek(toOffset: UInt64(size - tailBytes)) }
        guard let data = try? handle.readToEnd() else { return nil }

        // A seek lands mid record, so the first partial line is dropped here rather
        // than by scanning the file a byte at a time.
        var tail = data
        if seeking, let newline = tail.firstIndex(of: 0x0A) {
            tail = tail[tail.index(after: newline)...]
        }
        guard let text = String(data: tail, encoding: .utf8) else { return nil }

        var aiTitle: String?
        var summary: String?
        for line in text.split(separator: "\n") {
            if line.contains("\"ai-title\"") {
                if let value = field("aiTitle", in: line) { aiTitle = value }
            } else if line.contains("\"type\":\"summary\"") {
                if let value = field("summary", in: line) { summary = value }
            }
        }
        return aiTitle ?? summary
    }

    /// The message that opened the session, which is the closest thing on disk to a
    /// description of what the session is actually for.
    private static func readOpening(from path: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: path) else { return nil }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 131_072),
              let text = String(data: data, encoding: .utf8)
        else { return nil }

        for line in text.split(separator: "\n") {
            guard line.contains("\"type\":\"user\""),
                  let json = try? JSONSerialization.jsonObject(
                      with: Data(line.utf8)) as? [String: Any],
                  let message = json["message"] as? [String: Any]
            else { continue }

            var body = ""
            if let content = message["content"] as? String {
                body = content
            } else if let blocks = message["content"] as? [[String: Any]] {
                body = blocks.compactMap { $0["text"] as? String }.joined(separator: " ")
            }

            // Injected context and command wrappers arrive as user messages too, and
            // none of them describe what the session is for.
            body = body.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !body.isEmpty, !body.hasPrefix("<") else { continue }
            body = body.replacingOccurrences(of: "\n", with: " ")
            body = withoutURLs(body)
            return body.count > 220 ? String(body.prefix(220)) + "…" : body
        }
        return nil
    }

    /// A pasted link fills both lines of the summary and says nothing, so the words
    /// around it get the room instead.
    private static func withoutURLs(_ text: String) -> String {
        let stripped = text
            .split(separator: " ")
            .filter { !$0.hasPrefix("http://") && !$0.hasPrefix("https://") }
            .joined(separator: " ")
        return stripped.trimmingCharacters(in: .whitespaces)
    }

    private static func field(_ key: String, in line: Substring) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
        else { return nil }
        return json[key] as? String
    }

    // MARK: - Locating a transcript

    private static func transcriptPath(for id: String) -> URL? {
        if let cached = transcriptPaths[id], FileManager.default.fileExists(atPath: cached.path) {
            return cached
        }
        rebuildTranscriptIndex()
        return transcriptPaths[id]
    }

    /// The project folder name is a slug of the working directory, and the slug rules
    /// are not ours to guess, so the index is built by listing the folders instead.
    private static func rebuildTranscriptIndex() {
        guard let projects = try? FileManager.default.contentsOfDirectory(
            at: projectsDir, includingPropertiesForKeys: nil
        ) else { return }

        var index: [String: URL] = [:]
        for project in projects {
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: project, includingPropertiesForKeys: nil
            ) else { continue }
            for file in files where file.pathExtension == "jsonl" {
                index[file.deletingPathExtension().lastPathComponent] = file
            }
        }
        transcriptPaths = index
    }
}
