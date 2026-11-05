import Foundation

/// The sign-in Claude Code keeps in the login keychain. Read only: the token is never
/// refreshed here, because refreshing rotates it underneath Claude Code and can sign
/// Claude Code out.
enum ClaudeCredentials {

    private static let service = "Claude Code-credentials"

    /// Read through `/usr/bin/security`, not `SecItemCopyMatching`. Claude Code writes the
    /// item with that tool, so it is on the item's access list and reads without a
    /// prompt. The app itself is ad-hoc signed: every rebuild is a new app to the
    /// keychain, and "Always Allow" did not survive it.
    private static let securityTool = URL(fileURLWithPath: "/usr/bin/security")

    /// Held until it expires, so the keychain is read once per token, not once per fetch.
    private static var cached: (token: String, expires: Date?)?
    private static let lock = NSLock()

    /// Nil when there is no sign-in, the item cannot be read, or the token has expired.
    static func accessToken(now: Date = Date()) -> String? {
        lock.lock()
        defer { lock.unlock() }

        if let cached, !isExpired(cached.expires, now: now) { return cached.token }
        cached = nil

        guard let data = readItem(),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = root["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String
        else { return nil }

        let expires = (oauth["expiresAt"] as? Double).map { Date(timeIntervalSince1970: $0 / 1000) }
        if isExpired(expires, now: now) { return nil }
        cached = (token, expires)
        return token
    }

    /// Called when the server rejects the token: Claude Code may have rotated it early.
    static func forget() {
        lock.lock()
        cached = nil
        lock.unlock()
    }

    private static func isExpired(_ expires: Date?, now: Date) -> Bool {
        guard let expires else { return false }
        return expires <= now
    }

    private static func readItem() -> Data? {
        let process = Process()
        process.executableURL = securityTool
        process.arguments = ["find-generic-password", "-s", service, "-w"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return nil }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let text = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : Data(text.utf8)
    }
}
