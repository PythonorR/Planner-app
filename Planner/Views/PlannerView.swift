import SwiftUI

enum PlannerTab: String, CaseIterable, Identifiable {
    case day = "Day", week = "Week", month = "Month", progress = "Progress"
    var id: Self { self }
}

struct EditorTarget: Identifiable {
    let id = UUID()
    let item: Item
    let isNew: Bool
}

/// Tab row + content + persistent quick-add bar.
struct PlannerView: View {
    let id: UUID
    let onDelete: () -> Void

    @EnvironmentObject private var store: Store
    @State private var tab: PlannerTab = .day
    @State private var selected = Day.start(Date())
    @State private var quickSubject: UUID?
    @State private var editor: EditorTarget?
    @State private var showSettings = false
    @State private var deleteRequested = false

    var body: some View {
        Group {
            if let planner = store.planner(id) {
                content(planner)
            } else {
                Theme.bg.ignoresSafeArea()
            }
        }
        .toolbar(.visible, for: .navigationBar)
    }

    private func content(_ p: Planner) -> some View {
        VStack(spacing: 0) {
            tabRow
            switch tab {
            case .day:
                DayTab(planner: p, selected: $selected, today: store.today,
                       onEdit: { editor = EditorTarget(item: $0, isNew: false) },
                       onToggle: { store.toggle($0, in: id) },
                       onDelete: { store.delete($0, in: id) })
            case .week:
                WeekTab(planner: p, selected: $selected, today: store.today, onOpen: openDay)
            case .month:
                MonthTab(planner: p, selected: $selected, today: store.today, onOpen: openDay)
            case .progress:
                ProgressTab(planner: p, today: store.today)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if tab != .progress {
                QuickAddBar(planner: p, date: selected, today: store.today, subjectID: $quickSubject,
                            onAdd: { title in
                                store.add([Item(title: title, subjectID: p.subject(quickSubject)?.id, date: selected)], to: id)
                            },
                            onMore: { title in
                                editor = EditorTarget(item: Item(title: title, subjectID: p.subject(quickSubject)?.id, date: selected),
                                                      isNew: true)
                            })
            }
        }
        .navigationTitle(p.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3") }
                    .accessibilityLabel("Planner settings")
            }
        }
        .sheet(item: $editor) { target in
            ItemEditor(plannerID: id, item: target.item, isNew: target.isNew)
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            if deleteRequested { onDelete() }
        }) {
            SettingsView(planner: p, deleteRequested: $deleteRequested)
        }
        .onAppear {
            if quickSubject == nil { quickSubject = p.subjects.first?.id }
        }
    }

    private func openDay(_ day: Date) {
        selected = day
        tab = .day
    }

    private var tabRow: some View {
        HStack(spacing: 20) {
            ForEach(PlannerTab.allCases) { t in
                Button { tab = t } label: {
                    Text(t.rawValue)
                        .scaledFont(16, tab == t ? .bold : .regular)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(tab == t ? Theme.fg : Theme.muted)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            if tab == t { Rectangle().fill(Theme.fg).frame(height: 2.5) }
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == t ? .isSelected : [])
            }
            Spacer(minLength: 0)
            if tab != .progress && !Day.same(selected, store.today) {
                Button { selected = store.today } label: {
                    Text("Today")
                        .scaledFont(13, .semibold)
                        .lineLimit(1)
                        .foregroundStyle(Theme.bg)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.fg))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Go to today")
            }
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .bottom) { Separator() }
    }
}

/// Capsule at the bottom: subject dot · text field · "…" for the full editor.
struct QuickAddBar: View {
    let planner: Planner
    let date: Date
    let today: Date
    @Binding var subjectID: UUID?
    let onAdd: (String) -> Void
    let onMore: (String) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        let subject = planner.subject(subjectID)
        HStack(spacing: 0) {
            Menu {
                Picker("Subject", selection: $subjectID) {
                    Text("No subject").tag(UUID?.none)
                    ForEach(planner.subjects) { s in
                        Text(s.name).tag(UUID?.some(s.id))
                    }
                }
            } label: {
                Circle()
                    .fill(Theme.color(for: subject))
                    .frame(width: 14, height: 14)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Subject: \(subject?.name ?? "No subject")")

            TextField(placeholder, text: $text)
                .scaledFont(16)
                .foregroundStyle(Theme.fg)
                .submitLabel(.done)
                .focused($focused)
                .onSubmit(add)

            Button {
                onMore(text.trimmingCharacters(in: .whitespacesAndNewlines))
                text = ""
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.fg)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options")
        }
        .padding(.horizontal, 4)
        .background(Capsule().fill(Theme.bg))
        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.bg)
        .overlay(alignment: .top) { Separator() }
    }

    private var placeholder: String {
        Day.same(date, today) ? "Add a task for today" : "Add a task for \(Fmt.weekdayMonthDay(date))"
    }

    private func add() {
        let title = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        onAdd(title)
        text = ""
        DispatchQueue.main.async { focused = true }   // keep the keyboard up for the next one
    }
}
