import AppKit
import SwiftUI

// Renders the panel to PNGs so the layout can be inspected without photographing the
// menu bar. ImageRenderer draws neither ScrollView content nor a Menu, so the header is
// stood in for here and PanelBody is rendered for real. Sessions are the live ones;
// usage comes from fixtures, so no state needs the network.
let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

struct RenderSheet: View {
    @ObservedObject var store: SessionStore
    @ObservedObject var usage: UsageStore
    @State private var flashID: String?
    @State private var flashText = ""
    @State private var showAllIdle: Bool
    @State private var folded: Bool

    init(store: SessionStore, usage: UsageStore, folded: Bool = false, showAllIdle: Bool = false) {
        self.store = store
        self.usage = usage
        _folded = State(initialValue: folded)
        _showAllIdle = State(initialValue: showAllIdle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            HStack {
                Text("Claude Sessions")
                    .font(Theme.Typography.panelName)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
                RoundGlyph(symbol: PanelAppearance.stored.toggleSymbol, diameter: Theme.Size.settingsButton,
                           glyphSize: Theme.IconSize.settings)
                RoundGlyph(symbol: "gearshape", diameter: Theme.Size.settingsButton,
                           glyphSize: Theme.IconSize.settings)
            }
            .padding(.horizontal, Theme.Space.xs)
            PanelBody(store: store, usage: usage, usageFolded: $folded, flashID: $flashID,
                      flashText: $flashText, showAllIdle: $showAllIdle)
        }
        .padding(Theme.Space.panel)
        .frame(width: Theme.panelWidth)
        .background(Theme.Palette.surface)
    }
}

/// Only the usage cards, for the states that do not need the session list.
struct UsageSheet: View {
    @ObservedObject var usage: UsageStore
    @State var folded = false

    var body: some View {
        UsageSection(store: usage, folded: $folded)
            .padding(Theme.Space.panel)
            .frame(width: Theme.panelWidth)
            .background(Theme.Palette.surface)
    }
}

enum Fixture {
    static let now = Date()

    static func usage(session: Int, weekly: Int, critical: Bool = false) -> Usage {
        Usage(
            session: .init(percent: session, resetsAt: now.addingTimeInterval(4 * 60), isCritical: critical),
            weekly: .init(percent: weekly, resetsAt: now.addingTimeInterval(3 * 24 * 3600), isCritical: false),
            claudeCodeShare: 96,
            fetchedAt: now
        )
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

    let normal = Fixture.usage(session: 15, weekly: 16)
    let critical = Fixture.usage(session: 94, weekly: 78, critical: true)
    render(RenderSheet(store: store, usage: UsageStore(usage: normal, phase: .idle)),
           to: "panel-open.png")
    render(RenderSheet(store: store, usage: UsageStore(usage: normal, phase: .idle), folded: true),
           to: "panel-folded.png")
    for (name, usage, phase) in [
        ("updating", normal, UsageStore.Phase.updating),
        ("critical", critical, .idle),
        ("failed", normal, .failed(.offline)),
    ] {
        render(UsageSheet(usage: UsageStore(usage: usage, phase: phase)), to: "usage-\(name)-open.png")
        render(UsageSheet(usage: UsageStore(usage: usage, phase: phase), folded: true), to: "usage-\(name)-folded.png")
    }

    PanelAppearance.dark.apply()
    render(RenderSheet(store: store, usage: UsageStore(usage: normal, phase: .idle))
               .environment(\.colorScheme, .dark),
           to: "panel-open-dark.png")
    render(RenderSheet(store: store, usage: UsageStore(usage: critical, phase: .idle), folded: true)
               .environment(\.colorScheme, .dark),
           to: "panel-folded-dark.png")
    exit(0)
}

RunLoop.main.run()
