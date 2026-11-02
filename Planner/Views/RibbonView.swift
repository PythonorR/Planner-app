import SwiftUI

/// Seven columns for the week of the selected day. Tap selects a day; swipe moves a week.
struct RibbonView: View {
    let planner: Planner
    @Binding var selected: Date
    let today: Date

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Day.week(containing: selected), id: \.self) { day in
                column(day)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { selected = day }
            }
        }
        .padding(.horizontal, 12)
        .simultaneousGesture(
            DragGesture(minimumDistance: 24).onEnded { v in
                let w = v.translation.width
                guard abs(w) > abs(v.translation.height), abs(w) > 40 else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    selected = Day.add(w < 0 ? 7 : -7, selected)
                }
            }
        )
    }

    private func column(_ day: Date) -> some View {
        let items = planner.items(on: day)
        let segs = segments(for: items, subjects: planner.subjects)
        let hasDue = items.contains { $0.kind == .due && !$0.done }
        let hasEvent = items.contains { $0.kind == .event }
        let isSelected = Day.same(day, selected)
        let t = tally(items)

        var label = "\(Fmt.fullDay(day)), \(t.done) of \(t.total) done"
        if hasDue { label += ", due date" }
        if hasEvent { label += ", event" }

        return VStack(spacing: 6) {
            Text(Fmt.weekdayShort(day))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.muted)
            SegmentStack(segments: segs, width: 26, segment: 8, height: 66)
            DayNumber(day: day, selected: isSelected, today: Day.same(day, today))
            Marker(hasDue: hasDue, hasEvent: hasEvent)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { selected = day }
    }
}
