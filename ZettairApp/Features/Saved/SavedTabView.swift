import SwiftUI

struct SavedTabView: View {
    @EnvironmentObject var environment: AppEnvironment
    @EnvironmentObject var router: AppRouter

    var body: some View {
        NavigationStack {
            List {
                Section("Saved queries") {
                    if environment.savedStore.savedQueries.isEmpty {
                        Text("No saved queries yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(environment.savedStore.savedQueries, id: \.self) { q in
                            Button(q) { router.openQuery(q) }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        environment.savedStore.unsaveQuery(q)
                                    } label: { Label("Remove", systemImage: "trash") }
                                }
                        }
                    }
                }
                Section("History") {
                    if environment.savedStore.history.isEmpty {
                        Text("No history yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(environment.savedStore.history, id: \.self) { q in
                            Button(q) { router.openQuery(q) }
                        }
                        Button("Clear history", role: .destructive) {
                            environment.savedStore.clearHistory()
                        }
                    }
                }
            }
            .navigationTitle("Saved")
        }
    }
}
