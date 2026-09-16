import Foundation

/// Usage for the panel. Fetched when the panel opens and when Refresh is pressed; there
/// is no timer.
@MainActor
final class UsageStore: ObservableObject {

    enum Phase: Equatable {
        case idle
        case updating
        case failed(UsageClient.Failure)
    }

    @Published private(set) var usage: Usage?
    @Published private(set) var phase: Phase

    /// Opening the panel can be reported by more than one signal. Automatic refreshes
    /// inside this window are the same click; a pressed button always goes through.
    private static let automaticInterval: TimeInterval = 10
    private var lastStarted: Date?

    init() {
        usage = UsageCache.load()
        phase = .idle
    }

    /// For the render harness, which draws fixed states without touching disk or network.
    init(usage: Usage?, phase: Phase) {
        self.usage = usage
        self.phase = phase
    }

    var isStale: Bool { phase != .idle }

    var failure: UsageClient.Failure? {
        if case .failed(let failure) = phase { return failure }
        return nil
    }

    func refresh(manual: Bool = false) {
        guard phase != .updating else { return }
        if !manual, let lastStarted,
           Date().timeIntervalSince(lastStarted) < Self.automaticInterval {
            return
        }
        lastStarted = Date()
        phase = .updating

        Task {
            do {
                usage = try await UsageClient.fetch()
                phase = .idle
            } catch let failure as UsageClient.Failure {
                phase = .failed(failure)
            } catch {
                phase = .failed(.unreadable)
            }
        }
    }
}
