import Foundation

enum PersonCategory: String, Codable, CaseIterable, Identifiable {
    case man
    case woman
    case child

    var id: String { rawValue }

    var label: String {
        switch self {
        case .man: return "Man"
        case .woman: return "Woman"
        case .child: return "Child"
        }
    }
}

struct Person: Identifiable, Codable, Hashable {
    /// A conversation is considered overdue once this many days pass with no follow-up.
    static let followUpDays = 30

    var id: UUID = UUID()
    var name: String
    var category: PersonCategory = .man
    var suburb: String = ""
    var isShortlisted: Bool = false
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var conversations: [Conversation] = []

    /// Most recent conversation, falling back to when the person was added.
    var lastActivity: Date {
        conversations.map(\.date).max() ?? createdAt
    }

    var daysSinceActivity: Int {
        Calendar.current.dateComponents([.day], from: lastActivity, to: Date()).day ?? 0
    }

    /// Archived people are paused, so they never count as overdue.
    var isOverdue: Bool {
        !isArchived && daysSinceActivity >= Person.followUpDays
    }

    /// When this person should next be nudged about, if nothing else happens.
    var followUpDueDate: Date {
        Calendar.current.date(byAdding: .day, value: Person.followUpDays, to: lastActivity) ?? lastActivity
    }

    var sortedConversations: [Conversation] {
        conversations.sorted { $0.date > $1.date }
    }

    var initials: String {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        if parts.isEmpty { return "?" }
        if parts.count == 1 { return String(parts[0].prefix(2)).uppercased() }
        return (String(parts.first!.prefix(1)) + String(parts.last!.prefix(1))).uppercased()
    }

    var activitySummary: String {
        let gap = Self.describeGap(days: daysSinceActivity)
        if conversations.isEmpty {
            return "No conversations yet · added \(gap)"
        }
        let count = conversations.count
        return "\(count) conversation\(count == 1 ? "" : "s") · last \(gap)"
    }

    static func describeGap(days: Int) -> String {
        if days <= 0 { return "today" }
        if days == 1 { return "yesterday" }
        if days < 30 { return "\(days) days ago" }
        let months = days / 30
        return months == 1 ? "over a month ago" : "\(months) months ago"
    }
}
