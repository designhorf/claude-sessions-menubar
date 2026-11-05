# Claude Sessions

A macOS menu bar app that lists the Claude Code sessions running right now, with the
plan usage `/usage` reports.

## Layers

Values live in `Sources/ClaudeSessions/Theme.swift`. Mechanics live in components.
Anything a machine can see lives in `scripts/check.sh`. Only judgment belongs here.

Run `./scripts/check.sh` before every commit.

## Rules

**The app only reads.** It never writes under `~/.claude`, never deletes a stale
record, and never writes to the keychain. A record it does not understand is skipped,
not repaired.

**The one thing it does to another process is stop a dev server.** The power button on a
server card, or Stop all, sends SIGTERM to the server, the launchers in front of it
(`pnpm`, `node`, `bun` and the like) and everything under them, then SIGKILL to whatever is
still the same process three seconds later. A Claude session, a shell or an app is never
a target. Signals live in `ServerStopper.swift` alone. Stop all asks twice.

**Servers are scanned only while the panel is open.** A server is a process listening on
a local TCP port whose working directory is under the home folder and whose executable is
not inside an app bundle. The menu bar title does not show servers, so nothing scans
while the panel is closed.

**One network call, and only while Claude works.** Usage is fetched with a single GET
when the panel opens, when Refresh is pressed, and every five minutes while at least one
session is working, so the menu bar title stays current. While every session is idle
nothing is fetched. The token is Claude Code's: it is read
from the keychain through `/usr/bin/security` (on the item's access list, so no
prompt), held until it expires, and never refreshed, because refreshing rotates it underneath Claude
Code. An expired token shows the cached numbers and asks for Claude Code instead.

**The data decides red.** A limit turns red only when its severity says critical. The
app does not invent a threshold.

**Running is green, and only running is green.** The section header names the state
and the bubble repeats it as a glyph: green play while Claude runs, grey stop while it
waits. No other element uses green.

**The subject leads a card.** Metadata is quieter than the thing it describes. A title
stays on one line; the full title is in the tooltip.

**One click does one thing.** The card body opens the terminal tab; the chevron opens
the context line. Nothing does both.

**Check the layout by rendering it.** `Tools/main.swift` draws the panel to a PNG.
Reasoning about SwiftUI from the source is how wrong layouts get shipped.

**Scripts take arguments, never interpolated text.** A session title containing a
quote must not be able to alter an AppleScript.

**A second copy becomes a component.** The disclosure chevron existed twice, in two
different rotations, before it became `DisclosureChevron`.

**Light by default, dark on request.** The toggle next to the gear switches the panel
and remembers the choice; the system setting is not followed. Every colour in
`Theme.Palette` carries both values, so a view never branches on the mode.

**English everywhere.** Source, comments, docs, commits, UI strings.

**Comments record constraints, not the code.** A comment that restates the identifier
it sits on gets deleted. A comment explaining why `tab` cannot be used as a separator
inside a Ghostty `tell` block stays.

## Terminal support

Ghostty only. Its AppleScript dictionary exposes a terminal's name and working
directory but neither its pid nor its tty, so a session is matched to a tab by title.
Any other terminal falls back to copying the resume command. Adding a terminal means
adding a matcher, not changing the card.
