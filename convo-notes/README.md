# Convo Notes

Record notes on conversations with people, and get nudged when you haven't followed up in a month.

Each **person** has a name, a category (man / woman / child), a suburb and an optional street address. Underneath them sits a running log of **conversations** — each one date- and time-stamped, tagged with a location you type in, and marked as either an *initial* conversation or a *follow-up*.

There are two builds of the same app in this folder:

| | Folder | Runs on | Reminders | Map |
|---|---|---|---|---|
| **Web app (PWA)** | [`web/`](web) | iPhone, iPad, any browser — installable to the home screen | In-app "Follow-up" list + badge | Yes |
| **Native app** | [`ios/`](ios) | iPhone + iPad, built in Xcode | Real push notifications after 30 days | Not yet |

## Features

- **Conversation log per person** — add a new entry every time you speak, oldest history preserved
- **Date & time stamped** — defaults to now, editable if you're writing it up later
- **Location per conversation** — typed by hand; neither build reads your device's GPS, so no location permission is requested
- **Address + map** (web build) — give someone a street address and the app looks up where it is and drops a pin. The map screen shows everyone you've addressed, colour-coded like the list and obeying whichever filters are active, so you can see your whole patch or just who's overdue. Drag the pin if the lookup is slightly off.
- **Initial vs follow-up** — the first entry for a person defaults to *initial*, everything after defaults to *follow-up*
- **Suburb filter** — filter your list of people down to one suburb
- **Shortlist** — star anyone for quick follow-up, then filter to just those
- **Archive** — pause a conversation; archived people drop out of the main list and stop generating reminders, and can be resumed any time
- **Follow-up reminders** — anyone with no conversation for 30 days is flagged. The native app also fires a local notification and sets an app-icon badge.
- **Export / import backups** — save all your data to a JSON file and load it back. On iPhone and iPad this opens the share sheet, so the file can go to Files, iCloud Drive or AirDrop. Importing offers *merge* (adds anything missing, keeps what you have) or *replace*. Backups include coordinates, and the two builds can read each other's files.

> **Back up before reinstalling.** Data lives in the browser's local storage, and on iOS removing a home-screen web app usually deletes it. Export first — that's also how you move data between your iPhone and iPad, since the two don't sync.

## What the map sends, and what it doesn't

Your notes, names and conversation history never leave the device — there's still no account and no server holding your data.

Two things do reach the internet, and only in the web build:

- **Address lookup.** When you press *Find on map*, the address text (plus the suburb, to sharpen the result) is sent to [OpenStreetMap's Nominatim geocoder](https://nominatim.openstreetmap.org/) to turn it into coordinates. Nothing else about the person goes with it. The result is stored locally, so each address is only ever looked up when you ask.
- **Map tiles.** The map images themselves are fetched from OpenStreetMap as you pan and zoom.

Both are optional: skip the address field and the app behaves exactly as before. Once a pin is saved it lives in your own data, so pins survive offline — you'll just see a blank grid instead of streets until you're back on a connection.


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
