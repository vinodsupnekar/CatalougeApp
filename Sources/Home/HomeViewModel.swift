import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var topRated: [Product] = []
    @Published var sections: [CategorySection] = []
    @Published var isLoading = false
    @Published var error: String?

    private let repo: ProductRepository
    private let favorites: [String]
    private var hasLoaded = false

    init(repo: ProductRepository, favorites: [String]) {
        self.repo = repo
        self.favorites = favorites
    }

    func load(force: Bool = false) async {
        guard !isLoading, force || !hasLoaded else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let products = try await repo.products(for: favorites)
            let sorted = products.sorted {
                if $0.rating.rate != $1.rating.rate {
                    return $0.rating.rate > $1.rating.rate
                }
                if $0.rating.count != $1.rating.count {
                    return $0.rating.count > $1.rating.count
                }
                return $0.id < $1.id
            }

            topRated = Array(sorted.prefix(5))
            sections = Dictionary(grouping: sorted, by: \.category)
                .map { CategorySection(name: $0.key, products: $0.value) }
                .sorted { $0.name < $1.name }
            hasLoaded = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
