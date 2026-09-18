#!/bin/zsh
# Builds FuzzyBar.app into ./build. Pass --install to copy it to /Applications.
#
# Signing: set SIGN_IDENTITY to a Developer ID / Apple Distribution certificate
# name (or SHA-1) to produce a properly signed build. Unset, the app is ad-hoc
# signed, which is fine for running locally. Never commit certificates or keys.
set -euo pipefail
cd "$(dirname "$0")"

TEAM_ID="FGG98L437R"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

swift build -c release --arch arm64 2>&1 | grep -v '^\[' || true
BIN=".build/apple/Products/Release/FuzzyBar"
[[ -x "$BIN" ]] || BIN=".build/release/FuzzyBar"

APP="build/FuzzyBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/FuzzyBar"
cp Info.plist "$APP/Contents/Info.plist"
cp Assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

if [[ "$SIGN_IDENTITY" == "-" ]]; then
    codesign --force --sign - "$APP"
    echo "Built $APP (ad-hoc signed; set SIGN_IDENTITY for a real signature)"
else
    codesign --force --options runtime --timestamp \
        --entitlements FuzzyBar.entitlements \
        --sign "$SIGN_IDENTITY" "$APP"
    codesign --verify --strict "$APP"
    echo "Built $APP (signed with $SIGN_IDENTITY, team $TEAM_ID)"
fi

if [[ "${1:-}" == "--install" ]]; then
    pkill -x FuzzyBar || true
    rm -rf /Applications/FuzzyBar.app
    cp -R "$APP" /Applications/FuzzyBar.app
    open /Applications/FuzzyBar.app
    echo "Installed and launched /Applications/FuzzyBar.app"
fi
