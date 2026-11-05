# Claude Sessions

A macOS menu bar app that lists the Claude Code sessions running right now (how
many, since when, and what each one is about) and the plan usage `/usage` reports.

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

A raised grey top holds the name, what is running and the usage. Below it short rows split
by hairlines, each led by an icon. Every colour, size and radius lives in `Theme.swift`;
nothing downstream hardcodes a value.

The icons are [IBM Carbon](https://github.com/carbon-design-system/carbon/tree/main/packages/icons),
Apache-2.0, kept as path data in `Icon.swift`; the licence is in
`docs/third-party/carbon-icons-LICENSE`.

The panel is light by default. The moon and sun button next to the gear switches it to dark
and back, and the choice is remembered; the system setting is not followed.

The menu bar title reads `1/12  A: 12% W: 25%`: working over open sessions, then the
5-hour window and the weekly limit.

Usage leads, as one block for the session and the weekly limit. Open, each limit has a
bar and its reset time, and the header holds the fetch time and a refresh button.
Folded, it is one line with a ring per limit; the panel remembers the choice. Below it,
Working and Idle. Idle shows the three most recent sessions and folds the rest behind
"Show all".

## Servers

Below the sessions, the Servers section lists the local dev servers: project, port, how
long it has run and how much memory it and its children hold. Clicking a row opens it in
the browser; the power button stops it, launcher chain included, so `pnpm dev` does not
start it again. Stop all asks for a second click. `Tools/ServerProbe` lists the live
servers from the terminal and, with `--stop <port>`, stops one.

## Looking at the layout

`Tools/main.swift` renders the panel body to PNGs, which is how the layout gets checked
without photographing the menu bar:

```bash
swiftc -sdk "$(xcrun --sdk macosx --show-sdk-path)" -target arm64-apple-macos13.0 \
    $(ls Sources/ClaudeSessions/*.swift | grep -v ClaudeSessionsApp) Tools/main.swift -o /tmp/render
/tmp/render /tmp   # the panel open and folded, plus the usage states from fixtures
```

`ImageRenderer` draws neither `ScrollView` content nor a `Menu`, so the harness stands in
for the panel chrome and renders the list for real.

## Where the data comes from

Nothing is written. The only network call is the usage GET below.

| What | Source |
| --- | --- |
| Which sessions run | `~/.claude/sessions/<pid>.json` |
| Started at, working directory, idle or busy | the same file |
| Subject | the last `ai-title` record in `~/.claude/projects/*/<sessionId>.jsonl` |
| Usage on launch | `cachedUsageUtilization` in `~/.claude.json`, what Claude Code last fetched |
| Usage on open, on Refresh, and every 5 min while a session works | `GET https://api.anthropic.com/api/oauth/usage`, the endpoint `/usage` calls |
| The token for that call | the `Claude Code-credentials` item in the login keychain, read only |

The usage endpoint is not a documented API. When it fails, the panel keeps the last
numbers, dimmed, with their time.

macOS asks once whether the app may read `Claude Code-credentials`. The build is signed
ad hoc, so the signature changes with every build and the question comes back after
each rebuild.
