import SwiftUI

/// The Servers section. Stop all asks twice, because it ends every server at once and
/// the panel gives no other warning.
struct ServerList: View {
    @ObservedObject var store: ServerStore
    @State private var confirmingStopAll = false

    private static let confirmWindow = 3.0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            SectionHeader(
                title: "Servers",
                count: store.servers.count,
                actionTitle: store.servers.count > 1 ? (confirmingStopAll ? "Confirm stop all" : "Stop all") : nil,
                action: store.servers.count > 1 ? stopAllTapped : nil
            )
            if store.servers.isEmpty {
                BubbleRow(
                    bubble: IconBubble(symbol: "server.rack"),
                    title: "No servers running",
                    subtitle: "Dev servers started from a project show here."
                )
                .softCard()
            } else {
                ForEach(store.servers) { server in
                    ServerCard(server: server, isStopping: store.stopping.contains(server.pid)) {
                        store.stop(server)
                    }
                }
            }
        }
    }

    private func stopAllTapped() {
        guard confirmingStopAll else {
            confirmingStopAll = true
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.confirmWindow) { confirmingStopAll = false }
            return
        }
        confirmingStopAll = false
        store.stopAll()
    }
}
