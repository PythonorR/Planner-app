import SwiftUI

/// Root screen. Exactly one add control: the "New planner" capsule at the bottom.
struct PlannerListView: View {
    @EnvironmentObject private var store: Store
    @State private var path: [UUID] = []
    @State private var showNew = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Planners")
                        .screenTitle()
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 24)
                        .padding(.bottom, 12)

                    if store.planners.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.planners) { planner in
                            NavigationLink(value: planner.id) {
                                PlannerRow(planner: planner)
                            }
                            .buttonStyle(.plain)
                        }
                        Separator()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button { showNew = true } label: { Text("＋ New planner") }
                    .buttonStyle(FilledCapsule())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Theme.bg)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                PlannerView(id: id) {
                    path.removeAll()
                    store.deletePlanner(id)
                }
            }
            .sheet(isPresented: $showNew) { NewPlannerView() }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Separator()
            Text("No planners yet")
                .scaledFont(24, .bold, relativeTo: .title2)
                .foregroundStyle(Theme.fg)
                .padding(.top, 16)
            Text("A planner covers a stretch of study days. Start a new one below, or bring in your midterm plan.")
                .scaledFont(15)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button("Import Midterm Sprint (\(Seed.taskCount) tasks)") {
                store.importMidterm()
            }
            .buttonStyle(OutlinedCapsule())
            .padding(.top, 8)
        }
    }
}

private struct PlannerRow: View {
    let planner: Planner

    var body: some View {
        let t = tally(planner.items)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(planner.displayName)
                    .scaledFont(28, .bold, relativeTo: .title)
                    .tracking(-0.5)
                    .foregroundStyle(Theme.fg)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.muted)
            }
            ProgressBar(fraction: t.fraction, height: 3)
            HStack {
                Text(Fmt.range(planner.start, planner.end))
                Spacer()
                Text("\(t.done) of \(t.total) done").monospacedDigit()
            }
            .scaledFont(14)
            .foregroundStyle(Theme.muted)
        }
        .padding(.vertical, 18)
        .overlay(alignment: .top) { Separator() }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(planner.displayName), \(Fmt.range(planner.start, planner.end)), \(t.done) of \(t.total) done")
        .accessibilityAddTraits(.isButton)
    }
}
