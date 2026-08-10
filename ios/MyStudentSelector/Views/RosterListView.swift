import SwiftUI

extension Color {
    static let brandIndigo = Color(red: 79 / 255, green: 70 / 255, blue: 229 / 255)
    static let brandViolet = Color(red: 139 / 255, green: 92 / 255, blue: 246 / 255)
}

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [Color.brandIndigo, Color.brandViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct RosterListView: View {
    @EnvironmentObject private var store: RosterStore
    @State private var showAddRoster = false

    private var sortedRosters: [Roster] {
        store.rosters.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.rosters.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(sortedRosters) { roster in
                            NavigationLink(value: roster.id) {
                                RosterRow(roster: roster)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("MyStudentSelector")
            .navigationDestination(for: UUID.self) { rosterId in
                RosterDetailView(rosterId: rosterId)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddRoster = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(LinearGradient.brand)
                    }
                }
            }
            .sheet(isPresented: $showAddRoster) {
                AddRosterSheet(mode: .create) { name in
                    let roster = store.addRoster(name: name)
                    showAddRoster = false
                    return roster.id
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("🎲").font(.system(size: 44))
            Text("No class lists yet").font(.headline)
            Text("Create a roster to start randomly calling on students.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showAddRoster = true
            } label: {
                Text("Create your first class")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.brand)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct RosterRow: View {
    let roster: Roster

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient.brand)
                    .frame(width: 44, height: 44)
                Text(roster.initials)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(roster.name).font(.body.weight(.semibold))
                Text(metaText).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var metaText: String {
        let total = roster.students.count
        let active = roster.presentStudents.count
        var text = "\(total) student\(total == 1 ? "" : "s")"
        if active != total { text += " · \(active) present" }
        return text
    }
}

#Preview {
    RosterListView().environmentObject(RosterStore())
}
