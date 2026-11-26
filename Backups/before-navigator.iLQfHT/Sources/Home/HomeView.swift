import SwiftUI

struct HomeView: View {
    @StateObject var vm: HomeViewModel
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if vm.isLoading {
                        ProgressView("Loading products…")
                            .frame(maxWidth: .infinity)
                    }

                    if let error = vm.error {
                        VStack {
                            Text(error).foregroundStyle(.red)
                            Button("Retry") {
                                Task { await vm.load(force: true) }
                            }
                        }
                        .padding(.horizontal)
                    }

                    if !vm.topRated.isEmpty {
                        ProductRow(
                            title: "Top Rated",
                            products: vm.topRated,
                            seeAll: nil
                        )
                    }

                    ForEach(vm.sections) { section in
                        ProductRow(
                            title: section.name.capitalized,
                            products: Array(section.products.prefix(8)),
                            seeAll: .category(section.name)
                        )
                    }

                    if !vm.isLoading && vm.error == nil && vm.sections.isEmpty {
                        Text("No products available.")
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Catalogue")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(value: Route.search) {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Search products")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Favourites") {
                        container.handle(.editFavourites)
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .search:
                    SearchView(vm: SearchViewModel(repo: container.repository))
                case .category(let category):
                    CategoryProductsView(
                        title: category,
                        products: vm.sections.first {
                            $0.name == category
                        }?.products ?? []
                    )
                case .product(let product):
                    ProductDetailView(product: product)
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.load(force: true) }
        }
    }
}
