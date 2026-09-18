# FuzzyBar

A tiny native macOS menubar clock that tells the time in words.

<p align="center">
  <img src="Assets/screenshot.png" width="420" alt="FuzzyBar showing “nine o'clock” in the menubar, with its popover open">
</p>

Click it for the exact time, today's date, a month calendar, and a couple of
menu items. That's the whole app.

FuzzyBar exists because the fuzzy clock I'd used for years stopped getting
updates and still ran under Rosetta. This one is a few hundred lines of Swift,
builds natively for Apple Silicon, and has no dependencies.

## Features

- Time in words in the menubar, updated when the phrase changes
- Popover with the exact time, full date, and a month calendar with week numbers
- Start at login, via the system Login Items list
- No Dock icon, no network, no analytics, nothing running that doesn't need to

## Requirements

- macOS 14 Sonoma or later
- Xcode 15 or later (command line tools are enough) to build from source

## Build and install

```sh
git clone https://github.com/gkoch02/fuzzybar.git
cd fuzzybar
./build.sh --install
```

That builds a release binary, wraps it in `build/FuzzyBar.app`, copies it to
`/Applications`, and launches it. Run `./build.sh` on its own to build without
installing.

Local builds are ad-hoc signed, which is all you need to run it on your own
Mac. If you have an Apple developer certificate and want a real signature,
point `SIGN_IDENTITY` at it:

```sh
SIGN_IDENTITY="Apple Development: Your Name (TEAMID)" ./build.sh --install
```

No certificates, keys, or notarization credentials are stored in this repo.

## How the fuzzy time works

Minutes are rounded to the nearest five, then mapped to the usual spoken
phrases: *o'clock*, *five past*, *ten past*, *quarter past*, *twenty past*,
*twenty-five past*, *half past*, and the same again counting down *to* the next
hour. So 8:38 is "twenty to nine" and 8:37 is "twenty-five to nine".

The logic lives in `Sources/FuzzyBar/FuzzyTime.swift` and is covered by tests:

```sh
swift test
python3 -m unittest discover -s Tests/BuildScriptTests
```

Tests cover all daily phrase boundaries, calendar grids, clock scheduling, login
approval states, and build-script failure handling.

## Project layout

| Path | What it is |
| --- | --- |
| `Sources/FuzzyBar/FuzzyBarApp.swift` | App entry point and the menubar popover |
| `Sources/FuzzyBar/FuzzyTime.swift` | Time-to-words conversion |
| `Sources/FuzzyBar/Clock.swift` | Phrase-boundary ticker (minute updates while the popover is open) |
| `Sources/FuzzyBar/CalendarView.swift` | Month grid |
| `Sources/FuzzyBar/SettingsView.swift` | Preferences window |
| `Assets/` | Icon renderer and the generated `.icns` |
| `build.sh` | Builds, signs, and optionally installs the app bundle |

## Regenerating the icon

The app icon is drawn in code. Edit `Assets/make_icon.swift` and run:

```sh
./Assets/make_icns.sh
```

## License

MIT. See [LICENSE](LICENSE).
