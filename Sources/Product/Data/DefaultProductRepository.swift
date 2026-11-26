import Foundation

final class DefaultProductRepository: ProductRepository {
    private let remote: ProductRemoteDataSource
    private let local: ProductLocalDataSource

    init(remote: ProductRemoteDataSource, local: ProductLocalDataSource) {
        self.remote = remote
        self.local = local
    }

    func categories() async throws -> [String] {
        try await remote.fetchCategories().sorted()
    }

    func products(for categories: [String]) async throws -> [Product] {
        let selected = Set(categories)
        guard !selected.isEmpty else { return [] }

        let fetched: [Product]
        do {
            // Only selected categories are requested from the backend.
            var items: [Product] = []
            for category in selected.sorted() {
                try Task.checkCancellation()
                items += try await remote.fetch(category: category)
            }
            fetched = items
        } catch {
            if error is CancellationError { throw error }
            let cached = try await local.all()
                .filter { selected.contains($0.category) }
            guard !cached.isEmpty else { throw error }
            return cached
        }

        try await local.save(fetched)
        return fetched.sorted { $0.id < $1.id }
    }

    func search(_ query: String) async throws -> [Product] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        func matches(_ product: Product) -> Bool {
            product.title.localizedCaseInsensitiveContains(query)
        }

        // Search the persisted catalogue first.
        let cached = try await local.all()
        let localMatches = cached.filter(matches)
        if !localMatches.isEmpty {
            return localMatches.sorted { $0.id < $1.id }
        }

        // A local miss triggers a full catalogue refresh.
        try Task.checkCancellation()
        let refreshed = try await remote.fetchAll()
        try await local.save(refreshed)
        return refreshed.filter(matches).sorted { $0.id < $1.id }
    }
}
