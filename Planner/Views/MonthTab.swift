import SwiftUI

struct MonthTab: View {
    let planner: Planner
    @Binding var selected: Date
    let today: Date
    let onOpen: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        let cells = Day.monthGrid(containing: selected)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(Fmt.monthName(selected))
                        .screenTitle()
                        .accessibilityAddTraits(.isHeader)
                    Text(Fmt.year(selected))
                        .scaledFont(20, .semibold)
                        .foregroundStyle(Theme.muted)
                    Spacer(minLength: 8)
                    ChevronButtons(previousLabel: "Previous month", nextLabel: "Next month",
                                   previous: { selected = Day.addMonths(-1, selected) },
                                   next: { selected = Day.addMonths(1, selected) })
                }
                .padding(.horizontal, 4)
                .padding(.top, 20)
                .padding(.bottom, 12)

                HStack(spacing: 0) {
                    ForEach(Array(Fmt.weekdayInitials().enumerated()), id: \.offset) { _, letter in
                        Text(letter)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 8)
                .accessibilityHidden(true)

                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                        if let day {
                            cell(day)
                        } else {
                            Color.clear.frame(minHeight: 68)
                        }
                    }
                }

                HStack(spacing: 8) {
                    Diamond().fill(Theme.due).frame(width: 8, height: 8)
                    Text("Due date")
                    Diamond().stroke(Theme.fg, lineWidth: 1.2).frame(width: 8, height: 8)
                        .padding(.leading, 12)
                    Text("Event")
                }
                .scaledFont(13)
                .foregroundStyle(Theme.muted)
                .padding(.top, 16)
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func cell(_ day: Date) -> some View {
        let items = planner.items(on: day)
        let segs = segments(for: items, subjects: planner.subjects)
        let hasDue = items.contains { $0.kind == .due && !$0.done }
        let hasEvent = items.contains { $0.kind == .event }
        let isSelected = Day.same(day, selected)
        let t = tally(items)

        return Button {
            onOpen(day)
        } label: {
            VStack(spacing: 3) {
                DayNumber(day: day, selected: isSelected, today: Day.same(day, today), size: 28)
                SegmentStack(segments: segs, width: 14, segment: 2, height: 20, gap: 1, emptyLine: 0)
                Marker(hasDue: hasDue, hasEvent: hasEvent, size: 8)
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .top)
            .overlay(alignment: .top) { Separator() }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Fmt.fullDay(day)), \(t.done) of \(t.total) done\(hasDue ? ", due date" : "")\(hasEvent ? ", event" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
