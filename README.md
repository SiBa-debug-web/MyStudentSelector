# MyStudentSelector

This repo holds two small iOS apps. Each one exists as a native SwiftUI app (the primary build) and as a plain web app you can run locally without Xcode.

| App | Native | Web | What it does |
|---|---|---|---|
| **MyStudentSelector** | [`ios/`](ios) | repo root | Randomly picks a student from a class list for cold calling |
| **Convo Notes** | [`convo-notes/ios/`](convo-notes/ios) | [`convo-notes/web/`](convo-notes/web) | Logs conversations with people and nudges you to follow up |

Neither app is hosted on the web. Build the native apps in Xcode, or run a web version locally with `python3 -m http.server`.

---

## MyStudentSelector

Picks a student at random for cold calling, without repeating anyone until the whole class has been called.

- Multiple class rosters, each with its own student list
- No-repeat picker that auto-starts a new round once everyone has been called
- Mark students absent to exclude them from picks without deleting them
- Per-student call counts and a "called this round" indicator
- Add students one at a time or paste a whole list (comma- or newline-separated)
- All data stored on-device — nothing leaves the phone

**Native:** open `ios/MyStudentSelector.xcodeproj` in Xcode — see [`ios/README.md`](ios/README.md).

**Web:** serve the repo root (`python3 -m http.server 8000`) and open `http://localhost:8000`. Files are `index.html`, `styles.css`, `app.js`, plus `manifest.json` / `sw.js` for offline support and `icons/`.

---

## Convo Notes

Records notes on conversations with people — date stamped, location tagged, filterable by suburb — and flags anyone you haven't followed up with in a month. The native build also fires a local notification when a follow-up falls due.

See [`convo-notes/README.md`](convo-notes/README.md) for the full write-up.
