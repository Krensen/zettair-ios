import Foundation

/// Placeholder for the PRD-028 M10 reading list. v0 keeps state in
/// `UserDefaults(suiteName:)` against the app group; CloudKit comes later.
@MainActor
final class SavedStore: ObservableObject {
    @Published private(set) var savedQueries: [String] = []
    @Published private(set) var savedArticles: [String] = []   // docnos
    @Published private(set) var history: [String] = []          // queries

    private let defaults: UserDefaults
    private let kQueries  = "saved.queries"
    private let kArticles = "saved.articles"
    private let kHistory  = "saved.history"

    init(suiteName: String = "group.io.zettair.app") {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.savedQueries  = defaults.stringArray(forKey: kQueries)  ?? []
        self.savedArticles = defaults.stringArray(forKey: kArticles) ?? []
        self.history       = defaults.stringArray(forKey: kHistory)  ?? []
    }

    func saveQuery(_ q: String) {
        guard !q.isEmpty, !savedQueries.contains(q) else { return }
        savedQueries.append(q)
        defaults.set(savedQueries, forKey: kQueries)
    }

    func unsaveQuery(_ q: String) {
        savedQueries.removeAll { $0 == q }
        defaults.set(savedQueries, forKey: kQueries)
    }

    func saveArticle(docno: String) {
        guard !savedArticles.contains(docno) else { return }
        savedArticles.append(docno)
        defaults.set(savedArticles, forKey: kArticles)
    }

    func unsaveArticle(docno: String) {
        savedArticles.removeAll { $0 == docno }
        defaults.set(savedArticles, forKey: kArticles)
    }

    func pushHistory(_ q: String) {
        guard !q.isEmpty else { return }
        history.removeAll { $0 == q }
        history.insert(q, at: 0)
        if history.count > 200 { history = Array(history.prefix(200)) }
        defaults.set(history, forKey: kHistory)
    }

    func clearHistory() {
        history = []
        defaults.set(history, forKey: kHistory)
    }
}
