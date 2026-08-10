import Foundation

@MainActor
final class RosterStore: ObservableObject {
    @Published var rosters: [Roster] = [] {
        didSet { save() }
    }

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("rosters.json")
    }()

    private var isLoading = false

    init() {
        load()
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Roster].self, from: data) {
            rosters = decoded
        }
    }

    private func save() {
        guard !isLoading else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(rosters) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Roster CRUD

    @discardableResult
    func addRoster(name: String) -> Roster {
        let roster = Roster(name: name)
        rosters.append(roster)
        return roster
    }

    func renameRoster(id: UUID, name: String) {
        guard let idx = rosters.firstIndex(where: { $0.id == id }) else { return }
        rosters[idx].name = name
    }

    func deleteRoster(id: UUID) {
        rosters.removeAll { $0.id == id }
    }

    // MARK: - Student CRUD

    @discardableResult
    func addStudents(rosterId: UUID, names: [String]) -> Int {
        guard let idx = rosters.firstIndex(where: { $0.id == rosterId }) else { return 0 }
        var existingLower = Set(rosters[idx].students.map { $0.name.lowercased() })
        var added = 0
        for rawName in names {
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !existingLower.contains(name.lowercased()) else { continue }
            rosters[idx].students.append(Student(name: name))
            existingLower.insert(name.lowercased())
            added += 1
        }
        return added
    }

    func deleteStudent(rosterId: UUID, studentId: UUID) {
        guard let idx = rosters.firstIndex(where: { $0.id == rosterId }) else { return }
        rosters[idx].students.removeAll { $0.id == studentId }
    }

    func toggleAbsent(rosterId: UUID, studentId: UUID) {
        guard let rIdx = rosters.firstIndex(where: { $0.id == rosterId }),
              let sIdx = rosters[rIdx].students.firstIndex(where: { $0.id == studentId }) else { return }
        rosters[rIdx].students[sIdx].isAbsent.toggle()
        if rosters[rIdx].students[sIdx].isAbsent {
            rosters[rIdx].students[sIdx].calledThisRound = false
        }
    }

    // MARK: - Picking

    struct PickResult {
        let student: Student
        let startedNewRound: Bool
    }

    func pickStudent(rosterId: UUID) -> PickResult? {
        guard let idx = rosters.firstIndex(where: { $0.id == rosterId }) else { return nil }
        let present = rosters[idx].students.indices.filter { !rosters[idx].students[$0].isAbsent }
        guard !present.isEmpty else { return nil }

        var eligible = present.filter { !rosters[idx].students[$0].calledThisRound }
        var startedNewRound = false
        if eligible.isEmpty {
            for i in present { rosters[idx].students[i].calledThisRound = false }
            eligible = present
            startedNewRound = true
        }

        guard let chosenIndex = eligible.randomElement() else { return nil }
        rosters[idx].students[chosenIndex].calledThisRound = true
        rosters[idx].students[chosenIndex].timesCalled += 1
        rosters[idx].students[chosenIndex].lastCalledAt = Date()

        return PickResult(student: rosters[idx].students[chosenIndex], startedNewRound: startedNewRound)
    }

    func startNewRound(rosterId: UUID) {
        guard let idx = rosters.firstIndex(where: { $0.id == rosterId }) else { return }
        for i in rosters[idx].students.indices {
            rosters[idx].students[i].calledThisRound = false
        }
    }

    func resetStats(rosterId: UUID) {
        guard let idx = rosters.firstIndex(where: { $0.id == rosterId }) else { return }
        for i in rosters[idx].students.indices {
            rosters[idx].students[i].timesCalled = 0
            rosters[idx].students[i].calledThisRound = false
            rosters[idx].students[i].lastCalledAt = nil
        }
    }

    func roster(id: UUID) -> Roster? {
        rosters.first { $0.id == id }
    }
}
