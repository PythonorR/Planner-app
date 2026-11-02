import SwiftUI

struct DayTab: View {
    let planner: Planner
    @Binding var selected: Date
    let today: Date
    let onEdit: (Item) -> Void
    let onToggle: (UUID) -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        let groups = planner.groups(on: selected)
        let t = tally(planner.items(on: selected))

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                DueBar(items: dueSoon(planner.items, today: today), today: today)

                RibbonView(planner: planner, selected: $selected, today: today)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Day.same(selected, today) ? "Today" : Fmt.weekdayMonthDay(selected))
                        .screenTitle()
                        .accessibilityAddTraits(.isHeader)
                    Text("\(Fmt.fullDay(selected)) · \(t.done) of \(t.total) done")
                        .scaledFont(15)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 4)

                if groups.isEmpty {
                    Text("Nothing planned. Type below to add a task.")
                        .scaledFont(15)
                        .foregroundStyle(Theme.muted)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }

                ForEach(groups) { group in
                    SectionLabel(text: group.title, color: labelColor(group))
                        .accessibilityAddTraits(.isHeader)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 6)
                    ForEach(group.items) { item in
                        ItemRow(item: item,
                                subject: planner.subject(item.subjectID),
                                onToggle: { onToggle(item.id) },
                                onEdit: { onEdit(item) },
                                onDelete: { onDelete(item.id) })
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    private func labelColor(_ g: DayGroup) -> Color {
        switch g.kind {
        case .dueEvents: return Theme.due
        case .subject: return Theme.subject(g.colorIndex)
        case .noSubject: return Theme.muted
        }
    }
}

/// Red bar for a due date today or tomorrow. Informational only: it ignores taps.
struct DueBar: View {
    let items: [Item]
    let today: Date

    var body: some View {
        if let first = items.first {
            HStack(spacing: 10) {
                Diamond().fill(Theme.bg).frame(width: 10, height: 10)
                Text(message(first))
                    .scaledFont(15, .semibold)
                    .lineLimit(2)
                Spacer(minLength: 8)
                if items.count > 1 {
                    Text("+\(items.count - 1) more")
                        .scaledFont(13, .semibold)
                        .opacity(0.85)
                }
            }
            .foregroundStyle(Theme.bg)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.due)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
        }
    }

    private func message(_ item: Item) -> String {
        var s = "\(item.title) is due \(Day.same(item.date, today) ? "today" : "tomorrow")"
        if let m = item.timeMinutes { s += " · \(Fmt.time(m, compact: true))" }
        return s
    }
}
