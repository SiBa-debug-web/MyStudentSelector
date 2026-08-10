import SwiftUI

@main
struct MyStudentSelectorApp: App {
    @StateObject private var store = RosterStore()

    var body: some Scene {
        WindowGroup {
            RosterListView()
                .environmentObject(store)
        }
    }
}
