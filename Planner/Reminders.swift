import Foundation
import UserNotifications

struct Reminder: Equatable {
    let id: String
    let title: String
    let body: String
    let fire: Date
}

/// Builds the full list of local notifications to schedule. Pure, so it can be tested.
/// - Daily plan at 8:00 AM for each of the next 14 days that has undone tasks.
/// - For undone due items with `remind`: 8:00 AM the day before and on the due day.
/// Never in the past, never more than `limit`.
func planReminders(_ planners: [Planner], now: Date, daily: Bool, due: Bool,
                   cal: Calendar = .current, limit: Int = 60) -> [Reminder] {
    var out: [Reminder] = []
    let today = Day.start(now, cal: cal)
    let all = planners.flatMap(\.items)
    func eight(_ d: Date) -> Date? { cal.date(bySettingHour: 8, minute: 0, second: 0, of: d) }

    if daily {
        var firstFireDay = true
        for k in 0..<14 {
            let day = Day.add(k, today, cal: cal)
            guard let fire = eight(day), fire > now else { continue }
            // On the first day we notify about, unfinished earlier tasks will have rolled onto it.
            let tasks = all.filter {
                $0.kind == .task && !$0.done &&
                (Day.same($0.date, day, cal: cal) || (firstFireDay && $0.date < day))
            }
            firstFireDay = false
            guard !tasks.isEmpty else { continue }
            let n = tasks.count
            out.append(Reminder(id: "daily-\(k)",
                                title: "Today · \(n) \(n == 1 ? "task" : "tasks")",
                                body: tasks.prefix(3).map(\.title).joined(separator: " · "),
                                fire: fire))
        }
    }

    if due {
        for item in all where item.kind == .due && !item.done && item.remind {
            for (offset, word) in [(-1, "tomorrow"), (0, "today")] {
                guard let fire = eight(Day.add(offset, item.date, cal: cal)), fire > now else { continue }
                var body = Fmt.weekdayMonthDay(item.date)
                if let m = item.timeMinutes { body += " · " + Fmt.time(m) }
                out.append(Reminder(id: "due-\(item.id.uuidString)-\(word)",
                                    title: "\(item.title) is due \(word)",
                                    body: body, fire: fire))
            }
        }
    }

    return Array(out.sorted { $0.fire < $1.fire }.prefix(limit))
}

enum Notifier {
    /// Asks for permission once (first launch). Calls `then` after the user answers.
    static func requestPermissionOnce(then: @escaping @Sendable () -> Void) {
        let key = "askedNotificationPermission"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in then() }
    }

    /// Removes every pending request and schedules `reminders` instead.
    static func replaceAll(with reminders: [Reminder], cal: Calendar = .current) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for r in reminders {
            let content = UNMutableNotificationContent()
            content.title = r.title
            content.body = r.body
            content.sound = .default
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: r.fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: r.id, content: content, trigger: trigger))
        }
    }
}
