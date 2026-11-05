import AppKit
import SwiftUI

/// A dev server as a row. The row body opens it in the browser; the power button is the
/// only thing that stops it.
struct ServerCard: View {
    let server: DevServer
    let isStopping: Bool
    let onStop: () -> Void

    var body: some View {
        ListRow(
            icon: .server,
            title: server.projectName,
            detail: "\(server.portList) · \(server.memory)",
            age: server.age,
            flash: isStopping ? "stopping…" : nil,
            action: open
        ) {
            Button(action: onStop) {
                GlyphControl(icon: .power, glyph: Theme.IconSize.row)
            }
            .buttonStyle(.plain)
            .help("Stop this server")
        }
        .opacity(isStopping ? Theme.Opacity.stopping : 1)
        .help(tooltip)
        .contextMenu {
            Button("Copy URL") { copyURL() }
            Button("Show folder in Finder") {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: server.cwd)
            }
        }
        .disabled(isStopping)
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
