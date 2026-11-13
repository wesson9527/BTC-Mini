#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
arch="${1:-$(uname -m)}"
case "$arch" in arm64|x86_64) ;; *) echo 'Expected arm64 or x86_64' >&2; exit 1 ;; esac
app="build/BTC Mini.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
xcrun swiftc -O -swift-version 5 -parse-as-library -target "$arch-apple-macos13.0" \
    Sources/*.swift -o "$app/Contents/MacOS/BTCMini"
cp Info.plist "$app/Contents/Info.plist"
codesign --force --sign - --options runtime --timestamp=none --entitlements entitlements.plist "$app"
codesign --verify --deep --strict "$app"
echo "Built: $PWD/$app ($arch)"
