import Foundation

/// Local dev servers, scanned only while the panel is open: the menu bar title does not
/// show them, so there is nothing to keep current while nobody is looking.
final class ServerStore: ObservableObject {
    @Published private(set) var servers: [DevServer] = []
    /// Servers that were told to stop and have not gone yet.
    @Published private(set) var stopping: Set<Int32> = []

    private var timer: Timer?
    private let queue = DispatchQueue(label: "hu.designhorf.claudesessions.servers")

    init(servers: [DevServer] = []) {
        self.servers = servers
    }

    func startWatching() {
        refresh()
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopWatching() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        queue.async { [weak self] in
            let scanned = ServerScanner.scan()
            DispatchQueue.main.async {
                guard let self else { return }
                let live = Set(scanned.map(\.pid))
                self.stopping.formIntersection(live)
                if scanned != self.servers { self.servers = scanned }
            }
        }
    }

    func stop(_ server: DevServer) {
        stopping.insert(server.pid)
        queue.async { ServerStopper.stop(server) }
        // Once for the servers that exit at once, once after the grace period.
        for delay in [1.0, 4.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in self?.refresh() }
        }
    }

    func stopAll() {
        servers.filter { !stopping.contains($0.pid) }.forEach(stop)
    }
}
