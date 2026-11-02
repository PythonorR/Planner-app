import SwiftUI

/// Planner settings. Every change is saved immediately (title and list update live).
struct SettingsView: View {
    @Binding var deleteRequested: Bool

    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("theme") private var theme = "auto"
    @AppStorage("dailyReminder") private var dailyReminder = true
    @AppStorage("dueReminder") private var dueReminder = true

    @State private var draft: Planner
    @State private var confirmDelete = false

    init(planner: Planner, deleteRequested: Binding<Bool>) {
        _draft = State(initialValue: planner)
        _deleteRequested = deleteRequested
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Planner name", text: $draft.name)
                        .scaledFont(22, .semibold, relativeTo: .title3)
                    DatePicker("Start", selection: startBinding, displayedComponents: .date)
                    DatePicker("End", selection: endBinding, in: draft.start..., displayedComponents: .date)
                } header: { Text("Planner") }
                .listRowBackground(Theme.bg)

                Section {
                    Picker("Theme", selection: $theme) {
                        Text("Auto").tag("auto")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                } header: { Text("Theme") }
                .listRowBackground(Theme.bg)

                Section {
                    ForEach($draft.subjects) { $subject in
                        SubjectEditorRow(subject: $subject)
                    }
                    .onDelete { draft.subjects.remove(atOffsets: $0) }
                    Button {
                        addSubject()
                    } label: {
                        Label("Add subject", systemImage: "plus")
                            .foregroundStyle(Theme.fg)
                    }
                } header: {
                    Text("Subjects")
                } footer: {
                    Text("Swipe left to delete a subject. Its tasks stay, under “No subject”.")
                }
                .listRowBackground(Theme.bg)

                Section {
                    Toggle("Daily plan, 8:00 AM", isOn: $dailyReminder).tint(.green)
                    Toggle("Due dates, the day before", isOn: $dueReminder).tint(.green)
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("To turn all notifications off, go to iPhone Settings → Notifications → Planner.")
                }
                .listRowBackground(Theme.bg)

                Section {
                    Button("Delete planner", role: .destructive) { confirmDelete = true }
                }
                .listRowBackground(Theme.bg)
            }
            .plainList()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .confirmationDialog("Delete “\(draft.displayName)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete planner", role: .destructive) {
                    deleteRequested = true
                    dismiss()
                }
            } message: {
                Text("All of its tasks, due dates and events will be removed. This can't be undone.")
            }
            .onChange(of: draft) { _, new in store.update(new) }
            .onChange(of: dailyReminder) { store.scheduleNotifications() }
            .onChange(of: dueReminder) { store.scheduleNotifications() }
        }
    }

    private var startBinding: Binding<Date> {
        Binding(get: { draft.start }, set: { new in
            draft.start = Day.start(new)
            if draft.end < draft.start { draft.end = draft.start }
        })
    }

    private var endBinding: Binding<Date> {
        Binding(get: { draft.end }, set: { draft.end = Day.start($0) })
    }

    private func addSubject() {
        let used = Set(draft.subjects.map(\.colorIndex))
        let color = (0..<6).first { !used.contains($0) } ?? draft.subjects.count % 6
        draft.subjects.append(Subject(name: "New subject", colorIndex: color))
    }
}

private struct SubjectEditorRow: View {
    @Binding var subject: Subject

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Circle().fill(Theme.subject(subject.colorIndex)).frame(width: 10, height: 10)
                TextField("Subject name", text: $subject.name)
                    .scaledFont(17, .semibold)
            }
            HStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { i in
                    Button {
                        subject.colorIndex = i
                    } label: {
                        ZStack {
                            Circle().fill(Theme.subject(i)).frame(width: 22, height: 22)
                            if subject.colorIndex == i {
                                Circle().stroke(Theme.fg, lineWidth: 2).frame(width: 30, height: 30)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)   // so one tap doesn't press every button in the row
                    .accessibilityLabel(Theme.paletteNames[i])
                    .accessibilityAddTraits(subject.colorIndex == i ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, 4)
    }
}
