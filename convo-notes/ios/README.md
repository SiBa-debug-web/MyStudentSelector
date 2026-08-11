# Convo Notes (iOS / iPadOS — SwiftUI)

Native universal app for iPhone and iPad. Same feature set as the web build in `../web`, plus real local notifications when a conversation hasn't been followed up for 30 days.

## Requirements

- A Mac with **Xcode 15 or later**
- iOS / iPadOS **16.0+** deployment target

## Opening and running

1. Open `ConvoNotes.xcodeproj` in Xcode.
2. Pick an iPhone or iPad simulator from the destination dropdown and press **⌘R**.

To run on your own device: plug it in, select it as the destination, then under the target's **Signing & Capabilities** tab choose your Apple ID under "Team". A free Apple ID works (the app expires after 7 days and needs re-installing); a paid Apple Developer account removes that limit.

On first launch the app asks permission to send notifications. If you decline, everything still works — you just lose the push reminders and keep the in-app "Follow-up" filter.

## Backups

The **⋯** menu in the people list has **Export backup** and **Import backup**.

Export writes a `convo-notes-backup-YYYY-MM-DD.json` through the system save
sheet, so it can go to Files or iCloud Drive. Import reads one back and asks
whether to **merge** (adds anything missing, keeps what you have, matching on
id so re-importing the same file changes nothing) or **replace**.

Backups are interchangeable with the web build in `../web`: the decoder accepts
that format's key names (`at`, `shortlisted`, `archived`), its lowercase
`followup` kind, its millisecond timestamps, and its non-UUID ids — which are
hashed to fixed UUIDs so identity stays stable across repeated imports. So you
can export from the web app and import here to bring existing notes over.

## Layout

On iPhone it's a normal push-navigation list. On iPad it's a two-column split view: people on the left, the selected person's conversation history on the right.

## Project structure

```
ConvoNotes/
  ConvoNotesApp.swift          — app entry; requests notification permission,
                                 re-syncs reminders when the app foregrounds
  Models/
    Person.swift               — person + category, overdue/follow-up logic
    Conversation.swift         — single conversation entry + kind
  Store/
    PersonStore.swift          — ObservableObject; CRUD + JSON persistence
    ReminderScheduler.swift    — schedules local notifications + app badge
  Views/
    RootView.swift             — NavigationSplitView shell (iPhone + iPad)
    PeopleListView.swift       — list, scope filter, suburb filter, search
    PersonDetailView.swift     — header card + conversation log
    PersonEditSheet.swift      — add / edit a person
    ConversationEditSheet.swift— log / edit a conversation
    Theme.swift                — brand colours, avatar, tag
  Assets.xcassets/             — app icon + accent colour
```

Data is stored as JSON at `Documents/convonotes.json` inside the app's sandbox. Nothing is sent anywhere.

## Notes

- Bundle identifier is `com.sibadebugweb.ConvoNotes` — change it under **Signing & Capabilities** if you want your own.
- Location is a plain text field. The app declares no location permissions and never reads GPS.
- Reminders are scheduled for a date 30 days after a person's most recent conversation. Logging a new conversation reschedules it; archiving cancels it. A follow-up that is *already* overdue when you open the app can't fire a past notification, so those surface in the in-app **Follow-up** filter and the app-icon badge instead.
- **This project has not been compiled.** It was written on Linux with no Mac or Swift toolchain available, so the Xcode project structure was validated programmatically and the Swift reviewed by hand, but not built. Do a build before relying on it; if Xcode reports anything, it should be a small fix.
