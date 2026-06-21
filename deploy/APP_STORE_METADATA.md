# App Store Connect — submission metadata

Paste-ready strings for filling out App Store Connect. Each section
labels which Apple field it goes into. Some fields have hard
character limits (Apple counts code points, not bytes); the limit is
noted and the draft fits inside it.

---

## App Information

### App name
**Apple field**: Name (max 30 chars)

```
Zettair
```

If "Zettair" alone is too unclear in search, alternative:

```
Zettair — Wikipedia Search
```

(27 chars including the em dash.)

### Subtitle
**Apple field**: Subtitle (max 30 chars)

```
A faster way to read Wikipedia
```

(29 chars.) Alternative drafts that fit:

- `Search Wikipedia, your way` (26)
- `Wikipedia, instantly searchable` (31 — over, skip)
- `Knowledge panels and trends` (27)

### Bundle ID
```
io.zettair.app
```

### Primary language
```
English (U.S.)
```

### Category
**Primary**: Reference
**Secondary**: News

### Content Rights
You own or have licensed all content. (Wikipedia content is CC BY-SA;
the app credits Wikipedia per license.) Answer "Yes" to "Does your
app contain, show, or access third-party content?" and document
Wikipedia + Google News attribution in App Review notes (see below).

---

## Pricing and Availability

- **Price**: Free
- **Availability**: All territories (unless you have a specific
  reason to gate any)
- **Pre-orders**: No

---

## App Privacy

Fill in the App Privacy questionnaire to match `PRIVACY_POLICY.md`.
Verbatim answers:

### Data Collection

**Q: Does your app collect any data?**
Yes — but the only collected data is on the server side via standard
request logs.

### Data Types Collected

Check **only** the following:

- **Identifiers → Device ID**: NO
- **Identifiers → User ID**: NO
- **Diagnostics → Crash Data**: NO (handled by Apple, not by us)
- **Search History → Search History**: YES — used for "App
  Functionality" and "Analytics". Linked to user: **No**. Used for
  tracking: **No**.
- **Usage Data → Product Interaction**: YES (click logging). Linked
  to user: **No**. Used for tracking: **No**.
- **Identifiers → IP Address (under "Other Data Types")**: YES
  (server logs). Linked to user: **No**. Used for tracking: **No**.

Apple's questionnaire wording shifts; if "IP Address" is not directly
selectable, declare it under "Other Data Types → Other Diagnostic
Data" with the note "Server access logs contain client IP, not linked
to a user account."

### Privacy Policy URL

Once the file is hosted on zettair.io, this is the URL for App Store
Connect:

```
https://zettair.io/privacy
```

(See "Hosting the privacy policy" section below.)

### Tracking

The app does **NOT** track users across apps/websites. The App
Tracking Transparency prompt will not be shown.

---

## App Store Listing

### Promotional Text
**Apple field**: Promotional Text (max 170 chars; editable any time
without resubmitting)

```
Search 1.5M Wikipedia articles with knowledge panels, the day's news, related entities, and a morning brief — fast, ad-free, no account required.
```

(150 chars.)

### Description
**Apple field**: Description (max 4000 chars)

