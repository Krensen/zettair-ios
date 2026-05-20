import SwiftUI
import ZettairKit

@main
struct ZettairApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var environment = AppEnvironment()
    @Environment(\.scenePhase) private var scenePhase
    @State private var launchAnimationDone = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(router)
                    .environmentObject(environment)
                    .onOpenURL { url in router.handle(url: url) }
                    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                        if let url = activity.webpageURL { router.handle(url: url) }
                    }
                    .onContinueUserActivity("io.zettair.app.search") { activity in
                        router.handle(activity: activity)
                    }
                    .onChange(of: scenePhase) { phase in
                        if phase == .active { drainPendingQueryFromIntent() }
                    }

                if !launchAnimationDone {
                    LaunchView {
                        withAnimation(.easeOut(duration: 0.35)) {
                            launchAnimationDone = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }

    private func drainPendingQueryFromIntent() {
        let defaults = UserDefaults(suiteName: "group.io.zettair.app") ?? .standard
        if let q = defaults.string(forKey: "pending.query"), !q.isEmpty {
            defaults.removeObject(forKey: "pending.query")
            router.openQuery(q)
        }
    }
}
