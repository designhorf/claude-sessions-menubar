import Foundation

/// The one network call the app makes: a GET to the endpoint `/usage` reads. It is not
/// a documented API, so every way it can fail maps to a reason the panel can show
/// instead of an error it cannot.
enum UsageClient {

    enum Failure: Error, Equatable {
        case signedOut
        case offline
        case rejected(status: Int)
        case unreadable

        var reason: String {
            switch self {
            case .signedOut: return "Open Claude Code to sign in again."
            case .offline: return "Offline."
            case .rejected(let status): return "Could not update (HTTP \(status))."
            case .unreadable: return "Could not read the usage."
            }
        }

        /// Fits the card header; the full reason is the tooltip.
        var short: String {
            switch self {
            case .signedOut: return "Signed out"
            case .offline: return "Offline"
            case .rejected(let status): return "HTTP \(status)"
            case .unreadable: return "Unreadable"
            }
        }
    }

    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private static let betaHeader = "oauth-2025-04-20"
    private static let timeout: TimeInterval = 10

    /// Ephemeral, so neither the token nor the response lands in a URL cache on disk.
    private static let session = URLSession(configuration: .ephemeral)

    static func fetch() async throws -> Usage {
        guard let token = ClaudeCredentials.accessToken() else { throw Failure.signedOut }

        var request = URLRequest(url: endpoint, timeoutInterval: timeout)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(betaHeader, forHTTPHeaderField: "anthropic-beta")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw Failure.offline
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 || status == 403 { throw Failure.signedOut }
        guard (200..<300).contains(status) else { throw Failure.rejected(status: status) }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let usage = Usage(utilization: json, fetchedAt: Date())
        else { throw Failure.unreadable }
        return usage
    }
}
