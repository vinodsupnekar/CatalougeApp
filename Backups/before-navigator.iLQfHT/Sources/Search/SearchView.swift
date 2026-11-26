import SwiftUI

struct SearchView: View {
    @StateObject var vm: SearchViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search product name", text: $vm.query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused($isFocused)
                    .onSubmit {
                        isFocused = false
                        Task { await vm.submit() }
                    }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()

            switch vm.state {
            case .idle:
                Text("Enter a product name and press Search.")
                    .foregroundStyle(.secondary)
                    .padding()
                Spacer()

            case .loading:
                ProgressView("Searching…").padding()
                Spacer()

            case .empty:
                Text("No matching products found.")
                    .foregroundStyle(.secondary)
                    .padding()
                Spacer()

            case .error(let message):
                Text(message).foregroundStyle(.red).padding()
                Button("Retry") {
                    Task { await vm.submit() }
                }
                Spacer()

            case .results(let products):
                List(products) { product in
                    NavigationLink(value: Route.product(product)) {
                        ProductListRow(product: product)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }
}
