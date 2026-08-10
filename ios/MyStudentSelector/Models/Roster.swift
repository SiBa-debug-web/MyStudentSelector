import Foundation

struct Roster: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var students: [Student] = []

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.isEmpty { return "?" }
        if parts.count == 1 { return String(parts[0].prefix(2)).uppercased() }
        return (String(parts.first!.prefix(1)) + String(parts.last!.prefix(1))).uppercased()
    }

    var presentStudents: [Student] { students.filter { !$0.isAbsent } }
    var calledThisRoundCount: Int { presentStudents.filter { $0.calledThisRound }.count }
}
