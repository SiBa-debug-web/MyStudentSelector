import Foundation

enum ConversationKind: String, Codable, CaseIterable, Identifiable {
    case initial
    case followUp

    var id: String { rawValue }

    var label: String {
        switch self {
        case .initial: return "Initial"
        case .followUp: return "Follow-up"
        }
    }
}

struct Conversation: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var kind: ConversationKind = .initial
    /// Free-text location, typed by hand — the app never reads GPS.
    var location: String = ""
    var notes: String = ""

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "d MMM, h:mm a"
            : "d MMM yyyy, h:mm a"
        return formatter.string(from: date)
    }
}
