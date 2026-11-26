import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @State private var showEnquiry = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProductImage(url: product.image, size: 250)
                    .frame(maxWidth: .infinity)

                Text(product.title).font(.title2.bold())
                Text(product.category.capitalized)
                    .foregroundStyle(.secondary)

                Text(product.price, format: .currency(code: "USD"))
                    .font(.title.bold())

                Label(
                    "\(product.rating.rate, specifier: "%.1f") • \(product.rating.count) ratings",
                    systemImage: "star.fill"
                )
                .foregroundStyle(.orange)

                Divider()
                Text("Description").font(.headline)
                Text(product.description)

                Button {
                    showEnquiry = true
                } label: {
                    Text("Make an Enquiry")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEnquiry) {
            EnquiryView(vm: EnquiryViewModel(product: product))
        }
    }
}
