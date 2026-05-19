import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        TabView(selection: $router.tab) {
            SearchTabView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppRouter.Tab.search)

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
