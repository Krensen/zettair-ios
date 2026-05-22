import Foundation
import SwiftUI
import ZettairKit

@MainActor
final class DailyBriefViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded(DailyBrief)
        case error(String)
    }

    @Published var state: State = .idle

    /// Load today's brief. Hits the on-disk store first; if today's brief is
    /// missing or for an older date, fetches fresh from the API.
    func load(api: ZettairAPI, store: DailyBriefStore, force: Bool = false) async {
        let today = todayLocalDateString()
        if !force, case .loaded(let b) = state, b.date == today {
            return  // already loaded in this session
        }
        // Try disk first.
        if !force, let cached = await store.load(), cached.date == today, !cached.isStale {
            state = .loaded(cached)
            return
        }
        state = .loading
        do {
            let assembler = DailyBriefAssembler(api: api)
            let brief = try await assembler.assemble(forDate: today, maxItems: 3)
            if brief.items.isEmpty {
                state = .error("Nothing trending right now.")
                return
            }
            await store.save(brief)
            state = .loaded(brief)
        } catch {
            state = .error("Couldn't build today's brief.")
        }
    }
}
