#!/bin/bash
# Checks an Xcode archive is a Release build of what the project says, before
# it is validated and uploaded.
#
#   Tools/check_archive.sh                    # the newest archive of any scheme below
#   Tools/check_archive.sh path/to.xcarchive
#
# The shared scheme's Archive action is Release, but a setting is not a proof,
# and nothing downstream asks: a Debug archive re-signs, validates, uploads and
# passes review like any other. So this reads the archive itself. Its signing
# is no guide — an archive is signed for development and carries
# get-task-allow until Distribute App re-signs it — so what is checked is what
# the build configuration leaves in the products:
#
# - the version and build Xcode resolves for the scheme's Release
#   configuration, so the upload is the one that was bumped;
# - a dSYM for every binary, marked optimised: the compiler writes
#   DW_AT_APPLE_optimized into the debug info of code built with -O, and
#   Debug's -Onone code has none (measured on a Release archive, 21,932 marks,
#   against a Debug build of the same app, 0). Debug's default debug format
#   makes no dSYM at all, which fails the same check;
# - no .debug.dylib, which a Debug build ships its code in.
#
# Nothing here reads the app's own code, so it is the same script in every
# PlumpBug repo; only the block below differs.
set -euo pipefail
cd "$(dirname "$0")/.."

# --- this repo ---------------------------------------------------------------
PROJECT="FuzzyBar.xcodeproj"
SCHEMES=(FuzzyBar)           # archives are named after the scheme
# ------------------------------------------------------------------------------

if [ $# -gt 0 ]; then
    ARCHIVE="$1"
else
    # Globbed rather than typed: Xcode names archives with a narrow no-break
    # space before "AM"/"PM", which a path written by hand never matches.
    globs=()
    for scheme in "${SCHEMES[@]}"; do
        globs+=("$HOME"/Library/Developer/Xcode/Archives/*/"$scheme "*.xcarchive)
    done
    ARCHIVE=$(ls -dt "${globs[@]}" 2>/dev/null | head -1 || true)
fi
[ -n "$ARCHIVE" ] && [ -d "$ARCHIVE" ] || { echo "no archive found for ${SCHEMES[*]}" >&2; exit 1; }

SCHEME=""
for candidate in "${SCHEMES[@]}"; do
    case "$(basename "$ARCHIVE")" in "$candidate "*) SCHEME="$candidate" ;; esac
done
[ -n "$SCHEME" ] || { echo "$(basename "$ARCHIVE") is not an archive of ${SCHEMES[*]}" >&2; exit 1; }

failures=0
pass() { echo "  ok    $1"; }
fail() { echo "  FAIL  $1"; failures=$((failures + 1)); }
plist() { /usr/libexec/PlistBuddy -c "Print :$1" "$2" 2>/dev/null || true; }

echo "$(basename "$ARCHIVE")"

# What Xcode resolves for the scheme's Release configuration: the app target's
# name, bundle ID and numbers, whatever file they are set in.
settings=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
    -showBuildSettings -json 2>/dev/null | python3 -c '
import json, sys
for entry in json.load(sys.stdin):
    s = entry["buildSettings"]
    if s.get("WRAPPER_EXTENSION") == "app":
        print(s["WRAPPER_NAME"], s["PRODUCT_BUNDLE_IDENTIFIER"], s["MARKETING_VERSION"], s["CURRENT_PROJECT_VERSION"])
        break
')
read -r wrapper want_id want_version want_build <<< "$settings"
[ -n "${wrapper:-}" ] || { echo "  could not read $SCHEME's Release settings from $PROJECT" >&2; exit 1; }

APP="$ARCHIVE/Products/Applications/$wrapper"
[ -d "$APP" ] || { fail "no $wrapper in the archive"; exit 1; }
# A Mac app keeps its Info.plist under Contents/.
INFO="$APP/Info.plist"; [ -f "$INFO" ] || INFO="$APP/Contents/Info.plist"

version=$(plist CFBundleShortVersionString "$INFO")
build=$(plist CFBundleVersion "$INFO")
if [ "$version" = "$want_version" ] && [ "$build" = "$want_build" ]; then
    pass "version $version ($build), as the project says"
else
    fail "version $version ($build); the project says $want_version ($want_build)"
fi
bundle_id=$(plist CFBundleIdentifier "$INFO")
[ "$bundle_id" = "$want_id" ] && pass "bundle ID $bundle_id" || fail "bundle ID $bundle_id; the project says $want_id"

# Every bundle with code in it: the app and any extension or framework it
# carries, each needing its own optimised dSYM.
while IFS= read -r -d '' bundle; do
    name=$(basename "$bundle")
    dsym="$ARCHIVE/dSYMs/$name.dSYM"
    if [ ! -d "$dsym" ]; then
        fail "$name has no dSYM: Debug's default is plain DWARF, which makes none"
        continue
    fi
    # Counted in full, not `grep -q`: under pipefail an early exit kills
    # dwarfdump with SIGPIPE, and a found mark would read as a missing one.
    marks=$(dwarfdump --debug-info "$dsym" 2>/dev/null | grep -c DW_AT_APPLE_optimized || true)
    [ "$marks" -gt 0 ] && pass "$name built optimised ($marks marks in its dSYM)" \
                       || fail "$name's dSYM has no optimised code: this is a Debug build"
done < <(find "$APP" \( -name "*.app" -o -name "*.appex" -o -name "*.framework" \) -type d -print0)

if [ -n "$(find "$APP" -name "*.debug.dylib" -print -quit)" ]; then
    fail "a .debug.dylib is bundled: this is a Debug build"
else
    pass "no debug dylib"
fi

echo
if [ "$failures" -eq 0 ]; then
    echo "Ready to validate and upload."
else
    echo "$failures check(s) failed. Do not upload this archive."
    exit 1
fi
