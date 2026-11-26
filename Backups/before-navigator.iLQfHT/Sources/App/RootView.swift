import SwiftUI

struct RootView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        Group {
            if container.favorites.isEmpty {
                CategorySelectionView(
                    vm: CategorySelectionViewModel(repo: container.repository),
                    onContinue: container.saveFavorites
                )
            } else {
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
}
