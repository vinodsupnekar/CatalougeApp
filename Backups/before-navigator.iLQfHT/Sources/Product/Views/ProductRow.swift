import SwiftUI

struct ProductRow: View {
    let title: String
    let products: [Product]
    let seeAll: Route?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if let seeAll = seeAll {
                    NavigationLink("See all", value: seeAll)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(products) { product in
                        NavigationLink(value: Route.product(product)) {
                            ProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
