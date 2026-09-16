#!/bin/bash
# Rules a machine can see. Run before every commit.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
mkdir -p .build
report() { echo "  FAIL  $1"; shift; printf '%s\n' "$@" | sed 's/^/        /'; fail=1; }
pass()   { echo "  ok    $1"; }

VIEWS=$(ls Sources/ClaudeSessions/*.swift | grep -v Theme.swift)

# Values belong to Theme.swift, not to the views that use them.
hits=$(grep -nE 'Color\(hex:|Color\(red:|\.font\(\.system\(size: [0-9]|cornerRadius: [0-9]' $VIEWS || true)
[ -z "$hits" ] && pass "no hardcoded colours or sizes outside Theme.swift" \
                || report "hardcoded value outside Theme.swift" "$hits"

# Light and dark live in Theme.Palette; a view never branches on the mode.
hits=$(grep -rnE 'colorScheme == \.dark|colorScheme == \.light|\.darkAqua' Sources/ \
        | grep -v -e 'Theme.swift' -e 'PanelAppearance.swift' || true)
[ -z "$hits" ] && pass "appearance only in Theme and PanelAppearance" || report "view branches on appearance" "$hits"

# Nothing but English ships.
# This file is excluded because it has to spell the letters it forbids.
hits=$(grep -rnE --exclude=check.sh '[áéíóöőúüűÁÉÍÓÖŐÚÜŰ]' \
        Sources/ Tools/ scripts/ README.md CLAUDE.md 2>/dev/null || true)
[ -z "$hits" ] && pass "English only" || report "non-English text" "$hits"

# A path from one machine is not a path on another.
hits=$(grep -rn '/Users/' Sources/ Tools/ build-app.sh README.md 2>/dev/null || true)
[ -z "$hits" ] && pass "no absolute home paths" || report "absolute path" "$hits"

# The app makes one kind of network call, a GET for usage, and only from one file.
hits=$(grep -rln 'URLSession\|URLRequest' Sources/ | grep -v 'UsageClient.swift' || true)
[ -z "$hits" ] && pass "network only in UsageClient.swift" || report "network call outside UsageClient.swift" "$hits"

# The sign-in belongs to Claude Code: read it, never refresh, write or delete it.
hits=$(grep -rnE 'refreshToken|httpMethod|SecItemAdd|SecItemUpdate|SecItemDelete' Sources/ || true)
[ -z "$hits" ] && pass "credentials read only" || report "credential write or non-GET request" "$hits"

# It has to compile.
if swiftc -typecheck -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
     -target arm64-apple-macos13.0 Sources/ClaudeSessions/*.swift 2>.build/cs-typecheck; then
    pass "typechecks"
else
    report "typecheck failed" "$(head -20 .build/cs-typecheck)"
fi

# The usage parsing and wording are pure, so they are tested without the app.
if swiftc -sdk "$(xcrun --sdk macosx --show-sdk-path)" -target arm64-apple-macos13.0 \
     Sources/ClaudeSessions/Usage.swift Sources/ClaudeSessions/UsageText.swift \
     Tools/UsageTests/main.swift -o .build/cs-usage-tests 2>.build/cs-usage-build \
   && .build/cs-usage-tests; then
    :
else
    report "usage tests failed" "$(head -20 .build/cs-usage-build)"
fi

echo
[ $fail -eq 0 ] && echo "all checks passed" || echo "checks failed"
exit $fail
