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
    var servers = Fixture.servers
    @State private var flashID: String?
    @State private var flashText = ""
    @State private var showAllIdle: Bool
    @State private var folded: Bool

    init(store: SessionStore, usage: UsageStore, folded: Bool = false, showAllIdle: Bool = false,
         servers: ServerStore = Fixture.servers) {
        self.store = store
        self.usage = usage
        self.servers = servers
        _folded = State(initialValue: folded)
        _showAllIdle = State(initialValue: showAllIdle)
    }

    var body: some View {
        VStack(spacing: 0) {
            PanelTop(store: store, usage: usage, usageFolded: $folded) {
                PanelTop<EmptyView>.headerGlyph(PanelAppearance.stored.toggleIcon)
                PanelTop<EmptyView>.headerGlyph(.gear)
            }
            PanelBody(store: store, servers: servers, flashID: $flashID, flashText: $flashText,
                      showAllIdle: $showAllIdle)
        }
        .padding(Theme.Space.panelInset)
        .frame(width: Theme.panelWidth)
        .background(Theme.Palette.surface)
    }
}

/// Only the usage block, for the states that do not need the session list.
struct UsageSheet: View {
    @ObservedObject var usage: UsageStore
    @State var folded = false

    var body: some View {
        UsageSection(store: usage, folded: $folded)
            .frame(width: Theme.panelWidth)
            .background(Theme.Palette.raised)
    }
}

enum Fixture {
    static let now = Date()

    static func server(_ pid: Int32, _ ports: [Int], _ path: String, days: Double, megabytes: UInt64) -> DevServer {
        DevServer(pid: pid, ports: ports, cwd: NSHomeDirectory() + "/dev/" + path,
                  startedAt: now.addingTimeInterval(-days * 24 * 3600), footprint: megabytes * 1_048_576)
    }

    static let servers = ServerStore(servers: [
        server(41365, [3000], "designhorf/designhorf-portfolio-2026", days: 5, megabytes: 1934),
        server(53467, [3003], "_agentic/ferilab-site", days: 14, megabytes: 646),
        server(43003, [4000], "_agentic/coss/apps/ui", days: 12, megabytes: 9906),
    ])

    static func usage(session: Int, weekly: Int, critical: Bool = false) -> Usage {
        Usage(
            session: .init(percent: session, resetsAt: now.addingTimeInterval(4 * 60), isCritical: critical),
            weekly: .init(percent: weekly, resetsAt: now.addingTimeInterval(3 * 24 * 3600), isCritical: false),
            claudeCodeShare: 96,
            fetchedAt: now
        )
    }
}

/// Every icon large and at its real size, so a path the parser got wrong is visible.
struct IconSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xl) {
            HStack(spacing: Theme.Space.xl) {
                ForEach(Array(Icon.allCases.enumerated()), id: \.offset) { _, icon in
                    IconView(icon: icon, size: 32, tint: Theme.Palette.textPrimary)
                }
            }
            HStack(spacing: Theme.Space.xl) {
                ForEach(Array(Icon.allCases.enumerated()), id: \.offset) { _, icon in
                    IconView(icon: icon, tint: Theme.Palette.textPrimary).frame(width: 32)
                }
            }
        }
        .padding(Theme.Space.xl)
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

    render(IconSheet(), to: "icons.png")

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

    render(RenderSheet(store: store, usage: UsageStore(usage: normal, phase: .idle), folded: true,
                       servers: ServerStore()),
           to: "panel-no-servers.png")

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
