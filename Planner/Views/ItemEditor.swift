import SwiftUI

struct ItemEditor: View {
    let plannerID: UUID
    let isNew: Bool
    private let originalDate: Date

    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var item: Item
    @State private var rule: RepeatRule = .never
    @State private var hasTime: Bool
    @State private var time: Date
    @FocusState private var titleFocused: Bool

    init(plannerID: UUID, item: Item, isNew: Bool) {
        self.plannerID = plannerID
        self.isNew = isNew
        self.originalDate = item.date
        _item = State(initialValue: item)
        _hasTime = State(initialValue: item.timeMinutes != nil || (isNew && item.kind == .due))
        _time = State(initialValue: ItemEditor.date(fromMinutes: item.timeMinutes ?? 17 * 60))
    }

    private var planner: Planner? { store.planner(plannerID) }
    private var trimmedTitle: String { item.title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            List {
                if isNew {
                    Section {
                        Picker("Type", selection: $item.kind) {
                            Text("Task").tag(ItemKind.task)
                            Text("Due date").tag(ItemKind.due)
                            Text("Event").tag(ItemKind.event)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .listRowBackground(Theme.bg)
                    .listRowSeparator(.hidden)
                }

                Section {
                    TextField(placeholder, text: $item.title, axis: .vertical)
                        .scaledFont(24, .semibold, relativeTo: .title2)
                        .lineLimit(1...5)
                        .focused($titleFocused)
                }
                .listRowBackground(Theme.bg)

                Section {
                    Picker("Subject", selection: $item.subjectID) {
                        Text("None").tag(UUID?.none)
                        ForEach(planner?.subjects ?? []) { s in
                            Text(s.name).tag(UUID?.some(s.id))
                        }
                    }
                    DatePicker("Date", selection: dateBinding, displayedComponents: .date)
                }
                .listRowBackground(Theme.bg)

                switch item.kind {
                case .task:
                    Section {
                        if isNew {
                            Picker("Repeat", selection: $rule) {
                                Text("Never").tag(RepeatRule.never)
                                Text("Every day").tag(RepeatRule.daily)
                                Text("Weekdays").tag(RepeatRule.weekdays)
                                Text("Every week").tag(RepeatRule.weekly)
                            }
                        }
                    } footer: {
                        Text("If you don't finish it, it moves to the next day on its own.")
                    }
                    .listRowBackground(Theme.bg)
                case .due:
                    Section {
                        Toggle("Time", isOn: $hasTime).tint(.green)
                        if hasTime {
                            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        }
                        Toggle("Remind me", isOn: $item.remind).tint(.green)
                    } footer: {
                        Text("Reminders arrive at 8:00 AM the day before and on the due day. A red bar also shows at the top of the Day view on both days.")
                    }
                    .listRowBackground(Theme.bg)
                case .event:
                    Section {
                        Toggle("Time", isOn: $hasTime).tint(.green)
                        if hasTime {
                            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        }
                    }
                    .listRowBackground(Theme.bg)
                }

                if !isNew {
                    Section {
                        Button("Delete", role: .destructive) {
                            store.delete(item.id, in: plannerID)
                            dismiss()
                        }
                    }
                    .listRowBackground(Theme.bg)
                }
            }
            .plainList()
            .navigationTitle(isNew ? "New" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).fontWeight(.semibold).disabled(trimmedTitle.isEmpty)
                }
            }
            .onChange(of: item.kind) { _, kind in
                hasTime = kind == .due
                if kind == .due { item.remind = true }
                if kind != .task { rule = .never }
            }
            .onAppear {
                // An orphaned subject (deleted in settings) shows as "None".
                if item.subjectID != nil && planner?.subject(item.subjectID) == nil { item.subjectID = nil }
                if isNew && item.title.isEmpty { titleFocused = true }
            }
        }
    }

    private var placeholder: String {
        switch item.kind {
        case .task: return "What will you study?"
        case .due: return "What is due?"
        case .event: return "Event"
        }
    }

    private var dateBinding: Binding<Date> {
        Binding(get: { item.date }, set: { item.date = Day.start($0) })
    }

    private func save() {
        var it = item
        it.title = trimmedTitle
        it.timeMinutes = (it.kind != .task && hasTime) ? ItemEditor.minutes(of: time) : nil
        if it.kind == .event { it.done = false }

        if isNew {
            let end = planner?.end ?? it.date
            let dates = it.kind == .task ? occurrences(from: it.date, rule: rule, until: end) : [it.date]
            let series: UUID? = dates.count > 1 ? UUID() : nil
            let copies = dates.map { d -> Item in
                var c = it
                c.id = UUID()
                c.date = d
                c.seriesID = series
                return c
            }
            store.add(copies, to: plannerID)
        } else {
            if !Day.same(it.date, originalDate) { it.rolledFrom = nil }
            store.save(it, in: plannerID)
        }
        dismiss()
    }

    static func date(fromMinutes m: Int) -> Date {
        Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
    }

    static func minutes(of date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
