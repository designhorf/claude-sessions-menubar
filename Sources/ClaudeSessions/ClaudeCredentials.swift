import Foundation
import Security

/// The sign-in Claude Code keeps in the login keychain. Read only: the token is never
/// refreshed here, because refreshing rotates it underneath Claude Code and can sign
/// Claude Code out.
enum ClaudeCredentials {

    private static let service = "Claude Code-credentials"

    /// Nil when there is no sign-in, the item cannot be read, or the token has expired.
    static func accessToken(now: Date = Date()) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = root["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String
        else { return nil }

        if let expiresMs = oauth["expiresAt"] as? Double,
           Date(timeIntervalSince1970: expiresMs / 1000) <= now {
            return nil
        }
        return token
    }
}