```
Zettair is a fast, focused way to search Wikipedia from your iPhone and iPad. It looks and feels like a search engine because that is what it is — a real BM25 ranking engine running over 1.5 million curated Wikipedia articles, with the kinds of touches you would expect from a major search product.

Knowledge panels. The top result is summarised in a clean panel with a hero image, a short paragraph, and a "show more" reveal. For queries that are currently in the news, the panel switches to a news-flavoured summary, with the source named explicitly — Wikipedia or Google News — so you always know where the words came from.

Related entities. Search a person and see related people, search a place and see related places. Generated from a random walk over the Wikipedia link graph; same-class only, so the rail stays coherent.

Trending. A live list of what is currently spiking, drawn from Wikipedia pageview data, Google News top stories, and Wikipedia's own "In the news" portal. Tap a chip to search it. Real thumbnails, smart-cropped for the subject's face when there is one.

Citations in five styles. Tap "cite" on any result to get APA, MLA, Chicago, Harvard, or BibTeX — copy-ready, generated natively on-device.

A morning brief. Opt in to a single daily notification and the app composes three swipeable cards from the morning's top trending stories. The notification is just a doorbell; the content is fetched and rendered when you open the app.

System-level integration. Recent searches show up in Spotlight. "Search Wikipedia in Zettair" works with Siri. Universal Links open zettair.io links in the app when you tap them anywhere on iOS.

Privacy. No account, no sign-up, no tracking, no advertising SDK. Your search history, saved queries, and reading list live on your device. Your queries are sent to the zettair.io server to actually run the search; the server keeps a request log to improve ranking, but the log is never linked to a user identity and is never sold or shared. The full policy is published on zettair.io and the source code is open.

Built on:

• 1.5 million top English Wikipedia articles
• A real BM25 ranking engine with per-field weighting
• Click-prior ranking from 15 months of Wikipedia clickstream data
• Query-biased summarisation in the result snippets
• Offline summary pipeline producing the knowledge-panel bodies
• Native SwiftUI, no embedded browsers, no analytics SDKs

For people who read Wikipedia for a living, or out of habit, or because the alternative is doomscrolling — Zettair tries to be the search box that is so fast and clean you reach for it first.

Wikipedia content is licensed under CC BY-SA. Zettair credits Wikipedia on every result and links back to the source article.
```

(~2570 chars, well under 4000.)

### Keywords
**Apple field**: Keywords (max 100 chars total, comma-separated, no
spaces around commas)

```
wikipedia,search,encyclopedia,reference,knowledge,trivia,research,news,trending,facts
```

(98 chars.)

Notes on keyword choice:

- "wikipedia" is the load-bearing one — most people who want this app
  will literally type "wikipedia" into App Store search.
- "search" and "encyclopedia" are obvious.
- "knowledge" picks up "knowledge panel" intent.
- "news" and "trending" pick up the live-news-summary use case.
- Apple's algorithm also uses the app **name**, **subtitle**, and
  **category** as implicit keywords. "Wikipedia" appears in the
  description; do not include the app name in the keyword field
  (Apple counts it automatically).

### Support URL
```
https://zettair.io
```

### Marketing URL (optional)
```
https://zettair.io
```

### Privacy Policy URL
```
https://zettair.io/privacy
```

---

## Age Rating

Run the questionnaire and answer:

- Cartoon or Fantasy Violence: None
- Realistic Violence: None
- Sexual Content or Nudity: None
- Profanity or Crude Humor: None
- Alcohol, Tobacco, or Drug Use: None
- Mature/Suggestive Themes: None
- Horror/Fear Themes: None
- Medical/Treatment Information: None
- Gambling: None
- Unrestricted Web Access: **YES** — the app links to external Wikipedia
  pages via Safari View Controller. This may push the rating to 17+
  in some App Store regions. That is acceptable.
- Gambling and Contests: None
- Frequent or intense user-generated content: None

Expected resulting rating: **17+** because of the unrestricted-web-
access flag (Wikipedia link-outs). This is the same rating Wikipedia's
own app gets and is unavoidable for any app that links to external
web content.

---

## App Review Notes

**Apple field**: Notes (visible to App Review team only, not users)

```
Zettair is a SwiftUI search client for the public website https://zettair.io. The website indexes 1.5 million English Wikipedia articles with a BM25 search engine, query-biased snippets, knowledge-panel summaries, and a trending news rail.

No account is required. No login screen exists. No demo credentials are needed.

Suggested test queries:
- "einstein" — biographical knowledge panel
- "iran" — news-flavoured knowledge panel (will vary with current news)
- "tom steyer" — another news example with the LLM/Google News attribution footer visible
- "morrissey" — biographical with related people rail
- "london" — geographical query
- "machine learning" — multi-word query

Content sources and attribution:

- Wikipedia article text is used under CC BY-SA. The app credits "Wikipedia" on every result and links back to en.wikipedia.org. The cite popover offers APA/MLA/Chicago/Harvard/BibTeX citations.
- Some news summaries are generated by a language model from Google News RSS headlines. The knowledge panel labels this honestly with an "AI summary from Google News headlines" footer.
- Wikimedia image thumbnails are fetched via the server's image proxy.

System integration features (per Guideline 4.2, Minimum Functionality):

- iOS Spotlight: recent searches are donated to Spotlight as on-device search results.
- Siri / AppIntents: "Search Wikipedia in Zettair" works as a Siri shortcut.
- Share Extension: text shared from other apps can be searched here.
- Widget: home-screen widget shows the day's trending list. (Note: widget is enabled on this build; free Apple ID side-load builds omit it.)
- Universal Links: tapping zettair.io URLs in Safari opens the app.

The app is a native SwiftUI client. It does not embed a WKWebView for primary content. External-link taps open SFSafariViewController.

Privacy:

- No third-party analytics SDK (no Firebase, no Mixpanel, no Google Analytics, etc.).
- No advertising network.
- No account or sign-up.
- Server-side query logs contain query string + IP + timestamp; no user identifier. Full policy at https://zettair.io/privacy.

Source code is published openly:
- https://github.com/Krensen/zettair-ios (app)
- https://github.com/Krensen/zettair-search (server)
```

