import Foundation
import UserNotifications

/// Schedules a local notification for each active person, firing once their
/// follow-up falls due. Everything happens on-device — no server involved.
enum ReminderScheduler {

    private static let prefix = "convonotes.followup."

    static func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    /// Rebuilds the full set of pending reminders from the current people.
    /// Called whenever the store changes, so it must be cheap and idempotent.
    static func sync(people: [Person]) {
        let center = UNUserNotificationCenter.current()

        // Drop only our own requests, so we never clobber anything else.
        center.getPendingNotificationRequests { requests in
            let ours = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            if !ours.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: ours)
            }

            for person in people where !person.isArchived {
                let due = person.followUpDueDate
                // A reminder in the past can't fire; the in-app "Follow-up"
                // filter surfaces those instead.
                guard due > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Time to follow up"
                content.body = "It's been a month since your last conversation with \(person.name)."
                content.sound = .default

                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute], from: due
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: prefix + person.id.uuidString,
                    content: content,
                    trigger: trigger
                )
                center.add(request, withCompletionHandler: nil)
            }
        }

        let overdueCount = people.filter(\.isOverdue).count
        center.setBadgeCount(overdueCount, withCompletionHandler: nil)
    }
}
