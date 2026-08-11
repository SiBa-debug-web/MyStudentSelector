import SwiftUI
import UniformTypeIdentifiers

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

    // Backup
    @State private var showExporter = false
    @State private var exportDocument = BackupDocument(data: Data())
    @State private var showImporter = false
    @State private var pendingImport: [Person] = []
    @State private var showImportChoice = false
    @State private var backupMessage: String?

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
                Menu {
                    Button {
                        startExport()
                    } label: {
                        Label("Export backup…", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showImporter = true
                    } label: {
                        Label("Import backup…", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Backup options")
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
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: BackupCoder.filename()
        ) { result in
            if case .failure = result {
                backupMessage = "Couldn't save the backup."
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { loadBackup(from: url) }
            case .failure:
                backupMessage = "Couldn't open that file."
            }
        }
        .confirmationDialog("Import backup", isPresented: $showImportChoice, titleVisibility: .visible) {
            Button("Merge with my data") {
                let added = store.merge(pendingImport)
                pendingImport = []
                backupMessage = (added.people == 0 && added.conversations == 0)
                    ? "Nothing new to add — already up to date."
                    : "Added \(added.people) \(added.people == 1 ? "person" : "people") and "
                      + "\(added.conversations) conversation\(added.conversations == 1 ? "" : "s")."
            }
            Button("Replace everything", role: .destructive) {
                let count = pendingImport.count
                store.replaceAll(with: pendingImport)
                pendingImport = []
                selection = nil
                backupMessage = "Replaced with \(count) \(count == 1 ? "person" : "people") from the backup."
            }
            Button("Cancel", role: .cancel) { pendingImport = [] }
        } message: {
            Text(importSummary)
        }
        .alert(
            "Backup",
            isPresented: Binding(
                get: { backupMessage != nil },
                set: { if !$0 { backupMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(backupMessage ?? "")
        }
    }

    // MARK: - Backup

    private var importSummary: String {
        let convos = pendingImport.reduce(0) { $0 + $1.conversations.count }
        return "This backup holds \(pendingImport.count) "
            + "\(pendingImport.count == 1 ? "person" : "people") and "
            + "\(convos) conversation\(convos == 1 ? "" : "s"). "
            + "Merge keeps what you already have and adds anything missing. "
            + "Replace deletes your current data first."
    }

    private func startExport() {
        do {
            exportDocument = BackupDocument(data: try store.exportData())
            showExporter = true
        } catch {
            backupMessage = "Couldn't prepare the backup."
        }
    }

    private func loadBackup(from url: URL) {
        // Files hands back a security-scoped URL; without this the read fails.
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let imported = try BackupCoder.decodePeople(from: data)
            guard !imported.isEmpty else {
                backupMessage = "That backup has no people in it."
                return
            }
            pendingImport = imported
            showImportChoice = true
        } catch {
            backupMessage = "That file isn't a Convo Notes backup."
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
