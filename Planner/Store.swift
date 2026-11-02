import Foundation
import Combine

/// Owns all planners: persistence (planners.json), rollover, notifications and every mutation.
/// Storage is private to this class so it can later be swapped for SwiftData.
@MainActor
final class Store: ObservableObject {
    @Published private(set) var planners: [Planner] = []
    @Published private(set) var today: Date = Day.start(Date())

    private let fileURL: URL
    private let remindersEnabled: Bool
    private let io = DispatchQueue(label: "planner.store.io")
    private var reminderTask: Task<Void, Never>?

    nonisolated static var defaultURL: URL {
        URL.documentsDirectory.appending(path: "planners.json")
    }

    init(fileURL: URL = Store.defaultURL, reminders: Bool = true) {
        self.fileURL = fileURL
        self.remindersEnabled = reminders
        planners = Store.load(from: fileURL)
        if rolloverAll() { persist() }      // before the first frame is drawn
    }

    // MARK: Loading and saving

    /// Missing file → empty list. Unreadable file → moved aside (kept, not deleted) and empty list.
    nonisolated static func load(from url: URL) -> [Planner] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let planners = try? decoder.decode([Planner].self, from: data) { return planners }
        let backup = url.deletingLastPathComponent()
            .appending(path: "planners-unreadable-\(Int(Date().timeIntervalSince1970)).json")
        try? FileManager.default.moveItem(at: url, to: backup)
        return []
    }

    private func persist() {
        let snapshot = planners
        let url = fileURL
        io.async {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            do {
                try encoder.encode(snapshot).write(to: url, options: .atomic)
            } catch {
                print("Planner: save failed: \(error)")
            }
        }
    }

    /// Waits for pending writes (used by tests).
    func flush() { io.sync {} }

    // MARK: Lifecycle

    func launched() {
        if remindersEnabled {
            Notifier.requestPermissionOnce { [weak self] in
                Task { @MainActor in self?.scheduleNotifications(immediately: true) }
            }
        }
        becameActive()
    }

    /// Launch, return to foreground, and midnight while open.
    func becameActive() {
        refreshToday()
        if rolloverAll() { persist() }
        scheduleNotifications(immediately: true)
    }

    private func refreshToday() {
        let now = Day.start(Date())
        if now != today { today = now }
    }

    private func rolloverAll() -> Bool {
        var changed = false
        for i in planners.indices {
            if rollover(&planners[i].items, today: today) { changed = true }
        }
        return changed
    }

    // MARK: Reading

    func planner(_ id: UUID) -> Planner? { planners.first { $0.id == id } }

    var hasImportedMidterm: Bool { planners.contains { $0.source == Seed.source } }

    // MARK: Mutations (each one saves)

    /// Planner settings: name, dates, subjects. Items are left alone.
    func update(_ p: Planner) {
        mutate(p.id) {
            let start = Day.start(p.start)
            $0.name = p.name
            $0.start = start
            $0.end = max(Day.start(p.end), start)
            $0.subjects = p.subjects
        }
    }

    func add(_ items: [Item], to plannerID: UUID) {
        mutate(plannerID) { $0.items += items }
    }

    func save(_ item: Item, in plannerID: UUID) {
        mutate(plannerID) { p in
            if let i = p.items.firstIndex(where: { $0.id == item.id }) { p.items[i] = item }
        }
    }

    func delete(_ itemID: UUID, in plannerID: UUID) {
        mutate(plannerID) { $0.items.removeAll { $0.id == itemID } }
    }

    func toggle(_ itemID: UUID, in plannerID: UUID) {
        mutate(plannerID) { p in
            if let i = p.items.firstIndex(where: { $0.id == itemID }), p.items[i].kind != .event {
                p.items[i].done.toggle()
            }
        }
    }

    @discardableResult
    func createPlanner(name: String, start: Date, end: Date, subjects: [Subject] = [],
                       items: [Item] = [], source: String? = nil) -> UUID {
        let s = Day.start(start)
        let p = Planner(name: name, start: s, end: max(Day.start(end), s),
                        subjects: subjects, items: items, source: source)
        planners.append(p)
        changed()
        return p.id
    }

    func deletePlanner(_ id: UUID) {
        planners.removeAll { $0.id == id }
        changed()
    }

    /// Only ever called from a button tap, never on launch.
    @discardableResult
    func importMidterm(name: String = "Midterm Sprint", start: Date = Seed.defaultStart, end: Date? = nil) -> UUID {
        let seeded = Seed.planner(name: name, start: start)
        return createPlanner(name: name, start: seeded.start, end: max(end ?? seeded.end, seeded.end),
                             subjects: seeded.subjects, items: seeded.items, source: Seed.source)
    }

    private func mutate(_ id: UUID, _ body: (inout Planner) -> Void) {
        guard let i = planners.firstIndex(where: { $0.id == id }) else { return }
        body(&planners[i])
        changed()
    }

    private func changed() {
        refreshToday()
        _ = rolloverAll()
        persist()
        scheduleNotifications()
    }

    // MARK: Notifications

    /// Rebuilds all pending notifications. Debounced ~0.8 s unless `immediately`.
    func scheduleNotifications(immediately: Bool = false) {
        guard remindersEnabled else { return }
        reminderTask?.cancel()
        reminderTask = Task { [weak self] in
            if !immediately { try? await Task.sleep(nanoseconds: 800_000_000) }
            guard !Task.isCancelled, let self else { return }
            let defaults = UserDefaults.standard
            let list = planReminders(self.planners, now: Date(),
                                     daily: defaults.object(forKey: "dailyReminder") as? Bool ?? true,
                                     due: defaults.object(forKey: "dueReminder") as? Bool ?? true)
            Notifier.replaceAll(with: list)
        }
    }
}
