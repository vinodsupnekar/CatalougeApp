import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    let repository: ProductRepository
    let navigator: Navigator

    @Published private(set) var favorites: [String]

    private let store: FavoritesStore

    init() {
        let store = FavoritesStore()
        let savedFavorites = store.load()

        self.store = store
        favorites = savedFavorites

        repository = DefaultProductRepository(
            remote: FakeStoreAPI(),
            local: FileProductStore()
        )

        let navigator = Navigator()
        self.navigator = navigator

        navigator.handle(
            .launch,
            savedFavourites: savedFavorites
        )
    }

    func handle(_ action: Navigator.Action) {
        if case .continueWithFavourites(let categories) = action {
            let selection = Array(Set(categories)).sorted()
            guard !selection.isEmpty else { return }

            store.save(selection)
            favorites = selection
        }

        navigator.handle(
            action,
            savedFavourites: favorites
        )
    }
}
