import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case results([Product])
        case empty
        case error(String)
    }

    @Published var query = ""
    @Published var state: State = .idle

    private let repo: ProductRepository
    private var requestID = UUID()

    init(repo: ProductRepository) {
        self.repo = repo
    }

    func submit() async {
        let id = UUID()
        requestID = id

        let submittedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedQuery.isEmpty else {
            state = .idle
            return
        }

        state = .loading

        do {
            let products = try await repo.search(submittedQuery)
            // Prevent an older request from replacing newer results.
            guard requestID == id else { return }
            state = products.isEmpty ? .empty : .results(products)
        } catch {
            guard requestID == id else { return }
            state = .error(error.localizedDescription)
        }
    }
}
