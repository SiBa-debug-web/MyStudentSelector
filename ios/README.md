# MyStudentSelector (iOS / SwiftUI)

A native SwiftUI version of MyStudentSelector for iPhone — manage class rosters and randomly pick a student to cold-call, without repeating anyone until the whole class has been called.

This is a from-scratch Xcode project (SwiftUI App lifecycle, no storyboards). It mirrors the feature set of the web version at the repo root, built natively instead.

## Requirements

- A Mac with **Xcode 15 or later**
- iOS 16.0+ deployment target (set in the project)

## Opening the project

1. Open `ios/MyStudentSelector.xcodeproj` in Xcode.
2. Select the `MyStudentSelector` scheme (Xcode creates it automatically on first open) and an iPhone simulator or your own device.
3. Press **Run** (⌘R).

To install on your own iPhone, select your device as the run destination, and sign the app with your Apple ID under **Signing & Capabilities** (Automatic signing is already enabled in the project — you just need to pick your personal team). A free Apple ID is enough to run it on your own device for 7 days at a time; a paid Apple Developer account removes that limit.

## Features

- Multiple class rosters, each with its own student list
- Random picker that won't repeat a student until everyone in the class has been called, then automatically starts a new round
- Swipe a student left to delete, right to mark absent/present
- Per-student call counts, with "called this round" indicator
- Add students one at a time or paste a whole list (comma- or newline-separated)
- All data stored locally on-device (JSON file in the app's Documents directory) — nothing leaves the phone, no accounts or network access

## Project structure

```
MyStudentSelector/
  MyStudentSelectorApp.swift   — app entry point
  Models/
    Student.swift
    Roster.swift
  Store/
    RosterStore.swift          — ObservableObject; CRUD + persistence + picker logic
  Views/
    RosterListView.swift       — list of classes, entry screen
    RosterDetailView.swift     — picker + student list for one class
    StudentRowView.swift
    AddRosterSheet.swift       — create/rename a class
    AddStudentsSheet.swift     — add students (single + bulk paste)
  Assets.xcassets/             — app icon + accent color
```

## Notes

- The bundle identifier is set to `com.sibadebugweb.MyStudentSelector` in the project's build settings — change it under the target's **Signing & Capabilities** tab if you want your own.
- This project was authored and reviewed without access to Xcode (no Mac in the environment it was built in), so it hasn't been compiled. The Swift code was written carefully and reviewed line-by-line, but do a build before relying on it — if Xcode reports an issue, it's most likely a small, easy fix.
