import AppKit
import Foundation

/// Brings the terminal tab that hosts a session to the front.
///
/// Ghostty's AppleScript dictionary exposes a terminal's name and working directory
/// but neither its pid nor its tty, so a session is matched to a tab by its title.
/// Claude Code writes its own title into the tab, prefixed with a status glyph.
enum TerminalJump {

    enum Outcome {
        case jumped
        case noMatchingTab
        case terminalNotRunning
    }

    private static let ghosttyBundleID = "com.mitchellh.ghostty"

    static func jump(to session: Session) -> Outcome {
        guard isGhosttyRunning else { return .terminalNotRunning }
        guard let title = session.title else { return .noMatchingTab }

        let tabs = listTabs()
        guard let match = tabs.first(where: { $0.matches(cwd: session.cwd, title: title) })
                ?? tabs.first(where: { $0.looselyMatches(cwd: session.cwd, title: title) })
        else { return .noMatchingTab }

        return select(match) ? .jumped : .noMatchingTab
    }

    private static var isGhosttyRunning: Bool {
        !NSRunningApplication
            .runningApplications(withBundleIdentifier: ghosttyBundleID)
            .isEmpty
    }

    // MARK: - Reading the tabs

    struct Tab {
        let windowID: String
        let index: Int
        let name: String
        let cwd: String

        /// The tab name is the session title behind a status glyph, so the comparison
        /// runs on the tail of the name.
        func matches(cwd: String, title: String) -> Bool {
            self.cwd == cwd && name.hasSuffix(title)
        }

        /// A long title can come back shortened, so the fallback settles for a prefix
        /// long enough to be unlikely to collide.
        func looselyMatches(cwd: String, title: String) -> Bool {
            guard self.cwd == cwd, title.count > 24 else { return false }
            return name.contains(title.prefix(24))
        }
    }

    /// The separator is bound outside the `tell` block on purpose: inside it, `tab`
    /// resolves to Ghostty's tab class rather than to the character.
    private static let listScript = """
    on run argv
      set sep to (ASCII character 9)
      set out to ""
      tell application "Ghostty"
        repeat with w in windows
          repeat with t in tabs of w
            repeat with term in terminals of t
              set out to out & (id of w) & sep & (index of t) & sep & ¬
                (working directory of term) & sep & (name of term) & linefeed
            end repeat
          end repeat
        end repeat
      end tell
      return out
    end run
    """

    private static func listTabs() -> [Tab] {
        guard let output = runOsascript(listScript) else { return [] }
        return output.split(separator: "\n").compactMap { line in
            let parts = line.components(separatedBy: "\t")
            guard parts.count >= 4, let index = Int(parts[1]) else { return nil }
            return Tab(windowID: parts[0],
                       index: index,
                       name: parts[3...].joined(separator: "\t"),
                       cwd: parts[2])
        }
    }

    // MARK: - Selecting one

    private static let selectScript = """
    on run argv
      set targetWindow to item 1 of argv
      set targetIndex to (item 2 of argv) as integer
      tell application "Ghostty"
        repeat with w in windows
          if (id of w) is targetWindow then
            repeat with t in tabs of w
              if (index of t) is targetIndex then
                select tab t
                activate window w
                activate
                return "ok"
              end if
            end repeat
          end if
        end repeat
      end tell
      return "missing"
    end run
    """

    private static func select(_ tab: Tab) -> Bool {
        runOsascript(selectScript, arguments: [tab.windowID, String(tab.index)])?
            .trimmingCharacters(in: .whitespacesAndNewlines) == "ok"
    }

    // MARK: - Running it

    /// Values reach the script as arguments rather than as interpolated text, so a
    /// title containing a quote cannot break or alter the script.
    private static func runOsascript(_ script: String, arguments: [String] = []) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script] + arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        guard (try? task.run()) != nil else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
