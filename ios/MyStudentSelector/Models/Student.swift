import Foundation

struct Student: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var isAbsent: Bool = false
    var timesCalled: Int = 0
    var calledThisRound: Bool = false
    var lastCalledAt: Date?

    var subtitle: String {
        if isAbsent { return "Marked absent" }
        if timesCalled == 0 { return "Not called yet" }
        return "Called \(timesCalled) time\(timesCalled == 1 ? "" : "s")"
    }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.isEmpty { return "?" }
        if parts.count == 1 { return String(parts[0].prefix(2)).uppercased() }
        return (String(parts.first!.prefix(1)) + String(parts.last!.prefix(1))).uppercased()
    }
}
