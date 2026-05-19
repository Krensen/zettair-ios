import SwiftUI
import ZettairKit

@main
struct ZettairApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
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
        }
    }
}
