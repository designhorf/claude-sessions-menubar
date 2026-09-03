import Foundation
import ServiceManagement

final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [Session] = []

    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != (SMAppService.mainApp.status == .enabled) else { return }
            do {
                launchAtLogin ? try SMAppService.mainApp.register()
                              : try SMAppService.mainApp.unregister()
            } catch {
                NSLog("launch at login failed: \(error.localizedDescription)")
                launchAtLogin = !launchAtLogin
            }
        }
    }

    var busy: [Session] { sessions.filter(\.isBusy) }
    var idle: [Session] { sessions.filter { !$0.isBusy } }

    private var timer: Timer?
    private let queue = DispatchQueue(label: "hu.designhorf.claudesessions.scan")

    init() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    /// Scanning touches the file system, so it stays off the main thread even though
    /// a full pass measures in tens of milliseconds.
    func refresh() {
        queue.async { [weak self] in
            let scanned = SessionScanner.scan()
            DispatchQueue.main.async {
                guard let self, scanned != self.sessions else { return }
                self.sessions = scanned
            }
        }
    }
}
