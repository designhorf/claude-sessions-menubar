import SwiftUI

/// A session as a card. The card body jumps to the terminal tab; the chevron is the
/// only thing that opens the context line, so a click never does two things at once.
struct SessionCard: View {
    let session: Session
    @Binding var flashID: String?
    @Binding var flashText: String
    @State private var expanded: Bool
    @State private var hovering = false

    init(session: Session,
         flashID: Binding<String?>,
         flashText: Binding<String>,
         expanded: Bool = false) {
        self.session = session
        _flashID = flashID
        _flashText = flashText
        _expanded = State(initialValue: expanded)
    }

    private var isFlashing: Bool { flashID == session.id }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack(alignment: .top, spacing: Theme.Space.lg) {
                Text(session.subject)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Theme.Space.sm)
                if session.opening != nil { disclosure }
            }

            if expanded, let opening = session.opening {
                Text(opening)
                    .font(Theme.Typography.meta)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: Theme.Space.lg) {
                Pill(label: session.projectName,
                     dot: Theme.projectColor(for: session.projectName))
                Spacer(minLength: Theme.Space.sm)
                Text(isFlashing ? flashText : session.age)
                    .font(Theme.Typography.meta)
                    .monospacedDigit()
                    .foregroundStyle(isFlashing ? Theme.Palette.accent : Theme.Palette.textTertiary)
            }
        }
        .padding(Theme.Space.xl - 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(hovering ? Theme.Palette.cardHover : Theme.Palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Theme.Palette.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture { open() }
        .help(tooltip)
        .contextMenu {
            Button("Copy resume command") { copyResumeCommand() }
        }
    }

    private var disclosure: some View {
        Button {
            withAnimation(.easeOut(duration: 0.12)) { expanded.toggle() }
        } label: {
            DisclosureChevron(expanded: expanded)
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(expanded ? "Hide what this session opened with"
                       : "Show what this session opened with")
    }

    private var tooltip: String {
        var lines = ["\(session.name) · \(session.shortPath)"]
        if let last = session.lastActivityAge { lines.append("last active \(last) ago") }
        lines.append("Click to open its terminal tab")
        return lines.joined(separator: "\n")
    }

    // MARK: - Actions

    /// Falling back to the clipboard keeps the click useful when the session is not a
    /// Ghostty tab, rather than doing nothing at all.
    private func open() {
        switch TerminalJump.jump(to: session) {
        case .jumped:
            flash("opened")
        case .noMatchingTab:
            copyResumeCommand()
            flash("tab not found · copied")
        case .terminalNotRunning:
            copyResumeCommand()
            flash("copied")
        }
    }

    private func copyResumeCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(session.resumeCommand, forType: .string)
    }

    private func flash(_ text: String) {
        flashText = text
        flashID = session.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if flashID == session.id { flashID = nil }
        }
    }
}
