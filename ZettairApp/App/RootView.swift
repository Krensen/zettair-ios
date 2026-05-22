import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: AppRouter

    /// Custom binding for TabView selection. When the user taps the Search tab
    /// while it's already active, the setter sees newValue == oldValue and we
    /// bump router.searchHomeRequest. The Search tab observes that and resets
    /// to home — Twitter / Instagram / Slack idiom.
    private var tabSelection: Binding<AppRouter.Tab> {
        Binding(
            get: { router.tab },
            set: { newValue in
                if newValue == router.tab, newValue == .search {
                    router.searchHomeRequest &+= 1
                }
                router.tab = newValue
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            SearchTabView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppRouter.Tab.search)

            DailyBriefView()
                .tabItem { Label("Brief", systemImage: "newspaper") }
                .tag(AppRouter.Tab.brief)

            SavedTabView()
                .tabItem { Label("Saved", systemImage: "bookmark") }
                .tag(AppRouter.Tab.saved)

            SettingsTabView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(AppRouter.Tab.settings)
        }
        .tint(.accentColor)
    }
}
