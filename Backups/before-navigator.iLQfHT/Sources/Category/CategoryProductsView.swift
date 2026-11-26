import SwiftUI

struct CategoryProductsView: View {
    let title: String
    let products: [Product]

    var body: some View {
        List(products) { product in
            NavigationLink(value: Route.product(product)) {
                ProductListRow(product: product)
            }
        }
        .navigationTitle(title.capitalized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
