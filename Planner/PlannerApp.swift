import SwiftUI
import Combine

@main
struct PlannerApp: App {
    @StateObject private var store = Store()
    @AppStorage("theme") private var theme = "auto"
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            PlannerListView()
                .environmentObject(store)
                .tint(Theme.fg)
                .onAppear {
                    Theme.apply(theme)
                    store.launched()
                }
                .onChange(of: theme) { _, new in Theme.apply(new) }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.becameActive() }
                }
                // Midnight while the app is open: roll tasks over on the spot.
                .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
                    store.becameActive()
                }
        }
    }
}
