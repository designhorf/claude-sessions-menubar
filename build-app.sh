#!/bin/bash
# Builds ClaudeSessions.app. No Xcode required, Command Line Tools are enough.
set -euo pipefail

cd "$(dirname "$0")"
APP="ClaudeSessions.app"
SDK=$(xcrun --sdk macosx --show-sdk-path)

echo "compiling…"
swiftc -O -sdk "$SDK" -target arm64-apple-macos13.0 -parse-as-library \
    Sources/ClaudeSessions/*.swift -o ClaudeSessions

echo "packaging…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mv ClaudeSessions "$APP/Contents/MacOS/ClaudeSessions"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Claude Sessions</string>
    <key>CFBundleDisplayName</key><string>Claude Sessions</string>
    <key>CFBundleIdentifier</key><string>hu.designhorf.claudesessions</string>
    <key>CFBundleExecutable</key><string>ClaudeSessions</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSAppleEventsUsageDescription</key><string>Claude Sessions asks Ghostty to bring a session's terminal tab to the front.</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP" 2>/dev/null || echo "  (ad-hoc signing skipped)"
echo "done: $(pwd)/$APP"
