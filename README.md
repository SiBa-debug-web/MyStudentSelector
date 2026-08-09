# MyStudentSelector

A mobile web app for randomly picking students from a class list for cold calling — installs to an iPhone home screen like a native app, works offline, and needs no App Store or Mac/Xcode.

## Features

- Multiple class rosters, each with its own student list
- Random picker that won't repeat a student until everyone in the class has been called, then automatically starts a new round
- Mark students absent to exclude them from picks without deleting them
- Per-student call counts and "called this round" indicator
- Add students one at a time or paste a whole list (comma- or newline-separated)
- All data stored locally on-device (localStorage) — nothing leaves the phone
- Installable as a standalone app via Safari's "Add to Home Screen," with offline support via a service worker

## Installing on an iPhone

1. Host the contents of this folder somewhere reachable over HTTPS (GitHub Pages, Netlify, Vercel, etc. all work with static files).
2. Open the URL in Safari on the iPhone.
3. Tap the Share icon, then **Add to Home Screen**.
4. Launch it from the home screen — it opens full-screen, like a native app.

## Local development

No build step. Serve the folder with any static file server, e.g.:

```
python3 -m http.server 8000
```

Then open `http://localhost:8000` in a browser.

## Files

- `index.html` — app markup
- `styles.css` — styling (dark/light aware, iPhone safe-area aware)
- `app.js` — app logic (roster/student CRUD, picker, persistence)
- `manifest.json` — PWA manifest
- `sw.js` — service worker for offline caching
- `icons/` — app icons
