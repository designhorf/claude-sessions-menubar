import AppKit
import SwiftUI

/// A dev server as a card. The card body opens it in the browser; the power button is
/// the only thing that stops it.
struct ServerCard: View {
    let server: DevServer
    let isStopping: Bool
    let onStop: () -> Void

    var body: some View {
        BubbleRow(
            bubble: IconBubble(symbol: "server.rack"),
            title: server.projectName,
            subtitle: isStopping ? "stopping…" : "\(server.portList) · \(server.age) · \(server.memory)"
        ) {
            stopButton
        }
        .softCard(hoverable: true)
        .opacity(isStopping ? Theme.Opacity.staleValue : 1)
        .onTapGesture { open() }
        .help(tooltip)
        .contextMenu {
            Button("Copy URL") { copyURL() }
            Button("Show folder in Finder") {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: server.cwd)
            }
        }
        .disabled(isStopping)
    }

    private var stopButton: some View {
        Button(action: onStop) {
            RoundGlyph(symbol: "power", diameter: Theme.Size.rowAction,
                       glyphSize: Theme.IconSize.rowAction, fill: Theme.Palette.bubble,
                       fillOnHover: true)
        }
        .buttonStyle(.plain)
        .help("Stop this server")
    }

    private var tooltip: String {
        [
            server.shortPath,
            "pid \(server.pid) · \(server.portList)",
            "Click to open in the browser",
        ].joined(separator: "\n")
    }

    private func open() {
        guard let url = server.url else { return }
        NSWorkspace.shared.open(url)
    }

    private func copyURL() {
        guard let url = server.url else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
    }
}
