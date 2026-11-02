import XCTest
@testable import StudyPlanner

final class PlannerTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        c.firstWeekday = 1
        return c
    }()

    private func day(_ d: Int, month: Int = 11, year: Int = 2026) -> Date {
        cal.date(from: DateComponents(year: year, month: month, day: d))!
    }

    // MARK: Rollover

    func testRolloverMovesOnlyUndoneTasksFromThePast() {
        var items = [
            Item(title: "undone past", date: day(1)),
            Item(title: "done past", date: day(1), done: true),
            Item(kind: .due, title: "due past", date: day(1)),
            Item(kind: .event, title: "event past", date: day(1)),
            Item(title: "today", date: day(3)),
            Item(title: "future", date: day(5)),
        ]
        XCTAssertTrue(rollover(&items, today: day(3), cal: cal))

        XCTAssertEqual(items[0].date, day(3))
        XCTAssertEqual(items[0].rolledFrom, day(1))
        XCTAssertEqual(items[1].date, day(1)); XCTAssertNil(items[1].rolledFrom)
        XCTAssertEqual(items[2].date, day(1)); XCTAssertNil(items[2].rolledFrom)
        XCTAssertEqual(items[3].date, day(1)); XCTAssertNil(items[3].rolledFrom)
        XCTAssertEqual(items[4].date, day(3)); XCTAssertNil(items[4].rolledFrom)
        XCTAssertEqual(items[5].date, day(5)); XCTAssertNil(items[5].rolledFrom)
    }

    func testRolledFromKeepsTheFirstDay() {
        var items = [Item(title: "a", date: day(1))]
        rollover(&items, today: day(2), cal: cal)
        rollover(&items, today: day(4), cal: cal)
        XCTAssertEqual(items[0].date, day(4))
        XCTAssertEqual(items[0].rolledFrom, day(1))
    }

    func testRolloverIsANoOpWhenNothingIsLate() {
        var items = [Item(title: "a", date: day(2))]
        XCTAssertFalse(rollover(&items, today: day(2), cal: cal))
    }

    // MARK: Repeat expansion

    func testNeverIsJustTheStartDay() {
        XCTAssertEqual(occurrences(from: day(3), rule: .never, until: day(10), cal: cal), [day(3)])
    }

    func testDailyRunsToTheEndInclusive() {
        let d = occurrences(from: day(1), rule: .daily, until: day(10), cal: cal)
        XCTAssertEqual(d.count, 10)
        XCTAssertEqual(d.first, day(1))
        XCTAssertEqual(d.last, day(10))
    }

    func testWeekdaysSkipsWeekends() {
        // Nov 1, 2026 is a Sunday.
        let d = occurrences(from: day(1), rule: .weekdays, until: day(10), cal: cal)
        XCTAssertEqual(d, [day(2), day(3), day(4), day(5), day(6), day(9), day(10)])
        for date in d {
            let wd = cal.component(.weekday, from: date)
            XCTAssertTrue((2...6).contains(wd))
        }
    }

    func testWeeklyEverySevenDays() {
        XCTAssertEqual(occurrences(from: day(1), rule: .weekly, until: day(30), cal: cal),
                       [day(1), day(8), day(15), day(22), day(29)])
    }

    func testRepeatIsCappedAtNinetyDays() {
        let d = occurrences(from: day(1), rule: .daily, until: day(1, month: 12, year: 2027), cal: cal)
        XCTAssertEqual(d.count, 90)
    }

    func testEndBeforeStartStillCreatesOne() {
        XCTAssertEqual(occurrences(from: day(5), rule: .daily, until: day(1), cal: cal), [day(5)])
    }

    // MARK: Segments, counts, red bar

    func testSegmentsOrderBySubjectThenDoneFirst() {
        let a = Subject(name: "A", colorIndex: 0), b = Subject(name: "B", colorIndex: 1)
        let items = [
            Item(title: "b undone", subjectID: b.id, date: day(1)),
            Item(title: "a undone", subjectID: a.id, date: day(1)),
            Item(title: "none", date: day(1)),
            Item(title: "a done", subjectID: a.id, date: day(1), done: true),
            Item(kind: .event, title: "event", date: day(1)),
        ]
        let s = segments(for: items, subjects: [a, b])
        XCTAssertEqual(s, [Segment(colorIndex: 0, done: true), Segment(colorIndex: 0, done: false),
                           Segment(colorIndex: 1, done: false), Segment(colorIndex: nil, done: false)])
    }

    func testTallyExcludesEvents() {
        let items = [Item(title: "t", date: day(1), done: true),
                     Item(kind: .due, title: "d", date: day(1)),
                     Item(kind: .event, title: "e", date: day(1))]
        XCTAssertEqual(tally(items), Tally(done: 1, total: 2))
    }

    func testDueSoonOnlyTodayAndTomorrowAndUndone() {
        let items = [
            Item(kind: .due, title: "yesterday", date: day(9)),
            Item(kind: .due, title: "today", date: day(10), timeMinutes: 17 * 60),
            Item(kind: .due, title: "tomorrow", date: day(11)),
            Item(kind: .due, title: "later", date: day(12)),
            Item(kind: .due, title: "done", date: day(10), done: true),
            Item(title: "task", date: day(10)),
        ]
        XCTAssertEqual(dueSoon(items, today: day(10), cal: cal).map(\.title), ["today", "tomorrow"])
        XCTAssertEqual(dueSoon(items, today: day(11), cal: cal).map(\.title), ["tomorrow"])
    }

    // MARK: Reminders

    func testRemindersNeverInThePastAndCapped() {
        var items: [Item] = []
        for d in 1...28 {
            items.append(Item(title: "t\(d)", date: day(d)))
            items.append(Item(kind: .due, title: "d\(d)", date: day(d)))
        }
        let planner = Planner(name: "P", start: day(1), end: day(28), items: items)
        let now = cal.date(byAdding: .hour, value: 9, to: day(2))!   // 9 AM, after today's 8 AM
        let list = planReminders([planner], now: now, daily: true, due: true, cal: cal)
        XCTAssertLessThanOrEqual(list.count, 60)
        XCTAssertTrue(list.allSatisfy { $0.fire > now })
        XCTAssertEqual(list.map(\.fire), list.map(\.fire).sorted())
    }

    func testDueReminderTitles() {
        let due = Item(kind: .due, title: "PS 3", date: day(10), timeMinutes: 17 * 60)
        let planner = Planner(name: "P", start: day(1), end: day(10), items: [due])
        let list = planReminders([planner], now: day(1), daily: false, due: true, cal: cal)
        XCTAssertEqual(list.map(\.title), ["PS 3 is due tomorrow", "PS 3 is due today"])
    }

    // MARK: Seed and store

    func testSeedHas55StudyTasksOverTenDays() {
        let p = Seed.planner(start: day(1), cal: cal)
        XCTAssertEqual(p.items.count, Seed.taskCount)
        XCTAssertEqual(p.items.count, 55)
        XCTAssertTrue(p.items.allSatisfy { $0.kind == .task && $0.subjectID != nil })
        XCTAssertEqual(p.subjects.map(\.name), ["ECON 139", "STAT 153", "STAT 134"])
        XCTAssertEqual(p.end, day(10))
        XCTAssertTrue(p.items.allSatisfy { $0.date >= day(1) && $0.date <= day(10) })
    }

    @MainActor
    func testStorePersistsAndSurvivesCorruptJSON() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appending(path: "planners.json")

        let store = Store(fileURL: url, reminders: false)
        XCTAssertTrue(store.planners.isEmpty)
        let id = store.createPlanner(name: "Test", start: Date(), end: Date())
        store.add([Item(title: "Read", date: Day.start(Date()))], to: id)
        store.flush()

        let reloaded = Store(fileURL: url, reminders: false)
        XCTAssertEqual(reloaded.planners.first?.name, "Test")
        XCTAssertEqual(reloaded.planners.first?.items.first?.title, "Read")

        try Data("{ not json".utf8).write(to: url)
        let afterCorrupt = Store(fileURL: url, reminders: false)
        XCTAssertTrue(afterCorrupt.planners.isEmpty)
    }

    @MainActor
    func testImportOnlyOnRequest() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
        let store = Store(fileURL: url, reminders: false)
        XCTAssertFalse(store.hasImportedMidterm)
        store.importMidterm()
        XCTAssertTrue(store.hasImportedMidterm)
        XCTAssertEqual(store.planners.first?.items.count, 55)
    }
}
