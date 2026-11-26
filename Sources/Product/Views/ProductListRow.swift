import SwiftUI

struct ProductListRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            ProductImage(url: product.image, size: 60)
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title).lineLimit(2)
                Text(product.price, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
                Text("Rating: \(product.rating.rate, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
