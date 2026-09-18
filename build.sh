#!/bin/zsh
# Builds FuzzyBar.app into ./build. Pass --install to copy it to /Applications.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release --arch arm64 2>&1 | grep -v '^\[' || true
BIN=".build/apple/Products/Release/FuzzyBar"
[[ -x "$BIN" ]] || BIN=".build/release/FuzzyBar"

APP="build/FuzzyBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/FuzzyBar"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x FuzzyBar || true
    rm -rf /Applications/FuzzyBar.app
    cp -R "$APP" /Applications/FuzzyBar.app
    open /Applications/FuzzyBar.app
    echo "Installed and launched /Applications/FuzzyBar.app"
fi
