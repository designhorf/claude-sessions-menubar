# Claude Sessions

A macOS menu bar app that lists the Claude Code sessions running right now: how
many, since when, and what each one is about.

## Build

```bash
./build-app.sh
open ClaudeSessions.app
```

Command Line Tools are enough, Xcode is not required. SwiftPM needs a full Xcode
install, and it would produce a bare executable rather than a bundle, so the script
drives `swiftc` directly and assembles the `.app` itself.

To keep it around, move `ClaudeSessions.app` to `/Applications` and turn on
"Open at login" in the panel.

## Rules

`CLAUDE.md` holds the rules that need judgment. `scripts/check.sh` holds the ones a
machine can see; run it before every commit.

## Design

Linear's visual language on a light palette: cards with a hairline border, a coloured
dot inside a pill for the project, board-style section headers that carry a state icon
and a count. Every colour, size and radius lives in `Theme.swift`; nothing downstream
hardcodes a value. A project keeps the same colour between launches, because the colour
is picked by hashing the folder name.

The panel is pinned to the light appearance and does not follow the system setting.

Card reading order is subject first, then the quieter project and age line. The state is
named once, by the section header, and never repeated on the cards inside it.

## Looking at the layout

`Tools/main.swift` renders the panel body to PNGs, which is how the layout gets checked
without photographing the menu bar:

```bash
swiftc -sdk "$(xcrun --sdk macosx --show-sdk-path)" -target arm64-apple-macos13.0 \
    $(ls Sources/ClaudeSessions/*.swift | grep -v ClaudeSessionsApp) Tools/main.swift -o /tmp/render
/tmp/render /tmp
```

`ImageRenderer` draws neither `ScrollView` content nor a `Menu`, so the harness stands in
for the panel chrome and renders the list for real.

## Where the data comes from

Read only. Nothing is written, no network call is made.

| What | Source |
| --- | --- |
| Which sessions run | `~/.claude/sessions/<pid>.json` |
| Started at, working directory, idle or busy | the same file |
| Subject | the last `ai-title` record in `~/.claude/projects/*/<sessionId>.jsonl` |

A pid record counts as live only when the pid is still up *and* its kernel start
time matches the recorded one, so a recycled pid cannot resurrect a session that
has already exited. Stale records are ignored, never deleted.

The subject falls back to the transcript's `summary`, then to the opening message,
if no `ai-title` has been written yet.

`sessions-index.json` looks like the obvious source and is not: it stops being
updated and does not know about running sessions.

## Cost of a refresh

The panel refreshes every 5 seconds.

- First scan: ~0.3s, one time, on a background queue.
- Every scan after that: ~3ms. Titles are cached per transcript and re-read only
  when the file's size or modification date changes.

Transcripts grow to megabytes, so only the last 256 KB is read: `ai-title` is
rewritten at the end of the file as the conversation moves on.
