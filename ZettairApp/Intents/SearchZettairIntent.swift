import AppIntents
import Foundation

/// Public AppIntent that Siri, Spotlight, and Shortcuts can invoke. The intent
/// itself doesn't do the search — it constructs a deep-link URL and asks
/// iOS to open it, which routes through AppRouter.handle(url:).
public struct SearchZettairIntent: AppIntent {
    public static var title: LocalizedStringResource = "Search Wikipedia"
    public static var description = IntentDescription("Run a Zettair search across English Wikipedia.")
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "Query") public var query: String

    public init() {}

    public init(query: String) {
        self.query = query
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("Search Wikipedia for \(\.$query)")
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        // openAppWhenRun = true brings the app to the foreground. The query
        // needs to land in the app, so we post a Darwin notification via
        // shared UserDefaults that the app reads on activation.
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaults = UserDefaults(suiteName: "group.io.zettair.app") ?? .standard
        defaults.set(q, forKey: "pending.query")
        return .result()
    }
}

public struct ZettairShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchZettairIntent(),
            phrases: [
                "Search Wikipedia in \(.applicationName)",
                "Look up \(\.$query) in \(.applicationName)",
            ],
            shortTitle: "Search Wikipedia",
            systemImageName: "magnifyingglass"
        )
    }
}
