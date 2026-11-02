import Foundation

enum ItemKind: String, Codable, CaseIterable { case task, due, event }
enum RepeatRule: String, Codable, CaseIterable { case never, daily, weekdays, weekly }

struct Subject: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var colorIndex: Int          // index into the 6-colour palette
}

struct Item: Identifiable, Codable, Hashable {
    var id = UUID()
    var kind: ItemKind = .task
    var title: String
    var subjectID: UUID? = nil
    var date: Date               // always startOfDay
    var timeMinutes: Int? = nil  // minutes since midnight (due / event)
    var done = false
    var rolledFrom: Date? = nil  // first day it was planned for, if auto-moved
    var remind = true            // due items only
    var seriesID: UUID? = nil    // shared by copies made by a repeat rule

    /// Tasks and due items count toward progress. Events never do.
    var counts: Bool { kind != .event }
}

struct Planner: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var start: Date
    var end: Date
    var subjects: [Subject] = []
    var items: [Item] = []
    /// Set when the planner came from bundled seed data; nil for user-made planners.
    var source: String? = nil
}
