# Convo Notes

Record notes on conversations with people, and get nudged when you haven't followed up in a month.

Each **person** has a name, a category (man / woman / child) and a suburb. Underneath them sits a running log of **conversations** — each one date- and time-stamped, tagged with a location you type in, and marked as either an *initial* conversation or a *follow-up*.

There are two builds of the same app in this folder:

| | Folder | Runs on | Reminders |
|---|---|---|---|
| **Web app (PWA)** | [`web/`](web) | iPhone, iPad, any browser — installable to the home screen | In-app "Follow-up" list + badge |
| **Native app** | [`ios/`](ios) | iPhone + iPad, built in Xcode | Real push notifications after 30 days |

## Features

- **Conversation log per person** — add a new entry every time you speak, oldest history preserved
- **Date & time stamped** — defaults to now, editable if you're writing it up later
- **Location per conversation** — typed by hand; neither build ever reads your device's GPS, so no location permission is requested
- **Initial vs follow-up** — the first entry for a person defaults to *initial*, everything after defaults to *follow-up*
- **Suburb filter** — filter your list of people down to one suburb
- **Shortlist** — star anyone for quick follow-up, then filter to just those
- **Archive** — pause a conversation; archived people drop out of the main list and stop generating reminders, and can be resumed any time
- **Follow-up reminders** — anyone with no conversation for 30 days is flagged. The native app also fires a local notification and sets an app-icon badge.
- **Everything stays on the device** — no accounts, no server, no network calls
- **Export / import backups** (web build) — save all your data to a JSON file and load it back. On iPhone and iPad this opens the share sheet, so the file can go to Files, iCloud Drive or AirDrop. Importing offers *merge* (adds anything missing, keeps what you have) or *replace*.

> **Back up before reinstalling.** Data lives in the browser's local storage, and on iOS removing a home-screen web app usually deletes it. Export first — that's also how you move data between your iPhone and iPad, since the two don't sync.

## The native app — start here

This is the primary build. See [`ios/README.md`](ios/README.md) for how to open and run it in Xcode.

## The web app

Not hosted anywhere — it's kept in the repo as a quick way to try the app without Xcode. Run it locally:

```
cd convo-notes/web
python3 -m http.server 8000
```

then open `http://localhost:8000` in a browser.

If you ever do want it on a phone, host the `web/` folder on any static host over HTTPS (GitHub Pages, Netlify, Cloudflare Pages), open the URL in Safari, and tap Share → **Add to Home Screen**.

Data lives in the browser's `localStorage`, so it is per-device and per-browser, and entirely separate from the native app's data.

## Follow-up timing

The 30-day threshold is defined in one place per build if you want to change it:

- Web: `FOLLOW_UP_DAYS` at the top of `web/app.js`
- Native: `Person.followUpDays` in `ios/ConvoNotes/Models/Person.swift`

The clock runs from the most recent conversation — or, if you have not logged one yet, from the day you added the person.
