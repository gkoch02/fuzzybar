# App Store — the release record

> **Status: not yet submitted.** Bundle ID `dev.plumpbug.fuzzybar` · team `FGG98L437R`
> · **$0.99, paid up front**, no in-app purchases · macOS 14 Sonoma or later.
> The source stays free under MIT; the store price buys a signed build the store
> installs and updates. The plumpbug.dev pages say the same (site commit
> "Price FuzzyBar at $0.99 on the Mac App Store", September 18, 2026).
>
> The code-side work is done (§0) and a store-signed `.pkg` has been produced from
> this repo (September 18, 2026). What remains is App Store Connect: the agreement
> and app record (§2), the listing copy (§3–§5), screenshots (§6), and the upload (§7).

Everything that has to happen outside the code to get FuzzyBar onto the Mac App
Store, plus the paste-ready metadata. Conventions follow the Nightdraft and Between
Us playbooks so all the PlumpBug apps ship the same way: same developer account, same
brand domain, same bundle-ID shape.

FuzzyBar is the first **macOS** app in the family. The differences from the iOS
playbooks are: the archive is a `.pkg` rather than an `.ipa`, App Sandbox is
mandatory, there is no launch screen or device-family setting, and Mac screenshots
have their own sizes.

---

## 0. Already done in this repo — don't redo these

