import SwiftUI

struct RootView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var navigator: Navigator

    private var cancelAction: (() -> Void)? {
        guard !container.favorites.isEmpty else { return nil }

        return {
            container.handle(.cancelFavourites)
        }
    }

    var body: some View {
        switch navigator.screen {
        case .search:
              SearchView(
                  vm: SearchViewModel(repo: container.repository)
              )
        case .favourites:
            CategorySelectionView(
                vm: CategorySelectionViewModel(
                    repo: container.repository,
                    selectedCategories: container.favorites
                ),
                onContinue: { categories in
                    container.handle(
                        .continueWithFavourites(categories)
                    )
                },
                onCancel: cancelAction
            )

        case .home:
            HomeView(
                vm: HomeViewModel(
                    repo: container.repository,
                    favorites: container.favorites
                )
            )
            .id(container.favorites.joined(separator: "|"))
        }
    }
}
