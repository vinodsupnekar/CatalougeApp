import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    let repository: ProductRepository
    @Published private(set) var favorites: [String]
    private let store = FavoritesStore()

    init(productRemoteDataSource: ProductRemoteDataSource,
         productLocalDataSource: ProductLocalDataSource) {
        repository = DefaultProductRepository(
            remote: productRemoteDataSource,
            local: productLocalDataSource //FileProductStore()
        )
        favorites = store.load()
    }

    func saveFavorites(_ categories: [String]) {
        let categories = Array(Set(categories)).sorted()
        store.save(categories)
        favorites = categories
    }
}
