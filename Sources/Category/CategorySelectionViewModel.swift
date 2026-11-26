import SwiftUI

@MainActor
final class CategorySelectionViewModel: ObservableObject {
    @Published var categories: [String] = []
    @Published var selected: Set<String>
    @Published var isLoading = false
    @Published var error: String?

    private let repo: ProductRepository

    init(
        repo: ProductRepository,
        selectedCategories: [String] = []
    ) {
        self.repo = repo
        selected = Set(selectedCategories)
    }

    func load() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            categories = try await repo.categories()

            // Remove unsupported categories from the draft only.
            // Saved favourites remain unchanged until Continue.
            selected.formIntersection(Set(categories))
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggle(_ category: String) {
        if selected.contains(category) {
            selected.remove(category)
        } else {
            selected.insert(category)
        }
    }
}
