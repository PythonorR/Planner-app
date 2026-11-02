import SwiftUI

struct WeekTab: View {
    let planner: Planner
    @Binding var selected: Date
    let today: Date
    let onOpen: (Date) -> Void

    var body: some View {
        let days = Day.week(containing: selected)
        let isThisWeek = days.contains { Day.same($0, today) }

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isThisWeek ? "This week" : "Week of \(Fmt.monthDay(days[0]))")
                            .screenTitle()
                            .accessibilityAddTraits(.isHeader)
                        Text(Fmt.range(days[0], days[6]))
                            .scaledFont(15)
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer(minLength: 8)
                    ChevronButtons(previousLabel: "Previous week", nextLabel: "Next week",
                                   previous: { selected = Day.add(-7, selected) },
                                   next: { selected = Day.add(7, selected) })
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                ForEach(days, id: \.self) { day in row(day) }
                Separator().padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
    }

    private func row(_ day: Date) -> some View {
        let items = planner.groups(on: day).flatMap(\.items)
        let t = tally(items)
        let segs = segments(for: items, subjects: planner.subjects, limit: 10)
        let titles = items.map { $0.kind == .task ? $0.title : "◆ " + $0.title }.joined(separator: " · ")

        return Button { onOpen(day) } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(spacing: 2) {
                    Text(Fmt.weekdayShort(day))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                    DayNumber(day: day, selected: Day.same(day, selected), today: Day.same(day, today))
                }
                .frame(width: 44)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 3) {
                        if segs.isEmpty {
                            Capsule().fill(Theme.line).frame(width: 18, height: 3)
                        }
                        ForEach(segs.indices, id: \.self) { i in
                            Capsule()
                                .fill(Theme.subject(segs[i].colorIndex).opacity(segs[i].done ? 1 : 0.3))
                                .frame(width: 18, height: 10)
                        }
                    }
                    .frame(minHeight: 10)
                    Text(titles.isEmpty ? "Nothing planned" : titles)
                        .scaledFont(14)
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if t.total > 0 {
                    Text("\(t.done)/\(t.total)")
                        .scaledFont(15, .semibold)
                        .monospacedDigit()
                        .foregroundStyle(Theme.fg)
                }
            }
            .padding(.vertical, 12)
            .frame(minHeight: 64)
            .overlay(alignment: .top) { Separator() }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Fmt.fullDay(day)), \(t.done) of \(t.total) done. \(titles.replacingOccurrences(of: "◆ ", with: ""))")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onOpen(day) }
    }
}
