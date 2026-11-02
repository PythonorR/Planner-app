import SwiftUI

struct ProgressTab: View {
    let planner: Planner
    let today: Date

    private struct SubjectRow: Identifiable {
        let id: String
        let name: String
        let color: Color
        let tally: Tally
    }

    var body: some View {
        let t = tally(planner.items)
        let percent = Int((t.fraction * 100).rounded())
        let dayCount = Day.between(planner.start, planner.end) + 1

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(dayLabel(dayCount))
                    .scaledFont(12, .bold, relativeTo: .caption)
                    .tracking(0.6)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 24)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(percent)")
                        .scaledFont(96, .bold, relativeTo: .largeTitle)
                        .tracking(-3)
                        .foregroundStyle(Theme.fg)
                    Text("%")
                        .scaledFont(40, .bold, relativeTo: .largeTitle)
                        .foregroundStyle(Theme.muted)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(percent) percent done")

                Text("\(t.done) of \(t.total) done")
                    .scaledFont(17, .medium)
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 24)

                ForEach(subjectRows()) { row in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Circle().fill(row.color).frame(width: 10, height: 10)
                            Text(row.name)
                                .scaledFont(17, .semibold)
                                .foregroundStyle(Theme.fg)
                            Spacer()
                            Text("\(row.tally.done) / \(row.tally.total)")
                                .scaledFont(15, .medium)
                                .monospacedDigit()
                                .foregroundStyle(Theme.muted)
                        }
                        ProgressBar(fraction: row.tally.fraction, color: row.color, height: 8)
                    }
                    .padding(.vertical, 16)
                    .overlay(alignment: .top) { Separator() }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(row.name), \(row.tally.done) of \(row.tally.total) done")
                }

                Separator()

                HStack(alignment: .top, spacing: 12) {
                    stat("\(leftToday)", "left today")
                    stat("\(rolledOver)", "rolled over")
                    stat(String(format: "%.1f", Double(t.total) / Double(max(dayCount, 1))), "tasks per day")
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func dayLabel(_ count: Int) -> String {
        let k = Day.between(planner.start, today) + 1
        if k < 1 { return "STARTS \(Fmt.monthDay(planner.start).uppercased())" }
        if k > count { return "ENDED · \(count) DAYS" }
        return "DAY \(k) OF \(count)"
    }

    private var leftToday: Int {
        planner.items.filter { $0.counts && !$0.done && Day.same($0.date, today) }.count
    }

    private var rolledOver: Int {
        planner.items.filter { $0.kind == .task && !$0.done && $0.rolledFrom != nil }.count
    }

    private func subjectRows() -> [SubjectRow] {
        var rows = planner.subjects.map { s in
            SubjectRow(id: s.id.uuidString, name: s.name, color: Theme.subject(s.colorIndex),
                       tally: tally(planner.items.filter { $0.subjectID == s.id }))
        }
        let known = Set(planner.subjects.map(\.id))
        let orphans = planner.items.filter { item in item.subjectID.map { !known.contains($0) } ?? true }
        let orphanTally = tally(orphans)
        if orphanTally.total > 0 {
            rows.append(SubjectRow(id: "none", name: "No subject", color: Theme.muted, tally: orphanTally))
        }
        return rows
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .scaledFont(28, .bold, relativeTo: .title)
                .monospacedDigit()
                .foregroundStyle(Theme.fg)
            Text(label)
                .scaledFont(13)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
