import SwiftUI

@MainActor
final class Navigator: ObservableObject {
    enum Screen {
        case favourites
        case home
        case search
    }

    enum Action {
        case launch
        case editFavourites
        case continueWithFavourites([String])
        case cancelFavourites

        case search
        case showCategory(String)
        case showProduct(Product)
        case back
        case home
    }

    @Published private(set) var screen: Screen = .favourites

    // Writable so NavigationStack can update it on Back/swipe gestures.
    @Published var path: [Route] = []

    func handle(
        _ action: Action,
        savedFavourites: [String]
    ) {
        switch action {
        case .launch:
            path.removeAll()
            screen = savedFavourites.isEmpty ? .favourites : .home

        case .editFavourites:
            path.removeAll()
            screen = .favourites

        case .continueWithFavourites(let categories):
            guard !categories.isEmpty else { return }
            path.removeAll()
            screen = .home

        case .cancelFavourites:
            path.removeAll()
            screen = savedFavourites.isEmpty ? .favourites : .home

        case .search:
            guard screen == .home else { return }
            if path.last != .search {
                path.append(.search)
            }

        case .showCategory(let category):
            guard screen == .home else { return }
            path.append(.category(category))

        case .showProduct(let product):
            guard screen == .home else { return }
            path.append(.product(product))

        case .back:
            guard !path.isEmpty else { return }
            path.removeLast()

        case .home:
            path.removeAll()
            screen = savedFavourites.isEmpty ? .favourites : .home
        }
    }
}
