import Foundation

/// The bundled "Midterm Sprint" plan. Imported only when the user taps the import button.
/// `day` is an offset from the planner's start date; `subject` indexes `subjects`.
/// All 55 entries are plain study tasks (none is a due date).
/// NOTE: placeholder titles. Replace the "tasks" list with the real plan, keeping the same shape.
enum Seed {
    static let source = "midterm-sprint"
    static let taskCount = 55

    /// Nov 1, 2026 in the device time zone.
    static var defaultStart: Date {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = .current
        let d = gregorian.date(from: DateComponents(year: 2026, month: 11, day: 1)) ?? Date()
        return Calendar.current.startOfDay(for: d)
    }

    static let json = """
    {"subjects": [{"name": "ECON 139", "color": 0}, {"name": "STAT 153", "color": 1}, {"name": "STAT 134", "color": 2}],
    "tasks": [
      {"day": 0, "subject": 0, "title": "Lecture 13 notes"},
      {"day": 0, "subject": 1, "title": "Lecture 12 slides"},
      {"day": 0, "subject": 2, "title": "Ch 4 reading"},
      {"day": 0, "subject": 0, "title": "Lecture 14 notes"},
      {"day": 0, "subject": 1, "title": "ACF / PACF examples"},
      {"day": 0, "subject": 2, "title": "Ch 4 exercises"},
      {"day": 1, "subject": 0, "title": "Reread chapter 7"},
      {"day": 1, "subject": 1, "title": "Lecture 13 slides"},
      {"day": 1, "subject": 2, "title": "Ch 5 reading"},
      {"day": 1, "subject": 0, "title": "Definitions flashcards"},
      {"day": 1, "subject": 1, "title": "Stationarity proofs"},
      {"day": 1, "subject": 2, "title": "HW 5 review"},
      {"day": 2, "subject": 0, "title": "PS 2 solutions review"},
      {"day": 2, "subject": 1, "title": "HW 3 review"},
      {"day": 2, "subject": 2, "title": "Ch 5 exercises"},
      {"day": 2, "subject": 0, "title": "Lecture 15 notes"},
      {"day": 2, "subject": 1, "title": "Lecture 14 slides"},
      {"day": 3, "subject": 2, "title": "Joint densities practice"},
      {"day": 3, "subject": 0, "title": "Section worksheet 6"},
      {"day": 3, "subject": 1, "title": "AR(p) derivations"},
      {"day": 3, "subject": 2, "title": "Ch 6 reading"},
      {"day": 3, "subject": 0, "title": "Reread chapter 8"},
      {"day": 3, "subject": 1, "title": "Lab 5 code walkthrough"},
      {"day": 4, "subject": 2, "title": "Quiz 3 review"},
      {"day": 4, "subject": 0, "title": "Quiz 1 review"},
      {"day": 4, "subject": 1, "title": "MA(q) derivations"},
      {"day": 4, "subject": 2, "title": "Ch 6 exercises"},
      {"day": 4, "subject": 0, "title": "Lecture 16 notes"},
      {"day": 5, "subject": 1, "title": "Lecture 15 slides"},
      {"day": 5, "subject": 2, "title": "Change of variables practice"},
      {"day": 5, "subject": 0, "title": "Key graphs from memory"},
      {"day": 5, "subject": 1, "title": "ARMA identification"},
      {"day": 5, "subject": 2, "title": "HW 6 review"},
      {"day": 5, "subject": 0, "title": "PS 3 review"},
      {"day": 6, "subject": 1, "title": "HW 4 review"},
      {"day": 6, "subject": 2, "title": "Expectation & variance drills"},
      {"day": 6, "subject": 0, "title": "Section worksheet 7"},
      {"day": 6, "subject": 1, "title": "Lab 6 code walkthrough"},
      {"day": 6, "subject": 2, "title": "Conditional distributions"},
      {"day": 7, "subject": 0, "title": "Quiz 2 review"},
      {"day": 7, "subject": 1, "title": "Forecasting formulas"},
      {"day": 7, "subject": 2, "title": "Distribution cheat sheet"},
      {"day": 7, "subject": 0, "title": "Practice midterm A"},
      {"day": 7, "subject": 1, "title": "Spectral basics"},
      {"day": 7, "subject": 2, "title": "Practice midterm (Fall 24)"},
      {"day": 8, "subject": 0, "title": "Practice midterm B"},
      {"day": 8, "subject": 1, "title": "Practice midterm 1"},
      {"day": 8, "subject": 2, "title": "Practice midterm (Spring 25)"},
      {"day": 8, "subject": 0, "title": "Mistakes from practice midterms"},
      {"day": 8, "subject": 1, "title": "Practice midterm 2"},
      {"day": 9, "subject": 2, "title": "Redo missed problems"},
      {"day": 9, "subject": 0, "title": "Midterm review sheet"},
      {"day": 9, "subject": 1, "title": "Formula sheet"},
      {"day": 9, "subject": 2, "title": "Midterm review sheet"},
      {"day": 9, "subject": 1, "title": "Final read-through"}
    ]}
    """

    private struct File: Decodable {
        struct S: Decodable { let name: String; let color: Int }
        struct T: Decodable { let day: Int; let subject: Int; let title: String }
        let subjects: [S]
        let tasks: [T]
    }

    static func planner(name: String = "Midterm Sprint", start: Date = defaultStart,
                        cal: Calendar = .current) -> Planner {
        let s = Day.start(start, cal: cal)
        guard let file = try? JSONDecoder().decode(File.self, from: Data(json.utf8)) else {
            return Planner(name: name, start: s, end: s)
        }
        let subjects = file.subjects.map { Subject(name: $0.name, colorIndex: $0.color) }
        let items = file.tasks.map { t in
            Item(title: t.title,
                 subjectID: subjects.indices.contains(t.subject) ? subjects[t.subject].id : nil,
                 date: Day.add(t.day, s, cal: cal))
        }
        let lastDay = file.tasks.map(\.day).max() ?? 0
        return Planner(name: name, start: s, end: Day.add(lastDay, s, cal: cal),
                       subjects: subjects, items: items, source: source)
    }
}
