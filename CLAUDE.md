# Claude Sessions

A macOS menu bar app that lists the Claude Code sessions running right now.

## Layers

Values live in `Sources/ClaudeSessions/Theme.swift`. Mechanics live in components.
Anything a machine can see lives in `scripts/check.sh`. Only judgment belongs here.

Run `./scripts/check.sh` before every commit.

## Rules

**The app only reads.** It never writes under `~/.claude`, never opens a network
connection, and never deletes a stale record. A record it does not understand is
skipped, not repaired.

**Name a state once.** If a section header states it, the cards inside it do not
repeat it.

**The subject leads a card.** Metadata is quieter than the thing it describes.

**One click does one thing.** The card body opens the terminal tab; the chevron opens
the context line. Nothing does both.

**Check the layout by rendering it.** `Tools/main.swift` draws the panel to a PNG.
Reasoning about SwiftUI from the source is how wrong layouts get shipped.

**Scripts take arguments, never interpolated text.** A session title containing a
quote must not be able to alter an AppleScript.

**A second copy becomes a component.** The disclosure chevron existed twice, in two
different rotations, before it became `DisclosureChevron`.

**Light only.** No dark palette, no appearance toggle, no `prefers-color-scheme`.

**English everywhere.** Source, comments, docs, commits, UI strings.

**Comments record constraints, not the code.** A comment that restates the identifier
it sits on gets deleted. A comment explaining why `tab` cannot be used as a separator
inside a Ghostty `tell` block stays.

## Terminal support

Ghostty only. Its AppleScript dictionary exposes a terminal's name and working
directory but neither its pid nor its tty, so a session is matched to a tab by title.
Any other terminal falls back to copying the resume command. Adding a terminal means
adding a matcher, not changing the card.
