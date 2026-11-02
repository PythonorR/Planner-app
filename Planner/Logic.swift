import Foundation

// Pure helpers: no SwiftUI, no state. Everything here is unit-tested.

// MARK: - Dates

enum Day {
    static func start(_ d: Date, cal: Calendar = .current) -> Date { cal.startOfDay(for: d) }

    static func add(_ days: Int, _ d: Date, cal: Calendar = .current) -> Date {
        start(cal.date(byAdding: .day, value: days, to: start(d, cal: cal)) ?? d, cal: cal)
    }

    static func addMonths(_ months: Int, _ d: Date, cal: Calendar = .current) -> Date {
        start(cal.date(byAdding: .month, value: months, to: d) ?? d, cal: cal)
    }

    static func same(_ a: Date, _ b: Date, cal: Calendar = .current) -> Bool {
        cal.isDate(a, inSameDayAs: b)
    }

    /// Whole calendar days from `a` to `b`.
    static func between(_ a: Date, _ b: Date, cal: Calendar = .current) -> Int {
        cal.dateComponents([.day], from: start(a, cal: cal), to: start(b, cal: cal)).day ?? 0
    }

    /// The seven days of the week containing `d`, starting on the locale's first weekday.
    static func week(containing d: Date, cal: Calendar = .current) -> [Date] {
        let first = cal.dateInterval(of: .weekOfYear, for: d)?.start ?? start(d, cal: cal)
        return (0..<7).map { add($0, first, cal: cal) }
    }

    /// Month grid cells: leading blanks (nil), every day of the month, trailing blanks to fill the last row.
    static func monthGrid(containing d: Date, cal: Calendar = .current) -> [Date?] {
        guard let month = cal.dateInterval(of: .month, for: d),
              let count = cal.range(of: .day, in: .month, for: d)?.count else { return [] }
        let lead = (cal.component(.weekday, from: month.start) - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: lead)
        cells += (0..<count).map { Optional(add($0, month.start, cal: cal)) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}

// MARK: - Repeat expansion

/// Dates a repeating task is created on, from `start` up to `end` (inclusive), capped at 90 days.
/// Always returns at least the start day.
func occurrences(from start: Date, rule: RepeatRule, until end: Date, cal: Calendar = .current) -> [Date] {
    let first = Day.start(start, cal: cal)
    guard rule != .never else { return [first] }
    let last = min(Day.start(end, cal: cal), Day.add(89, first, cal: cal))
    var out: [Date] = []
    var day = first
    var index = 0
    while day <= last {
        switch rule {
        case .daily: out.append(day)
        case .weekdays:
            let wd = cal.component(.weekday, from: day)   // 1 = Sunday, 7 = Saturday
            if wd != 1 && wd != 7 { out.append(day) }
        case .weekly: if index % 7 == 0 { out.append(day) }
        case .never: break
        }
        index += 1
        day = Day.add(1, day, cal: cal)
    }
    return out.isEmpty ? [first] : out
}

// MARK: - Rollover

/// Moves every unfinished task dated before `today` to `today`.
/// Keeps the first original day in `rolledFrom`. Done tasks, due items and events never move.
@discardableResult
func rollover(_ items: inout [Item], today: Date, cal: Calendar = .current) -> Bool {
    let t = Day.start(today, cal: cal)
    var changed = false
    for i in items.indices {
        guard items[i].kind == .task, !items[i].done, items[i].date < t else { continue }
        items[i].rolledFrom = items[i].rolledFrom ?? items[i].date
        items[i].date = t
        changed = true
    }
    return changed
}

// MARK: - Counting

struct Tally: Equatable {
    var done: Int
    var total: Int
    var fraction: Double { total == 0 ? 0 : Double(done) / Double(total) }
}

/// Counts tasks and due items. Events are excluded.
func tally(_ items: [Item]) -> Tally {
    let counted = items.filter(\.counts)
    return Tally(done: counted.filter(\.done).count, total: counted.count)
}

/// Undone due items dated today or tomorrow, earliest first.
func dueSoon(_ items: [Item], today: Date, cal: Calendar = .current) -> [Item] {
    let tomorrow = Day.add(1, today, cal: cal)
    return items
        .filter { $0.kind == .due && !$0.done && (Day.same($0.date, today, cal: cal) || Day.same($0.date, tomorrow, cal: cal)) }
        .sorted { ($0.date, $0.timeMinutes ?? -1, $0.title) < ($1.date, $1.timeMinutes ?? -1, $1.title) }
}

// MARK: - Ribbon segments

struct Segment: Hashable {
    var colorIndex: Int?   // nil = no subject
    var done: Bool
}

/// One segment per task, ordered by subject order, then done first. At most `limit`.
func segments(for items: [Item], subjects: [Subject], limit: Int = 7) -> [Segment] {
    let order = Dictionary(subjects.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
    func rank(_ item: Item) -> Int { item.subjectID.flatMap { order[$0] } ?? Int.max }
    let tasks = items.enumerated().filter { $0.element.kind == .task }
    let sorted = tasks.sorted { a, b in
        let ra = rank(a.element), rb = rank(b.element)
        if ra != rb { return ra < rb }
        if a.element.done != b.element.done { return a.element.done }
        return a.offset < b.offset
    }
    return sorted.prefix(limit).map { pair in
        let color = pair.element.subjectID.flatMap { order[$0] }.map { subjects[$0].colorIndex }
        return Segment(colorIndex: color, done: pair.element.done)
    }
}

// MARK: - Day grouping

struct DayGroup: Identifiable {
    enum Kind: Hashable { case dueEvents, subject(UUID), noSubject }
    let kind: Kind
    let title: String
    let colorIndex: Int?
    let items: [Item]
    var id: Kind { kind }
}

extension Planner {
    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : name
    }

    func items(on day: Date, cal: Calendar = .current) -> [Item] {
        items.filter { Day.same($0.date, day, cal: cal) }
    }

    func subject(_ id: UUID?) -> Subject? {
        guard let id else { return nil }
        return subjects.first { $0.id == id }
    }

    /// Display order for one day: "Due & events" by time, then each subject in settings order, then "No subject".
    func groups(on day: Date, cal: Calendar = .current) -> [DayGroup] {
        let all = items(on: day, cal: cal)
        var out: [DayGroup] = []

        let dueEvents = all.filter { $0.kind != .task }
            .sorted { ($0.timeMinutes ?? -1, $0.title) < ($1.timeMinutes ?? -1, $1.title) }
        if !dueEvents.isEmpty {
            out.append(DayGroup(kind: .dueEvents, title: "Due & events", colorIndex: nil, items: dueEvents))
        }

        let tasks = all.filter { $0.kind == .task }
        for s in subjects {
            let t = tasks.filter { $0.subjectID == s.id }
            if !t.isEmpty {
                let title = s.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled subject" : s.name
                out.append(DayGroup(kind: .subject(s.id), title: title, colorIndex: s.colorIndex, items: t))
            }
        }
        let known = Set(subjects.map(\.id))
        let rest = tasks.filter { item in item.subjectID.map { !known.contains($0) } ?? true }
        if !rest.isEmpty {
            out.append(DayGroup(kind: .noSubject, title: "No subject", colorIndex: nil, items: rest))
        }
        return out
    }
}
