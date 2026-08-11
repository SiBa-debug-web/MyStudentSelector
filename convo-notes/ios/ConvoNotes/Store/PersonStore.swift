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
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Person].self, from: data) {
            people = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(people) else { return }
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
