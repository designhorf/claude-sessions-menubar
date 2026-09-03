#!/bin/bash
# Rules a machine can see. Run before every commit.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
report() { echo "  FAIL  $1"; shift; printf '%s\n' "$@" | sed 's/^/        /'; fail=1; }
pass()   { echo "  ok    $1"; }

VIEWS=$(ls Sources/ClaudeSessions/*.swift | grep -v Theme.swift)

# Values belong to Theme.swift, not to the views that use them.
hits=$(grep -nE 'Color\(hex:|Color\(red:|\.font\(\.system\(size: [0-9]|cornerRadius: [0-9]' $VIEWS || true)
[ -z "$hits" ] && pass "no hardcoded colours or sizes outside Theme.swift" \
                || report "hardcoded value outside Theme.swift" "$hits"

# The app is light only.
hits=$(grep -rn 'prefers-color-scheme\|NSAppearanceNameDarkAqua\|colorScheme == .dark' Sources/ || true)
[ -z "$hits" ] && pass "light only" || report "dark appearance branch" "$hits"

# Nothing but English ships.
# This file is excluded because it has to spell the letters it forbids.
hits=$(grep -rnE --exclude=check.sh '[áéíóöőúüűÁÉÍÓÖŐÚÜŰ]' \
        Sources/ Tools/ scripts/ README.md CLAUDE.md 2>/dev/null || true)
[ -z "$hits" ] && pass "English only" || report "non-English text" "$hits"

# A path from one machine is not a path on another.
hits=$(grep -rn '/Users/' Sources/ Tools/ build-app.sh README.md 2>/dev/null || true)
[ -z "$hits" ] && pass "no absolute home paths" || report "absolute path" "$hits"

# It has to compile.
if swiftc -typecheck -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
     -target arm64-apple-macos13.0 Sources/ClaudeSessions/*.swift 2>/tmp/cs-typecheck; then
    pass "typechecks"
else
    report "typecheck failed" "$(head -20 /tmp/cs-typecheck)"
fi

echo
[ $fail -eq 0 ] && echo "all checks passed" || echo "checks failed"
exit $fail
