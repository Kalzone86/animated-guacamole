# RecipeVault

A free, open-source recipe manager inspired by Paprika 3: save recipes, browse
the web and clip recipes straight into the app, and keep everything synced
between your iPhone and Mac automatically — using your existing iCloud
account instead of a paid sync service.

This first version is the **iPhone app**. It's structured so a Mac app can
be added as a second target sharing the same recipe data and iCloud sync
(see "Adding the Mac app" below).

## Features

- **Recipe library** — search, favorites, and tag-based filtering.
- **iCloud sync** — built on SwiftData + CloudKit's automatic sync. Any
  device signed into the same iCloud account and running this app sees the
  same recipes, no server or account system of ours involved.
- **Import from a URL** — paste a recipe link and RecipeVault reads the
  page's structured recipe data (the same `schema.org/Recipe` markup Google
  uses for rich search results, which nearly every recipe blog publishes)
  and pulls out the title, photo, ingredients, directions, and times.
- **Built-in browser** — browse recipe sites inside the app and tap
  **Save Recipe** to clip whatever's on screen, the same workflow as
  Paprika's browser tab / Safari extension.
- **Dark mode** — follows System appearance by default, or force Light/Dark
  from Settings.

## Requirements

- A Mac with Xcode 15.4 or later (Xcode 16 recommended).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the
  `.xcodeproj` (the project file itself isn't committed — only the
  human-readable `project.yml` spec is, which is standard practice for
  keeping Xcode project diffs sane).
- Any Apple ID. A **free personal Xcode signing team is enough** to build
  and run this on your own iPhone — you do **not** need the $99/year Apple
  Developer Program just to use the app yourself. The one downside of a
  free account: apps installed this way stop launching after 7 days until
  you reopen Xcode and re-run them to your device.

## Setup

```bash
brew install xcodegen
cd RecipeVault
xcodegen generate
open RecipeVault.xcodeproj
```

In Xcode:

1. Select the **RecipeVault** target → **Signing & Capabilities**.
2. Under **Team**, choose your Apple ID (add it first via
   Xcode → Settings → Accounts if it's not listed). Xcode will create a
   free personal team if you don't have a paid one.
3. Confirm the **iCloud** capability is present with **CloudKit** checked
   and a container listed (it's pre-configured in `project.yml`, but Xcode
   may ask you to fix the container identifier to match your own Team ID —
   just accept its suggested fix).
4. Plug in your iPhone (or pick it as the run destination), and hit **Run**.
   On the phone, accept the "untrusted developer" prompt under
   Settings → General → VPN & Device Management the first time.
5. Make sure the same iCloud account is signed in on both your iPhone and
   your Mac (Settings → \[your name] on iPhone; System Settings → Apple ID
   on Mac) — that's what makes sync work once a Mac app exists.

The app works fully offline and locally even without iCloud sync enabled;
sync simply layers on top automatically.

## How recipe import works

Most recipe websites embed a block of structured data (JSON-LD,
`schema.org/Recipe`) so Google can show ratings/times/ingredients directly
in search results. `RecipeImporter` (see `RecipeVault/Import/`) looks for
that block and reads it directly — this is far more reliable than trying to
scrape visible page text, and it's why "Import from URL" and the in-app
browser's "Save Recipe" both tend to work on the first try on major recipe
sites. Sites that don't publish this data (or paywall it) will fall back to
"no recipe found," and you can always add the recipe by hand instead.

## Adding the Mac app (next step)

This project is laid out so a native Mac target can reuse everything in
`RecipeVault/Models` and `RecipeVault/Import` unchanged — only the SwiftUI
views would need a Mac-appropriate layout (e.g. a sidebar + detail split
view instead of a navigation stack). Once a second target is added to
`project.yml` pointing at the same `Recipe` model and CloudKit container
identifier, the two apps sync through the same private CloudKit database
with no extra code. Ask for this as a follow-up and it can be scaffolded
the same way this iPhone app was.

## Known limitations / not yet included

- No Mac app target yet (see above).
- No Share Extension (share a link from Safari's share sheet) — the
  in-app browser's "Save Recipe" button covers the same use case for now.
- No grocery list / meal planner (Paprika features not requested here).
- App icon is a placeholder; add real icon images to
  `RecipeVault/Resources/Assets.xcassets/AppIcon.appiconset` whenever you like.

## Project layout

```
RecipeVault/
  project.yml                 XcodeGen spec (generates the .xcodeproj)
  RecipeVault/
    App/                       App entry point, CloudKit container, dark mode state
    Models/                    SwiftData Recipe model
    Import/                    URL fetch + schema.org JSON-LD parsing
    Views/                     SwiftUI screens
    Resources/Assets.xcassets  App icon + accent color
```
