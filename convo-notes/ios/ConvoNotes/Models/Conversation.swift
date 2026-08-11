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

    // Decoding is deliberately forgiving: every field falls back to a default
    // so a partial or older file still loads, and `at` / "followup" are
    // accepted as aliases so backups from the web build import cleanly.
    enum CodingKeys: String, CodingKey {
        case id, date, kind, location, notes
        case at
    }

    init(id: UUID = UUID(), date: Date = Date(), kind: ConversationKind = .initial,
         location: String = "", notes: String = "") {
        self.id = id
        self.date = date
        self.kind = kind
        self.location = location
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let raw = try? c.decode(String.self, forKey: .id) {
            id = BackupCoder.stableUUID(from: raw)
        } else {
            id = UUID()
        }
        date = (try? c.decode(Date.self, forKey: .date))
            ?? (try? c.decode(Date.self, forKey: .at))
            ?? Date()
        let rawKind = (try? c.decode(String.self, forKey: .kind)) ?? ""
        kind = ConversationKind(rawValue: rawKind)
            ?? (rawKind.lowercased() == "followup" ? .followUp : .initial)
        location = (try? c.decode(String.self, forKey: .location)) ?? ""
        notes = (try? c.decode(String.self, forKey: .notes)) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(kind, forKey: .kind)
        try c.encode(location, forKey: .location)
        try c.encode(notes, forKey: .notes)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "d MMM, h:mm a"
            : "d MMM yyyy, h:mm a"
        return formatter.string(from: date)
    }
}
