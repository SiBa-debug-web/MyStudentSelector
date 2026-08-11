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

## The web app

Live at **https://siba-debug-web.github.io/MyStudentSelector/convo-notes/web/**

On an iPhone or iPad, open that link in **Safari**, tap the Share icon, then **Add to Home Screen**. It then runs full-screen like a native app and works offline.

To run it locally instead:

```
cd convo-notes/web
python3 -m http.server 8000
```

Data lives in the browser's `localStorage`, so it is per-device and per-browser.

## The native app

See [`ios/README.md`](ios/README.md) for how to open and run it in Xcode.

## Follow-up timing

The 30-day threshold is defined in one place per build if you want to change it:

- Web: `FOLLOW_UP_DAYS` at the top of `web/app.js`
- Native: `Person.followUpDays` in `ios/ConvoNotes/Models/Person.swift`

The clock runs from the most recent conversation — or, if you have not logged one yet, from the day you added the person.
