import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: PersonStore
    @State private var selection: UUID?

    var body: some View {
        NavigationSplitView {
            PeopleListView(selection: $selection)
        } detail: {
            NavigationStack {
                if let selection, store.person(id: selection) != nil {
                    PersonDetailView(personID: selection)
                } else {
                    placeholder
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    /// Shown in the iPad detail pane when nothing is selected.
    private var placeholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(LinearGradient.brand)
            Text("Select a person")
                .font(.headline)
            Text("Their conversation history will show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
