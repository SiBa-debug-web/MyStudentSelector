import Foundation

@MainActor
final class PersonStore: ObservableObject {
    @Published var people: [Person] = [] {
        didSet {
            guard !isLoading else { return }
            save()
            ReminderScheduler.sync(people: people)
        }
    }

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("convonotes.json")
    }()

    private var isLoading = false

    init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        isLoading = true
        defer { isLoading = false }
        guard let data = try? Data(contentsOf: fileURL) else { return }
        // Same coder as backups, so the store also tolerates timestamps with
        // fractional seconds and older/partial records.
        if let decoded = try? BackupCoder.decoder.decode([Person].self, from: data) {
            people = decoded
        }
    }

    private func save() {
        guard let data = try? BackupCoder.encoder.encode(people) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Lookups

    func person(id: UUID) -> Person? {
        people.first { $0.id == id }
    }

    private func index(of id: UUID) -> Int? {
        people.firstIndex { $0.id == id }
    }

    /// Every distinct suburb currently in use, for the filter menu.
    var suburbs: [String] {
        let all = people.map { $0.suburb.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return Array(Set(all)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Previously used conversation locations, offered as suggestions.
    var knownLocations: [String] {
        let all = people
            .flatMap(\.conversations)
            .map { $0.location.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return Array(Set(all)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var shortlistedCount: Int { people.filter { !$0.isArchived && $0.isShortlisted }.count }
    var overdueCount: Int { people.filter(\.isOverdue).count }

    // MARK: - People

    @discardableResult
    func addPerson(name: String, category: PersonCategory, suburb: String) -> Person {
        let person = Person(name: name, category: category, suburb: suburb)
        people.append(person)
        return person
    }

    func updatePerson(id: UUID, name: String, category: PersonCategory, suburb: String) {
        guard let idx = index(of: id) else { return }
        people[idx].name = name
        people[idx].category = category
        people[idx].suburb = suburb
    }

    func deletePerson(id: UUID) {
        people.removeAll { $0.id == id }
    }

    func toggleShortlist(id: UUID) {
        guard let idx = index(of: id) else { return }
        people[idx].isShortlisted.toggle()
    }

    func toggleArchive(id: UUID) {
        guard let idx = index(of: id) else { return }
        people[idx].isArchived.toggle()
    }

    // MARK: - Backup

    func exportData() throws -> Data {
        let payload = BackupPayload(
            app: "convo-notes",
            version: 1,
            exportedAt: Date(),
            people: people
        )
        return try BackupCoder.encoder.encode(payload)
    }

    func replaceAll(with incoming: [Person]) {
        people = incoming
    }

    /// Adds people we haven't seen and tops up existing ones with any
    /// conversations they're missing, matching on id. Re-importing the same
    /// file is therefore a no-op, and local edits always win.
    @discardableResult
    func merge(_ incoming: [Person]) -> (people: Int, conversations: Int) {
        // Mutate a copy so the whole import is one publish + one save.
        var updated = people
        var indexByID: [UUID: Int] = [:]
        for (offset, person) in updated.enumerated() {
            indexByID[person.id] = offset
        }

        var addedPeople = 0
        var addedConversations = 0

        for person in incoming {
            guard let idx = indexByID[person.id] else {
                updated.append(person)
                indexByID[person.id] = updated.count - 1
                addedPeople += 1
                continue
            }
            var seen = Set(updated[idx].conversations.map(\.id))
            for conversation in person.conversations where !seen.contains(conversation.id) {
                updated[idx].conversations.append(conversation)
                seen.insert(conversation.id)
                addedConversations += 1
            }
        }

        people = updated
        return (addedPeople, addedConversations)
    }

    // MARK: - Conversations

    /// A person's first entry defaults to "initial"; everything after is a follow-up.
    func defaultKind(for personID: UUID) -> ConversationKind {
        guard let person = person(id: personID) else { return .initial }
        return person.conversations.isEmpty ? .initial : .followUp
    }

    func addConversation(to personID: UUID, conversation: Conversation) {
        guard let idx = index(of: personID) else { return }
        people[idx].conversations.append(conversation)
    }

    func updateConversation(personID: UUID, conversation: Conversation) {
        guard let idx = index(of: personID),
              let cIdx = people[idx].conversations.firstIndex(where: { $0.id == conversation.id })
        else { return }
        people[idx].conversations[cIdx] = conversation
    }

    func deleteConversation(personID: UUID, conversationID: UUID) {
        guard let idx = index(of: personID) else { return }
        people[idx].conversations.removeAll { $0.id == conversationID }
    }
}
