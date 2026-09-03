import AppKit
import SwiftUI

// Renders the panel body to a PNG so the layout can be inspected without
// photographing the menu bar. ImageRenderer draws neither ScrollView content nor a
// Menu, so the chrome is stood in for here and only the list is rendered for real.
let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

struct RenderSheet: View {
    @ObservedObject var store: SessionStore
    @State private var flashID: String?
    @State private var flashText = ""
    @State private var showIdle: Bool

    let crop: CGFloat

    init(store: SessionStore, expandIdle: Bool, crop: CGFloat = .infinity) {
        self.store = store
        self.crop = crop
        _showIdle = State(initialValue: expandIdle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Theme.Space.lg) {
                Text("Claude Sessions")
                    .font(Theme.Typography.panelName)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            .padding(.horizontal, Theme.Space.sm)
            .padding(.bottom, Theme.Space.lg)

            SessionList(store: store, flashID: $flashID, flashText: $flashText, showIdle: $showIdle)
                .frame(maxHeight: crop, alignment: .top)
                .clipped()
        }
        .padding(Theme.Space.xl)
        .frame(width: Theme.panelWidth)
        .background(Theme.Palette.surface)
    }
}

/// One card with its context line open, which the list never shows by default.
struct CardSheet: View {
    let session: Session
    @State private var flashID: String?
    @State private var flashText = ""

    var body: some View {
        SessionCard(session: session, flashID: $flashID, flashText: $flashText, expanded: true)
            .padding(Theme.Space.xl)
            .frame(width: Theme.panelWidth)
            .background(Theme.Palette.surface)
    }
}

@MainActor
func render<V: View>(_ view: V, to name: String) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    guard let image = renderer.nsImage,
          let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:])
    else { print("render failed: \(name)"); return }
    try? png.write(to: URL(fileURLWithPath: outputDirectory).appendingPathComponent(name))
    print("wrote \(name)  \(Int(image.size.width))x\(Int(image.size.height))pt")
}

let store = SessionStore()

Task { @MainActor in
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    print("sessions: \(store.sessions.count)  busy: \(store.busy.count)")
    render(RenderSheet(store: store, expandIdle: false), to: "panel-collapsed.png")
    render(RenderSheet(store: store, expandIdle: true, crop: 620), to: "panel-expanded.png")
    if let first = store.sessions.first {
        render(
            CardSheet(session: first),
            to: "card-open.png"
        )
    }
    exit(0)
}

RunLoop.main.run()
