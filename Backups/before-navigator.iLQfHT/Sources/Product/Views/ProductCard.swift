import SwiftUI

struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProductImage(url: product.image)
            Text(product.title)
                .font(.subheadline)
                .lineLimit(2)
                .frame(height: 42, alignment: .topLeading)
            Text(product.price, format: .currency(code: "USD"))
                .font(.subheadline.bold())
            Label(
                String(format: "%.1f", product.rating.rate),
                systemImage: "star.fill"
            )
            .font(.caption)
            .foregroundStyle(.orange)
        }
        .frame(width: 156, alignment: .leading)
    }
}
