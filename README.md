# Zettair iOS

Native SwiftUI client for [zettair.io](https://zettair.io). Search 1.5M
Wikipedia articles with knowledge panels, related entities, a trending
list, a daily morning brief, Siri/Spotlight integration, and a branded
launch + icon. Built per [PRD-028](https://github.com/Krensen/zettair-search/blob/main/prd/PRD-028-ios-app.md).

The app is a thin client of the existing Zettair JSON API. No accounts,
no server-side per-user state, no analytics.

## Project state (last reviewed 2026-05-25)

End of PRD-028 v1 scope (M1–M5) plus several v1.1 features brought
forward. Everything in the table is working in the simulator and on a
side-loaded device.

| Area | What | State |
|------|------|-------|
| Search | `.searchable` field, autosuggest, results, click logging | done |
| Active-search overlay | Apple Settings-style 4-up grid of trending; suggestion list while typing | done |
| Knowledge panel | Renders `summary` markdown, kind badge, event-date pill, hero image | done |
| Related entities | Right-rail (iPad) / bottom panel (iPhone), tap to search | done |
| Trending | Vertical list with real Wikimedia thumbnails (smart-cropped via Vision) | done |
| Cite-this | Native sheet with APA / MLA / Chicago / Harvard / BibTeX | done |
| Daily brief | 3 swipeable cards, opt-in daily local notification, deep-link from notification | done |
| Spotlight + AppIntents | Background prefix-sweep seed; per-search donation; Siri phrase "Search Wikipedia in Zettair" | done |
| Launch animation | Letter-by-letter Zettair wordmark + stripe sweep | done |
| App icon | Diagonal stripe band over italic Z, regenerable via `tools/generate_icon.py` | done |
| Saved tab | UserDefaults stub (PRD-028 M10 placeholder; iCloud sync not yet) | partial |
| Widget extension | Project target exists with a placeholder; full WidgetKit work is M7 | placeholder |
| Share extension | Project target exists with a placeholder; full plumbing is M8 | placeholder |
| Offline cache | In-memory `ArticleCache` only; `/article` backend endpoint is M6 | not started |
| Universal Links | `deploy/apple-app-site-association.json` ready; needs Caddy + paid Developer Program | not started |
| App Store prep | Not started; M12 work | not started |

CI status: green on `main`. `swift test` covers ZettairKit; `xcodebuild`
runs a clean device build with code signing disabled.

## Repo layout

```
project.yml                       — XcodeGen descriptor; run `xcodegen` to regenerate Zettair.xcodeproj
Zettair.xcodeproj                 — generated, gitignored; xcodegen rebuilds it
ZettairApp/                       — main app, SwiftUI, iOS 16+
  App/                            — @main, AppRouter, AppEnvironment, RootView, LaunchView
  Common/                         — Brand (logo + stripe), Haptics, SafariView, SmartImageView
  Features/Search/                — SearchTabView, SearchViewModel, ActiveSearchView,
                                    ResultsView, ResultRow, SnippetText, KnowledgePanelCard,
                                    RelatedEntitiesPanel, HomeView, CiteThisSheet, ErrorView
  Features/Trending/              — TrendingListView (home), TrendingRailView (unused chip variant)
  Features/Brief/                 — DailyBriefView, DailyBriefViewModel,
                                    NotificationScheduler, NotificationDelegate
  Features/Saved/                 — SavedTabView, SavedStore
  Features/Settings/              — SettingsTabView (brief opt-in, citation style, etc.)
  Intents/                        — SearchZettairIntent (AppIntents), IntentDonations
  Spotlight/                      — SpotlightIndexer
  Resources/Assets.xcassets/      — AppIcon.appiconset (regen via tools/generate_icon.py)
ZettairWidget/                    — WidgetKit extension placeholder (M7)
ZettairShare/                     — Share extension placeholder (M8)
ZettairKit/                       — shared Swift package, pure Foundation + URLSession
  Sources/ZettairKit/             — ZettairAPI, Models, Citations, QueryNorm,
                                    ArticleCache, ImageProxy, DailyBrief
  Tests/ZettairKitTests/          — URLProtocol stub, JSON fixtures, unit tests
tools/
  generate_icon.py                — PIL-based icon renderer; outputs all required iOS sizes
deploy/
  apple-app-site-association.json — for Caddy to serve at /.well-known/ on zettair.io
  README.md                       — Caddy snippet + Universal Links setup
.github/workflows/ci.yml          — macos-15 + Xcode 16.4 + swift test + xcodebuild device build
```

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Full-featured build. Has widget + share extension targets, App Group entitlement, Associated Domains. Requires Apple Developer Program ($99/yr) to sign for a real device. |
| `sideload` | Stripped for free-Apple-ID signing: widget + share extension targets removed, App Group + Associated Domains entitlements cleared. Main app is otherwise identical. Switch back to `main` when ready to pay for Developer Program. |

## Quickstart

```bash
# 1. Tooling (one-time)
brew install xcodegen

# 2. Generate the Xcode project from project.yml
cd zettair-ios
xcodegen

# 3. Open in Xcode
open Zettair.xcodeproj
```

Pick a simulator destination, ⌘R.

## Building on a real device

### Free Apple ID (7-day expiring side-load)

1. `git checkout sideload`
2. `xcodegen`
3. Xcode → project → ZettairApp target → Signing & Capabilities → tick Automatically Manage Signing → Team = your Personal Team
4. Plug in phone (or pair it via Window → Devices and Simulators if not already paired)
5. ⌘R, then on the phone Settings → General → VPN & Device Management → Trust your Apple ID

The widget and share extension are not in the sideload build (free
accounts can't register App Groups in the Apple Developer portal).
Everything else works.

### Paid Apple Developer Program

1. Enroll at developer.apple.com ($99/year)
2. In Apple Developer portal → Identifiers → App Groups → register `group.io.zettair.app`
3. `git checkout main` and `xcodegen`
4. Xcode → set Team on all three targets (ZettairApp, ZettairWidget, ZettairShare) → Automatically Manage Signing for each
5. ⌘R to device, or Product → Archive → TestFlight for over-the-air distribution

## Backend (zettair.io)

The app talks to `https://zettair.io` via these endpoints. All public,
all return JSON, no auth.

| Endpoint | Use |
|----------|-----|
| `GET /search?q=...&n=...` | Search; returns results + summary + related entities + event date |
| `GET /suggest?q=...&n=...` | Autosuggest |
| `GET /api/trending?n=...` | Home + active-search trending list; includes per-item `image_url` |
| `GET /img?url=...` | Wikimedia image proxy with allowed-thumb-width coercion |
| `POST /click` | Click logging |
| `GET /article?docno=...` | **Not live yet** (PRD-028 M6). Required for the offline cache. |

User-Agent is set to `ZettairIOS/<version>` so app traffic is
distinguishable in `logs/queries.jsonl`.

### Image handling

`ImageProxy.url(for:, preferredWidth:)` (in ZettairKit) rewrites the
thumbnail width in the URL to the closest one Wikimedia accepts (20, 40,
60, 120, 250, 330, 500, 960, 1280, 1920, 3840) and routes the request
through `/img` for the polite User-Agent + Cache-Control. The server-side
proxy does its own width coercion as a safety net.

`SmartImageView` (in ZettairApp/Common) downloads via URLSession, runs
Apple's Vision framework (face detection first, attention-saliency
fallback) to compute the salient crop rect once per URL, persists the
rect to disk, then renders the cropped image. **Important**: the
`fillParent` variant uses a `Color.clear` size authority instead of
`Image.aspectRatio(_, .fill)` to avoid SwiftUI's "image proposes
wider-than-parent size" pitfall that previously broke `.padding(.horizontal)`
on the brief card.

## Daily brief

`DailyBriefAssembler` (in ZettairKit) calls `/api/trending` for top
items, then for each calls `/search?q=...&n=1` to pick up the summary
markdown + URL. The assembled brief is keyed by local date and disk-
persisted, so re-opening the app on the same day reads from cache.

`BriefNotifications.requestAndSchedule(at:)` (in ZettairApp) schedules
a single `UNCalendarNotificationTrigger` with `repeats: true`. The
notification is a doorbell only — taps deep-link into the Brief tab,
which then fetches/serves today's brief.

## Tests

```bash
cd ZettairKit
swift test
```

Tests use a `URLProtocol` stub so nothing hits the live server. Coverage
is the API client, models (including optional decoding for backwards
compat), citations (byte-equivalent to the website's PRD-024 format),
in-memory article cache, query normalisation, and ImageProxy width
rewriting.

No UI tests on the app target yet; XCUITest scaffolding is M12 work.

## Icons

```bash
python3 tools/generate_icon.py
```

Reads parameters at the top of the script (gradient colours, stripe
angle, glyph size). Writes a 1024 master plus every Apple-required
size into `ZettairApp/Resources/Assets.xcassets/AppIcon.appiconset/`
with a generated `Contents.json`.

## CI

`.github/workflows/ci.yml` runs on macos-15 with Xcode 16.4 pinned
explicitly (the macos-15 default is 16.4, but the path is `Xcode_16.4.app`,
not `Xcode_16.app` — that was a real CI failure). Two jobs:

1. `kit-tests` — `swift test` in ZettairKit
2. `xcode-build` — `xcodegen` + `xcodebuild` device build with code
   signing disabled. Device target instead of simulator because the
   runner's iphonesimulator SDK doesn't have matching simulator
   runtimes installed.

## Known issues and follow-ups

- **Cyrillic image URLs** (e.g. trending entry for Russia → Путин image)
  show the letter-tile fallback instead of the photo. Suspected
  UTF-8 round-trip issue between iOS URLComponents and the proxy.
- **AppShortcut phrase template** can't include `\(\.$query)` placeholder
  on Xcode 16.4+ — String parameters aren't allowed in phrase templates.
  Reduced to two no-parameter phrases ("Search Wikipedia in Zettair"
  and "Search Zettair") which Siri responds to by prompting for the
  query. Affects the Siri-from-lock-screen surface only.
- **Saved tab** persists locally via UserDefaults; no iCloud sync yet.
- **Offline article cache** requires the `/article` backend endpoint
  (PRD-028 M6). Server work, tracked on the server side.

## Server-side asks (the maintainer of zettair-search has these)

All three landed on 2026-05-25:

- `/img` no longer caps every request at 250px (was a one-line server
  bug); width coercion works correctly per Wikimedia's allowed widths
- `/api/trending` items now include `image_url` directly, eliminating
  the per-item `/search?n=1` fan-out from the home view
- `/img` proxy passes through upstream HTTP status codes instead of
  blanket-404'ing on any error

The fourth ask (default thumb width 300 → 500 in the images sidecar
extractor) is documented but deferred to the next corpus rebuild.

## License

MIT. Knowledge-panel content and search results are derived from
English Wikipedia, licensed CC BY-SA. The app credits Wikipedia on
every result and links to the source article.

---

## Notes for whoever is restoring conversation context

If this is being read as a recovery document after a context compaction,
here's the operating state:

- **You can stop guessing** about layout bugs and most of the early
  thrash around `.searchable` behaviour, `\.isSearching`, AppIntents
  validation rules, and SwiftUI image sizing — those are all resolved
  and the relevant patterns are committed in the files referenced above.
- **The user is Hugh Williams** (Krensen on GitHub). zettair.io is his
  own project, related sibling repos are `zettair-search` and `zettair`.
- **Recent style guidance** that was learned the hard way: when a
  SwiftUI primitive misbehaves, find the documented escape hatch
  (`\.dismissSearch`, `Color.clear` size authority, etc.) instead of
  layering workarounds. The user reads `git log` and notices hacking.
- **Server changes**: the user prefers to be asked, then he runs them
  through another Claude instance against the server repo. Don't touch
  zettair-search or the production VPS directly.
- **Branches**: `main` is the full build; `sideload` is what the user
  installs on his iPhone via free Apple ID. Keep `sideload` in sync
  with main via cherry-pick or merge after every change.
- **CI**: macos-15 + Xcode 16.4 device build is the current
  configuration. `simctl install` over an existing install can be
  flaky; `simctl uninstall` first if changes don't appear.