---

## Build / Distribution

- **Distribution**: App Store
- **Sign-In Required**: No
- **Encryption**: `ITSAppUsesNonExemptEncryption` is set to `false`
  in Info.plist (see `project.yml`). The app uses only standard HTTPS,
  which is exempt. No export compliance documentation needed.
- **Demo Account**: Not required (no login).
- **Special Instructions for Review**: See "App Review Notes" above.

---

## Screenshots required

Apple's current minimum (as of mid-2026 — verify in App Store Connect
when you submit since the list shifts):

| Device | Resolution | Count | What to show |
|---|---|---|---|
| iPhone 6.9" (iPhone 16 Pro Max etc.) | 1320 × 2868 | 3-10 | Home + trending; results list; knowledge panel; cite popover; brief |
| iPhone 6.5" (legacy support, may be optional) | 1242 × 2688 | 3-10 | Same content downscaled in simulator |
| iPad Pro 13" (M4) | 2064 × 2752 | 3-10 | Results split-view with sidebar + detail |

Recommended screenshot order (each surface earns its place in the
PRD — show the differentiators first):

1. **Knowledge panel** for a news-trending query (Iran, Iraq, Tom Steyer).
   Shows the news badge, the LLM attribution footer, the hero image.
2. **Search results** with the corner-pill (reading time + difficulty)
   visible.
3. **Trending list** on the home screen.
4. **Cite popover** open with the five citation styles.
5. **Related entities rail** in landscape iPad.
6. **Daily brief** card swipe.

Generate via Xcode's Simulator → Device → Trigger Screenshot. Apple
accepts PNG.

---

## Hosting the privacy policy

App Store Connect requires the privacy policy to be live at a public
URL before you can submit. Two options:

**Option A — render at zettair.io/privacy**

Add a route to `server.py` that returns `PRIVACY_POLICY.md` rendered
as HTML, served under `/privacy`. Simplest path; lives in the
existing server. New endpoint, no new infra.

**Option B — serve as static HTML via Caddy**

`caddy file_server` directive pointing at a directory that contains
a converted `privacy.html`. Avoids a server.py change but requires
a Caddy snippet.

Option A is cleaner because the policy stays version-controlled in
the iOS repo and a small render hook fetches it. Need to coordinate
the server change in `zettair-search` either way.

---

## Submission checklist

- [ ] Apple Developer Program enrolment complete (24-48h after $99
      payment).
- [ ] App ID `io.zettair.app` registered in Developer portal.
- [ ] App Group `group.io.zettair.app` registered (for Widget + Share
      extension).
- [ ] `apple-app-site-association.json` has real Team ID and is
      deployed to `https://zettair.io/.well-known/`.
- [ ] `https://zettair.io/privacy` is live and serves the privacy
      policy.
- [ ] Branch is `main` (not `sideload`) and `xcodegen && xcodebuild`
      passes locally with signing.
- [ ] App icon 1024 × 1024 present in the asset catalogue (regenerate
      via `tools/generate_icon.py`).
- [ ] Screenshots taken for all required device sizes.
- [ ] All fields above are filled into App Store Connect.
- [ ] Build archived in Xcode (Product → Archive) and uploaded.
- [ ] TestFlight internal testing run for at least a week.
- [ ] Submit for App Store review with the App Review Notes attached.
