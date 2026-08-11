import SwiftUI

enum PeopleScope: String, CaseIterable, Identifiable {
    case active
    case shortlist
    case followUp
    case archived

    var id: String { rawValue }

    var label: String {
        switch self {
        case .active: return "Active"
        case .shortlist: return "Shortlist"
        case .followUp: return "Follow-up"
        case .archived: return "Archived"
        }
    }
}

struct PeopleListView: View {
    @EnvironmentObject private var store: PersonStore
    @Binding var selection: UUID?

    @State private var search = ""
    @State private var scope: PeopleScope = .active
    @State private var suburbFilter: String? = nil
    @State private var showAddPerson = false

    private var filteredPeople: [Person] {
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()

        var list = store.people.filter { person in
            switch scope {
            case .active where person.isArchived: return false
            case .shortlist where person.isArchived || !person.isShortlisted: return false
            case .followUp where !person.isOverdue: return false
            case .archived where !person.isArchived: return false
            default: break
            }
            if let suburbFilter,
               person.suburb.compare(suburbFilter, options: .caseInsensitive) != .orderedSame {
                return false
            }
            if !query.isEmpty, !person.name.lowercased().contains(query) {
                return false
            }
            return true
        }

        if scope == .followUp {
            list.sort { $0.lastActivity < $1.lastActivity }   // most overdue first
        } else {
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $scope) {
                ForEach(PeopleScope.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            if store.overdueCount > 0 && scope != .followUp {
                Button {
                    scope = .followUp
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.badge.exclamationmark")
                        Text(store.overdueCount == 1
                             ? "1 person needs a follow-up"
                             : "\(store.overdueCount) people need a follow-up")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            List(selection: $selection) {
                ForEach(filteredPeople) { person in
                    PersonRow(person: person).tag(person.id)
                }
            }
            .listStyle(.plain)
            .overlay {
                if filteredPeople.isEmpty {
                    emptyState
                }
            }
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search by name")
        .navigationTitle("Convo Notes")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("Suburb", selection: $suburbFilter) {
                        Text("All suburbs").tag(String?.none)
                        ForEach(store.suburbs, id: \.self) { suburb in
                            Text(suburb).tag(String?.some(suburb))
                        }
                    }
                } label: {
                    Label(suburbFilter ?? "All suburbs", systemImage: "line.3.horizontal.decrease.circle")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddPerson = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(LinearGradient.brand)
                }
                .accessibilityLabel("Add person")
            }
        }
        .sheet(isPresented: $showAddPerson) {
            PersonEditSheet(person: nil) { name, category, suburb in
                let person = store.addPerson(name: name, category: category, suburb: suburb)
                selection = person.id
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("💬").font(.system(size: 40))
            Text(emptyTitle).font(.headline)
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            if store.people.isEmpty {
                Button("Add your first person") { showAddPerson = true }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brandTeal)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var emptyTitle: String {
        if store.people.isEmpty { return "No people yet" }
        switch scope {
        case .active: return "No active people match"
        case .shortlist: return "Nobody shortlisted"
        case .followUp: return "Nothing overdue"
        case .archived: return "Nothing archived"
        }
    }

    private var emptyMessage: String {
        if store.people.isEmpty {
            return "Add someone to start recording your conversations with them."
        }
        switch scope {
        case .active: return "Try clearing the search or suburb filter."
        case .shortlist: return "Star someone to keep them handy for a quick follow-up."
        case .followUp: return "Everyone has been followed up within the last \(Person.followUpDays) days."
        case .archived: return "Archived people are paused conversations you can resume later."
        }
    }
}

struct PersonRow: View {
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(person: person)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(person.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    if person.isShortlisted && !person.isArchived {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                    if person.isOverdue {
                        TagView(text: "Follow up", color: .orange)
                    }
                    if person.isArchived {
                        TagView(text: "Archived", color: .secondary)
                    }
                }
                Text(metaLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(person.activitySummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .opacity(person.isArchived ? 0.65 : 1)
    }

    private var metaLine: String {
        person.suburb.isEmpty ? person.category.label : "\(person.category.label) · \(person.suburb)"
    }
}
