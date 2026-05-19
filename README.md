# Zettair iOS

Native SwiftUI client for [zettair.io](https://zettair.io), built per
[PRD-028](https://github.com/Krensen/zettair-search/blob/main/prd/PRD-028-ios-app.md).

The app is a thin client of the existing Zettair JSON API. No accounts,
no server-side per-user state, no analytics. iOS-specific features
(Spotlight, Siri, widget, share extension, offline cache) are the point.

## Status

| Milestone | What | State |
|-----------|------|-------|
| M1 | Project scaffold + networking | done |
| M2 | Search results UI | done |
| M3 | Trending + related entities + knowledge panel | done |
| M4 | Cite-this sheet | done |
| M5 | Spotlight + AppIntents + Siri donations | done |
| M6 | Offline cache + backend `/article` endpoint | not started |
| M7 | Home-screen widget (small/medium/large) | placeholder shipped |
| M8 | Share extension | placeholder shipped |
| M9 | Universal Links | docs in `deploy/apple-app-site-association.json` |
| M10 | Reading list + iCloud sync | UserDefaults stub |
| M11 | Context menus / haptics / iPad layout | mostly in M2 |
| M12 | App Store prep | not started |

**Nothing in this repo has been compiled.** It was written on a machine
with Command Line Tools only and a broken `swiftc`/SDK mismatch
(swiftlang 6.0.3.1.10 vs 6.0.3.1.5), so neither `swift test` nor
`xcodebuild` works locally. First compile happens when you open the
project in Xcode.

## Layout

```
project.yml                   — XcodeGen descriptor; run `xcodegen` to (re)generate Zettair.xcodeproj
ZettairApp/                   — main app, SwiftUI
  App/                        — @main, router, environment
  Common/                     — SafariView wrapper, haptics
  Features/Search/            — SearchTabView, ResultsView, ResultRow, KnowledgePanelCard, RelatedEntitiesPanel, CiteThisSheet
  Features/Trending/          — TrendingRailView, TrendingChip
  Features/Saved/             — SavedTabView, SavedStore
  Features/Settings/          — SettingsTabView
  Intents/                    — SearchZettairIntent, IntentDonations
  Spotlight/                  — SpotlightIndexer
ZettairWidget/                — WidgetKit extension, TrendingWidget (M7 placeholder)
ZettairShare/                 — Share extension, ShareViewController (M8 placeholder)
ZettairKit/                   — shared Swift package
  Sources/ZettairKit/         — ZettairAPI, Models, Citations, QueryNorm, ArticleCache, ImageProxy
  Tests/ZettairKitTests/      — URLProtocol stub, fixtures, unit tests
deploy/
  apple-app-site-association.json — for Caddy to serve at /.well-known/ on zettair.io
```

## Quickstart

```bash
# 1. Install XcodeGen if you haven't already
brew install xcodegen

# 2. Generate the Xcode project from project.yml
cd zettair-ios
xcodegen

# 3. Open in Xcode and run
open Zettair.xcodeproj
```

Sign each target with your Apple Developer team. App Group
`group.io.zettair.app` must be added to your account (Apple Developer →
Certificates, IDs & Profiles → App Groups).

## Backend dependencies

The app talks to `https://zettair.io` via these endpoints:

- `GET /search?q=...&n=...` — search
- `GET /suggest?q=...&n=...` — autosuggest
- `GET /api/trending?n=...` — trending chip rail
- `POST /click` — click logging
- `GET /article?docno=...` — **planned**, PRD-028 M6. Not live yet; the
  offline cache will gracefully degrade until it is.

`User-Agent` is set to `ZettairIOS/<version>` so app traffic is
distinguishable in `logs/queries.jsonl`.

## Universal Links

For deep-linking from Safari (`https://zettair.io/?q=...` opens directly
in the app), Caddy must serve `deploy/apple-app-site-association.json`
at:

```
https://zettair.io/.well-known/apple-app-site-association
```

with `Content-Type: application/json`. The file is small and static; no
Python changes required in `zettair-search`.

## Tests

```bash
cd ZettairKit
swift test            # API + model + citations + cache unit tests
```

Tests use a `URLProtocol` stub so nothing hits the live server.

The app target itself has no UI tests yet — XCUITest scaffolding is
M12 work.

## License

MIT. Knowledge-panel content and search results are derived from
English Wikipedia, licensed CC BY-SA. The app credits Wikipedia on
every result and links to the source article.
