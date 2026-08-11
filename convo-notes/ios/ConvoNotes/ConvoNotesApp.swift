import SwiftUI

@main
struct ConvoNotesApp: App {
    @StateObject private var store = PersonStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task {
                    ReminderScheduler.requestAuthorization()
                }
        }
        .onChange(of: scenePhase) { phase in
            // Overdue status is time-based, so refresh reminders and the app
            // badge whenever we come back to the foreground.
            if phase == .active {
                Task { @MainActor in
                    ReminderScheduler.sync(people: store.people)
                }
            }
        }
    }
}
