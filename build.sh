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

swift build -c release --arch arm64
BIN="$(swift build -c release --arch arm64 --show-bin-path)/FuzzyBar"
[[ -x "$BIN" ]] || { echo "Missing built executable: $BIN" >&2; exit 1; }

# Assemble and sign in a temp dir: folders under iCloud/Desktop sync pick up
# Finder and file-provider xattrs that make codesign reject the bundle.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
APP_STAGE="$STAGE/FuzzyBar.app"
mkdir -p "$APP_STAGE/Contents/MacOS" "$APP_STAGE/Contents/Resources"
cp "$BIN" "$APP_STAGE/Contents/MacOS/FuzzyBar"
cp Info.plist "$APP_STAGE/Contents/Info.plist"
cp Assets/AppIcon.icns "$APP_STAGE/Contents/Resources/AppIcon.icns"
xattr -cr "$APP_STAGE"

if [[ "$SIGN_IDENTITY" == "-" ]]; then
    codesign --force --sign - "$APP_STAGE"
    SIGN_NOTE="ad-hoc signed; set SIGN_IDENTITY for a real signature"
else
    codesign --force --options runtime --timestamp \
        --entitlements FuzzyBar.entitlements \
        --sign "$SIGN_IDENTITY" "$APP_STAGE"
    codesign --verify --strict "$APP_STAGE"
    SIGN_NOTE="signed with $SIGN_IDENTITY, team $TEAM_ID"
fi

APP="build/FuzzyBar.app"
rm -rf "$APP"
mkdir -p build
ditto "$APP_STAGE" "$APP"
echo "Built $APP ($SIGN_NOTE)"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x FuzzyBar || true
    rm -rf /Applications/FuzzyBar.app
    ditto "$APP_STAGE" /Applications/FuzzyBar.app
    open /Applications/FuzzyBar.app
    echo "Installed and launched /Applications/FuzzyBar.app"
fi