- **Xcode project** — `FuzzyBar.xcodeproj`, generated from `project.yml` by
  [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). Edit
  the spec and run `xcodegen generate`; both are committed so Xcode and Organizer
  work without the tool. SwiftPM (`Package.swift`, `build.sh`) remains the local
  build and test path; the project exists for store archives and signing.
  Two gotchas in the spec: `info:` and `entitlements:` keys would *regenerate*
  `Info.plist` and `FuzzyBar.entitlements`, so both are referenced by build setting
  only; and the test target needs `GENERATE_INFOPLIST_FILE: YES` or signing fails.
  The project lists source files explicitly, so **every new Swift file needs
  `xcodegen generate` and a commit of the project**; `Tests/BuildScriptTests`
  fails until that is done (#4 shipped the personalities without it once).
- **Open the project, not the package.** Xcode happily opens this folder as a Swift
  package, and Product → Archive then produces a "Generic Xcode Archive" with no
  version, no identifier and only a Custom distribution method, because a SwiftPM
  executable is not an app bundle. Open `FuzzyBar.xcodeproj`, pick the FuzzyBar
  scheme and My Mac, and archive from there.
- **Signing** — `DEVELOPMENT_TEAM = FGG98L437R`, `CODE_SIGN_STYLE = Automatic`,
  committed in the project. `xcodebuild ... -allowProvisioningUpdates` registered
  the bundle ID and created the "Mac Team Store Provisioning Profile" and the
  `3rd Party Mac Developer Installer` certificate on first export (September 18,
  2026), so nothing needs doing by hand in the developer portal.
- **App Sandbox** — `FuzzyBar.entitlements` enables it with no exceptions. Verified
  the sandboxed archive build launches, shows the phrase, and creates its container
  with no denials in the unified log. The login toggle uses `SMAppService.mainApp`,
  which works inside the sandbox.
- **Hardened runtime** — on. Not required for the store, harmless, and it means the
  same archive could be notarized for direct download later.
- **Info.plist** — `ITSAppUsesNonExemptEncryption = NO` (no export-compliance stall
  on upload), `LSApplicationCategoryType = public.app-category.utilities`,
  `LSUIElement = YES` (menubar-only, no Dock icon), copyright
  `© 2026 Gregory M Koch`. Version 1.0, build 1. The plist is literal, not
  generated, because `build.sh` copies it verbatim.
- **Privacy manifest** — `Resources/PrivacyInfo.xcprivacy`: no tracking, nothing
  collected, `UserDefaults` declared with `CA92.1`. Must stay in step with §4 and
  with the privacy page on plumpbug.dev (§1).
- **App icon** — `Resources/Assets.xcassets/AppIcon.appiconset`, ten PNGs from
  16 to 1024 px, written by `Assets/make_icns.sh` alongside the `.icns` that
  `build.sh` uses. macOS icons keep their alpha (rounded body plus shadow); the
  iOS "strip the alpha" rule does not apply here.
- **Export options** — `ExportOptions.plist`, method `app-store-connect`,
  destination `upload`.
- **Release checks** — as of September 18, 2026, on `main` after #4: `swift test`,
  `xcodebuild test` and the build-script suite pass (25 Swift tests, 3 Python), a
  Release archive builds universal (arm64 + x86_64), and `-exportArchive` produces a
  `.pkg` signed by `3rd Party Mac Developer Installer: Gregory M Koch (FGG98L437R)`
  with the store profile embedded. Re-run the three test commands and the two
  archive commands (§7) before every submission.

---

## 1. The pages on plumpbug.dev

Live since plumpbug-site PR #86 (September 18, 2026), served from that repo's
`docs/fuzzybar/`. The site's canonical URLs have no extension; the `.html` forms
redirect (308) to these, so use these in App Store Connect:

| Page | URL |
| --- | --- |
| About | <https://plumpbug.dev/fuzzybar/home> |
| Privacy | <https://plumpbug.dev/fuzzybar/privacy> |
| Support | <https://plumpbug.dev/fuzzybar/support> |

All three returned 200 on September 18, 2026. The privacy page already describes
the personality preference and the $0.99 price matches §3. Two sentences on it are
now wrong and should be fixed before submitting, since reviewers open the privacy
URL:

- [ ] **The entitlements sentence.** "Its hardened-runtime entitlements file is
      empty because it needs no entitlements" predates #3; the file now enables
      App Sandbox and nothing else. Say that the app runs in the App Sandbox with no
      other entitlements, which is the stronger claim anyway.
- [ ] **The preferences path.** The page names
      `~/Library/Preferences/dev.plumpbug.fuzzybar.plist`. That is where the
      unsandboxed `build.sh` build writes; the store build is sandboxed and writes to
      `~/Library/Containers/dev.plumpbug.fuzzybar/Data/Library/Preferences/dev.plumpbug.fuzzybar.plist`.
      The "What the app stores" and "Data deletion" sections both name the path.
- The pages say "built for Apple Silicon" because `build.sh` is arm64-only. The
  store build is universal, which the description in §3 says. Both are true; leave
  the site alone unless the direct-download build changes.

---

## 2. Before App Store Connect

- [x] **Apple Developer Program** — active, team `FGG98L437R`.
- [x] **Bundle ID registered** — done automatically on the first export (§0).
      Permanent once an app record exists.
- [ ] **Create the app record** — App Store Connect → My Apps → **+** → New App →
      platform **macOS**, name **FuzzyBar**, primary language English (U.S.), bundle
      ID `dev.plumpbug.fuzzybar`, SKU `fuzzybar`. The name check happens here and
      nowhere else; if "FuzzyBar" is taken, "FuzzyBar: Time in Words" is the
      fallback, and the display name in the app can stay as it is.
- [ ] **Paid Applications Agreement** — required, because this is the first paid app
      in the family. Agreements, Tax, and Banking → accept the Paid Apps agreement,
      then complete the bank account, tax forms (W-9 for a U.S. individual) and
      contact roles. Nothing can go on sale until the agreement shows "Active", and
      Apple's review of the tax forms can take days, so start this before anything
      else in this section.
- [ ] **EU trader status** — choose whatever Nightdraft and Between Us chose. A paid
      app makes the DSA trader question less avoidable than it was for the free ones:
      selling in EU storefronts publishes your name, address and phone number on the
      product page. Deselect EU storefronts if that is not acceptable.

---

## 3. App record — the metadata

Paste-ready. Keep the website telling the same story.

**Name** — `FuzzyBar`

**Subtitle** (30) — `The time, in words`

**Category** — Primary: Utilities. Secondary: none.

**Copyright** — `2026 Gregory M Koch` (no ©; App Store Connect prepends it).

**Support URL** — `https://plumpbug.dev/fuzzybar/support.html`
**Marketing URL** — `https://plumpbug.dev/fuzzybar/home.html`
**Privacy Policy URL** — `https://plumpbug.dev/fuzzybar/privacy.html`

**Keywords** (100) —
`fuzzy,clock,menubar,menu bar,time,words,text clock,word clock,minimal,calendar`

**Promotional text** (170) —
`A menubar clock that says "twenty to nine" instead of 8:38. Click it for the exact time and a calendar. That's the whole app.`

**Description** —

```
FuzzyBar tells the time the way you'd say it out loud. Instead of 8:38, your
menubar reads "twenty to nine". Click it for the exact time, today's date, and a
month calendar with week numbers.

Pick a personality in Preferences: plain spoken English, Shakespeare, Klingon,
Belter, German, HAL 9000, Cthulhu, or Latin. Every one of them tells the same
time, just with more character.

FuzzyBar is small on purpose.

• Time in words in the menubar, updated only when the phrase changes
• Exact time, full date, and a month calendar one click away
• Nine personalities
• Start at login, through the system Login Items list
• No Dock icon, no network, no analytics, no account
• Native on Apple silicon and Intel, a few hundred lines of Swift, no dependencies

Requires macOS 14 Sonoma or later. Open source under the MIT license.
```

**What's New** (1.0) — `First release.`

**Price** — the **$0.99 USD** price point (the lowest paid one), with Apple's
automatic equivalents elsewhere.
Availability: all storefronts except any deselected under EU trader status (§2).
No introductory offers, no IAP.

**Version** `1.0` · **Build** `1` (from `Info.plist`; bump both there and in
`project.yml` together, then `xcodegen generate` and commit the project).

---

## 4. Age rating and App Privacy

**Age rating** — answer None to everything → **4+**.

**App Privacy** — **Data Not Collected.** Every category answered "No". This is
what the privacy manifest declares and what the privacy page says; if the app ever
stores or sends anything more, all three change together.

---

## 5. App Review notes — paste into "Notes"

```
FuzzyBar is a menubar-only utility: it has no Dock icon and no main window
(LSUIElement). After launch, look for the time written in words in the menu bar,
e.g. "twenty to nine". Click it for the exact time, the date, a month calendar,
and the Preferences and Quit items.

Preferences (⌘, or the Preferences… item in the popover) has two settings: a
Personality picker that changes the phrasing, and a Start at login toggle that
registers the app with the system Login Items list via SMAppService.

The app has no networking code, no account, no analytics and no in-app
purchases; it is paid up front. It runs in the App Sandbox with no entitlements
beyond the sandbox itself. The same source is public under MIT at
https://github.com/gkoch02/fuzzybar; the store build is the signed, universal
(Apple silicon and Intel) binary with automatic updates.
```

**Sign-in required** — No. **Contact** — the developer account's name, phone and
email.

The recurring risk for a menubar-only app is **Guideline 2.1 (App Completeness)**:
a reviewer who expects a window sees nothing happen on launch. The first two
sentences of the note exist for that. **Guideline 4.2 (minimum functionality)** is
the secondary risk; a clock with a calendar, preferences and nine personalities is
comfortably past a single-function wrapper, but keep the personalities in the
description so the reviewer sees there is more than a label.

---

## 6. Screenshots

Mac App Store screenshots must be one of `1280×800`, `1440×900`, `2560×1600` or
`2880×1800` pixels (16:10), at least one, up to ten. `2880×1800` is the safe choice:
it is a Retina capture of a 1440×900 area and downscales cleanly.

- [ ] Capture on a clean desktop with the popover open and a calendar month that
      looks full (mid-month), one per personality worth showing (Spoken, HAL 9000,
      Cthulhu, Shakespeare).
- [ ] Follow the house rule: **captioned**, rendered from raws by a committed
      `make_screenshots.py` with captions lifted from the description above. The
      raw captures in `Assets/screenshots/` are gitignored working files, not the
      store set.

---

## 7. Order of operations

1. Merge the code, bump version and build in `Info.plist` and `project.yml` if this
   is not the first upload (then `xcodegen generate`), and run the three test
   suites:

   ```sh
   swift test
   xcodebuild -project FuzzyBar.xcodeproj -scheme FuzzyBar test
   python3 -m unittest discover -s Tests/BuildScriptTests
   ```

2. Archive and upload. From an iCloud-synced folder, keep `-derivedDataPath` and
   `-archivePath` outside it (Finder xattrs break code signing there; `build.sh`
   works around the same thing):

   ```sh
   OUT=/tmp/fuzzybar-release
   xcodebuild -project FuzzyBar.xcodeproj -scheme FuzzyBar -configuration Release \
     -derivedDataPath "$OUT/dd" -archivePath "$OUT/FuzzyBar.xcarchive" \
     -allowProvisioningUpdates archive
   xcodebuild -exportArchive -archivePath "$OUT/FuzzyBar.xcarchive" \
     -exportOptionsPlist ExportOptions.plist -exportPath "$OUT/export" \
     -allowProvisioningUpdates
   ```

   Or in Xcode: open **`FuzzyBar.xcodeproj`** (not the folder or `Package.swift`,
   see §0), scheme FuzzyBar, destination My Mac, Product → Archive, then in the
   Organizer: Distribute App → App Store Connect → Upload. It is the same signing
   path. Either way needs Xcode signed in to the account. If the Organizer shows
   the archive as "Generic Xcode Archive" with only a Custom method, the package
   was archived instead of the project.

3. Wait for the build to process (email arrives), then in App Store Connect attach
   it to the 1.0 version, fill §3–§5, add screenshots, and Submit for Review.
   Release: manual, so the site can be updated the same day.

4. After approval: record the Apple ID, URL and date at the top of this file, and add
   the App Store badge to the About page and the landing card on plumpbug.dev.

---

## 8. After launch — what still applies

- The bundle ID, the `UserDefaults` keys (`personality`), and `LSMinimumSystemVersion`
  become load-bearing against installs on other people's Macs.
- Updates: bump `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist`
  and the matching two lines in `project.yml`, run `xcodegen generate`, run the
  release checks, archive, upload.
- `build.sh` keeps producing the ad-hoc-signed direct-download build; the store
  build and the local build are the same code and the same bundle ID, so one replaces
  the other in `/Applications` cleanly.
