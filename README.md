# FuzzyBar

A tiny native macOS menubar clock that shows the time in words ("twenty to nine").
Click it for the exact time, a calendar, Preferences (start at login) and Quit.

Native Apple Silicon, macOS 14+, no dependencies.

## Build

    ./build.sh            # produces build/FuzzyBar.app
    ./build.sh --install  # also copies to /Applications and launches it

## Signing

Local builds are ad-hoc signed. For a distributable build, point `SIGN_IDENTITY`
at a certificate in your keychain:

    SIGN_IDENTITY="Apple Distribution: Your Name (TEAMID)" ./build.sh

Certificates, keys and notarization credentials are never committed.

## Test

    swift test
