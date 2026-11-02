import SwiftUI

struct NewPlannerView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    enum Source: Hashable { case blank, midterm, copy(UUID) }

    @State private var name = ""
    @State private var start = Day.start(Date())
    @State private var end = Day.add(9, Date())
    @State private var source: Source = .blank

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canCreate: Bool { source == .midterm || !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(source == .midterm ? "Midterm Sprint" : "Name", text: $name)
                        .scaledFont(22, .semibold, relativeTo: .title3)
                        .submitLabel(.done)
                } header: { Text("Name") }
                .listRowBackground(Theme.bg)

                Section {
                    DatePicker("Start", selection: $start, displayedComponents: .date)
                    DatePicker("End", selection: $end, in: start..., displayedComponents: .date)
                } header: { Text("Dates") }
                .listRowBackground(Theme.bg)

                Section {
                    Picker("Start from", selection: $source) {
                        Text("Blank").tag(Source.blank)
                        if !store.hasImportedMidterm {
                            Text("My Midterm Sprint plan (\(Seed.taskCount) tasks)").tag(Source.midterm)
                        }
                        ForEach(store.planners) { p in
                            Text("Subjects from \(p.displayName)").tag(Source.copy(p.id))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: { Text("Start from") }
                .listRowBackground(Theme.bg)
            }
            .plainList()
            .navigationTitle("New planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create).fontWeight(.semibold).disabled(!canCreate)
                }
            }
            .onChange(of: start) { _, s in
                if end < Day.start(s) { end = Day.start(s) }
            }
            .onChange(of: source) { _, s in
                if s == .midterm {
                    start = Seed.defaultStart
                    end = Day.add(9, Seed.defaultStart)
                }
            }
        }
    }

    private func create() {
        let s = Day.start(start)
        let e = max(Day.start(end), s)
        switch source {
        case .blank:
            store.createPlanner(name: trimmedName, start: s, end: e)
        case .midterm:
            store.importMidterm(name: trimmedName.isEmpty ? "Midterm Sprint" : trimmedName, start: s, end: e)
        case .copy(let id):
            let subjects = (store.planner(id)?.subjects ?? []).map { Subject(name: $0.name, colorIndex: $0.colorIndex) }
            store.createPlanner(name: trimmedName, start: s, end: e, subjects: subjects)
        }
        dismiss()
    }
}
