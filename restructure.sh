#!/bin/bash
set -euo pipefail

rm -rf Sources
mkdir -p Sources/App
mkdir -p Sources/Product/{Model,Data,Views}
mkdir -p Sources/{Category,Home,Search,Enquiry}

############################ APP ############################

cat > Sources/App/CatalogueApp.swift <<'SWIFT'
import SwiftUI

@main
struct CatalogueApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
        }
    }
}
SWIFT

cat > Sources/App/AppContainer.swift <<'SWIFT'
import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    let repository: ProductRepository
    @Published private(set) var favorites: [String]
    private let store = FavoritesStore()

    init() {
        repository = DefaultProductRepository(
            remote: FakeStoreAPI(),
            local: FileProductStore()
        )
        favorites = store.load()
    }

    func saveFavorites(_ categories: [String]) {
        let categories = Array(Set(categories)).sorted()
        store.save(categories)
        favorites = categories
    }
}
SWIFT

cat > Sources/App/Route.swift <<'SWIFT'
import Foundation

enum Route: Hashable {
    case search
    case category(String)
    case product(Product)
}
SWIFT

cat > Sources/App/RootView.swift <<'SWIFT'
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
SWIFT

######################## PRODUCT / MODEL ########################

cat > Sources/Product/Model/Product.swift <<'SWIFT'
import Foundation

struct Product: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let price: Double
    let description: String
    let category: String
    let image: String
    let rating: Rating

    struct Rating: Codable, Hashable {
        let rate: Double
        let count: Int
    }
}
SWIFT

######################## PRODUCT / DATA ########################

cat > Sources/Product/Data/ProductRemoteDataSource.swift <<'SWIFT'
import Foundation

protocol ProductRemoteDataSource {
    func fetchCategories() async throws -> [String]
    func fetchAll() async throws -> [Product]
    func fetch(category: String) async throws -> [Product]
}
SWIFT

cat > Sources/Product/Data/FakeStoreAPI.swift <<'SWIFT'
import Foundation

struct FakeStoreAPI: ProductRemoteDataSource {
    private let baseURL = URL(string: "https://fakestoreapi.com")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCategories() async throws -> [String] {
        try await get(baseURL.appendingPathComponent("products/categories"))
    }

    func fetchAll() async throws -> [Product] {
        try await get(baseURL.appendingPathComponent("products"))
    }

    func fetch(category: String) async throws -> [Product] {
        let url = baseURL
            .appendingPathComponent("products/category")
            .appendingPathComponent(category)
        return try await get(url)
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
SWIFT

cat > Sources/Product/Data/ProductLocalDataSource.swift <<'SWIFT'
import Foundation

protocol ProductLocalDataSource {
    func all() async throws -> [Product]
    func save(_ products: [Product]) async throws
}
SWIFT

cat > Sources/Product/Data/FileProductStore.swift <<'SWIFT'
import Foundation

actor FileProductStore: ProductLocalDataSource {
    private let fileURL: URL
    private var cache: [Int: Product]?

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CatalogueApp/products.json")
    }

    func all() async throws -> [Product] {
        try loadIfNeeded()
        return Array((cache ?? [:]).values).sorted { $0.id < $1.id }
    }

    func save(_ products: [Product]) async throws {
        try loadIfNeeded()
        var merged = cache ?? [:]
        for product in products {
            merged[product.id] = product
        }

        let data = try JSONEncoder().encode(
            Array(merged.values).sorted { $0.id < $1.id }
        )
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try data.write(to: fileURL, options: .atomic)
        cache = merged
    }

    private func loadIfNeeded() throws {
        guard cache == nil else { return }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            cache = [:]
            return
        }

        let data = try Data(contentsOf: fileURL)
        let products = try JSONDecoder().decode([Product].self, from: data)
        var loaded: [Int: Product] = [:]
        for product in products {
            loaded[product.id] = product
        }
        cache = loaded
    }
}
SWIFT

cat > Sources/Product/Data/ProductRepository.swift <<'SWIFT'
import Foundation

protocol ProductRepository {
    func categories() async throws -> [String]
    func products(for categories: [String]) async throws -> [Product]
    func search(_ query: String) async throws -> [Product]
}
SWIFT

cat > Sources/Product/Data/DefaultProductRepository.swift <<'SWIFT'
import Foundation

final class DefaultProductRepository: ProductRepository {
    private let remote: ProductRemoteDataSource
    private let local: ProductLocalDataSource

    init(remote: ProductRemoteDataSource, local: ProductLocalDataSource) {
        self.remote = remote
        self.local = local
    }

    func categories() async throws -> [String] {
        try await remote.fetchCategories().sorted()
    }

    func products(for categories: [String]) async throws -> [Product] {
        let selected = Set(categories)
        guard !selected.isEmpty else { return [] }

        let fetched: [Product]
        do {
            // Only selected categories are requested from the backend.
            var items: [Product] = []
            for category in selected.sorted() {
                try Task.checkCancellation()
                items += try await remote.fetch(category: category)
            }
            fetched = items
        } catch {
            if error is CancellationError { throw error }
            let cached = try await local.all()
                .filter { selected.contains($0.category) }
            guard !cached.isEmpty else { throw error }
            return cached
        }

        try await local.save(fetched)
        return fetched.sorted { $0.id < $1.id }
    }

    func search(_ query: String) async throws -> [Product] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        func matches(_ product: Product) -> Bool {
            product.title.localizedCaseInsensitiveContains(query)
        }

        // Search the persisted catalogue first.
        let cached = try await local.all()
        let localMatches = cached.filter(matches)
        if !localMatches.isEmpty {
            return localMatches.sorted { $0.id < $1.id }
        }

        // A local miss triggers a full catalogue refresh.
        try Task.checkCancellation()
        let refreshed = try await remote.fetchAll()
        try await local.save(refreshed)
        return refreshed.filter(matches).sorted { $0.id < $1.id }
    }
}
SWIFT

######################## PRODUCT / VIEWS ########################

cat > Sources/Product/Views/ProductImage.swift <<'SWIFT'
import SwiftUI

struct ProductImage: View {
    let url: String
    var size: CGFloat = 140

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            default:
                ProgressView()
            }
        }
        .frame(width: size, height: size)
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
SWIFT

cat > Sources/Product/Views/ProductCard.swift <<'SWIFT'
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
SWIFT

cat > Sources/Product/Views/ProductListRow.swift <<'SWIFT'
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
SWIFT

cat > Sources/Product/Views/ProductRow.swift <<'SWIFT'
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
SWIFT

cat > Sources/Product/Views/ProductDetailView.swift <<'SWIFT'
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
SWIFT

############################ CATEGORY ############################

cat > Sources/Category/CategorySection.swift <<'SWIFT'
import Foundation

struct CategorySection: Identifiable {
    var id: String { name }
    let name: String
    let products: [Product]
}
SWIFT

cat > Sources/Category/FavoritesStore.swift <<'SWIFT'
import Foundation

struct FavoritesStore {
    private let defaults: UserDefaults
    private let key = "catalogue.favoriteCategories"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    func save(_ categories: [String]) {
        defaults.set(categories, forKey: key)
    }
}
SWIFT

cat > Sources/Category/CategorySelectionViewModel.swift <<'SWIFT'
import SwiftUI

@MainActor
final class CategorySelectionViewModel: ObservableObject {
    @Published var categories: [String] = []
    @Published var selected: Set<String> = []
    @Published var isLoading = false
    @Published var error: String?

    private let repo: ProductRepository

    init(repo: ProductRepository) {
        self.repo = repo
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            categories = try await repo.categories()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggle(_ category: String) {
        if selected.contains(category) {
            selected.remove(category)
        } else {
            selected.insert(category)
        }
    }
}
SWIFT

cat > Sources/Category/CategorySelectionView.swift <<'SWIFT'
import SwiftUI

struct CategorySelectionView: View {
    @StateObject var vm: CategorySelectionViewModel
    let onContinue: ([String]) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose your favourite categories")
                    .font(.title2.bold())

                Text("We’ll show products from these categories.")
                    .foregroundStyle(.secondary)

                if vm.isLoading {
                    ProgressView("Loading categories…")
                }

                if let error = vm.error {
                    Text(error)
                        .foregroundStyle(.red)
                    Button("Retry") {
                        Task { await vm.load() }
                    }
                }

                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 145))],
                        spacing: 12
                    ) {
                        ForEach(vm.categories, id: \.self) { category in
                            Button {
                                vm.toggle(category)
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: vm.selected.contains(category)
                                          ? "checkmark.circle.fill"
                                          : "circle")
                                    Text(category.capitalized)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .foregroundStyle(
                                    vm.selected.contains(category)
                                    ? Color.white : Color.primary
                                )
                                .background(
                                    vm.selected.contains(category)
                                    ? Color.accentColor
                                    : Color(uiColor: .secondarySystemBackground)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(category)
                            .accessibilityValue(
                                vm.selected.contains(category)
                                ? "Selected" : "Not selected"
                            )
                        }
                    }
                }

                Button("Continue") {
                    onContinue(vm.selected.sorted())
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.selected.isEmpty || vm.isLoading)
            }
            .padding()
            .navigationTitle("Top Categories")
            .task { await vm.load() }
        }
    }
}
SWIFT

cat > Sources/Category/CategoryProductsView.swift <<'SWIFT'
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
SWIFT

############################## HOME ##############################

cat > Sources/Home/HomeViewModel.swift <<'SWIFT'
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var topRated: [Product] = []
    @Published var sections: [CategorySection] = []
    @Published var isLoading = false
    @Published var error: String?

    private let repo: ProductRepository
    private let favorites: [String]
    private var hasLoaded = false

    init(repo: ProductRepository, favorites: [String]) {
        self.repo = repo
        self.favorites = favorites
    }

    func load(force: Bool = false) async {
        guard !isLoading, force || !hasLoaded else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let products = try await repo.products(for: favorites)
            let sorted = products.sorted {
                if $0.rating.rate != $1.rating.rate {
                    return $0.rating.rate > $1.rating.rate
                }
                if $0.rating.count != $1.rating.count {
                    return $0.rating.count > $1.rating.count
                }
                return $0.id < $1.id
            }

            topRated = Array(sorted.prefix(5))
            sections = Dictionary(grouping: sorted, by: \.category)
                .map { CategorySection(name: $0.key, products: $0.value) }
                .sorted { $0.name < $1.name }
            hasLoaded = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
SWIFT

cat > Sources/Home/HomeView.swift <<'SWIFT'
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
                        container.saveFavorites([])
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
SWIFT

############################# SEARCH #############################

cat > Sources/Search/SearchViewModel.swift <<'SWIFT'
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case results([Product])
        case empty
        case error(String)
    }

    @Published var query = ""
    @Published var state: State = .idle

    private let repo: ProductRepository
    private var requestID = UUID()

    init(repo: ProductRepository) {
        self.repo = repo
    }

    func submit() async {
        let id = UUID()
        requestID = id

        let submittedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedQuery.isEmpty else {
            state = .idle
            return
        }

        state = .loading

        do {
            let products = try await repo.search(submittedQuery)
            // Prevent an older request from replacing newer results.
            guard requestID == id else { return }
            state = products.isEmpty ? .empty : .results(products)
        } catch {
            guard requestID == id else { return }
            state = .error(error.localizedDescription)
        }
    }
}
SWIFT

cat > Sources/Search/SearchView.swift <<'SWIFT'
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
SWIFT

############################ ENQUIRY ############################

cat > Sources/Enquiry/Enquiry.swift <<'SWIFT'
import Foundation

struct Enquiry {
    let productID: Int
    let name: String
    let email: String
    let phone: String
    let message: String
}
SWIFT

cat > Sources/Enquiry/EnquiryService.swift <<'SWIFT'
import Foundation

protocol EnquiryService {
    func submit(_ enquiry: Enquiry) async throws
}
SWIFT

cat > Sources/Enquiry/MockEnquiryService.swift <<'SWIFT'
import Foundation

// Demo only: no network request and no contact details are persisted.
struct MockEnquiryService: EnquiryService {
    func submit(_ enquiry: Enquiry) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
SWIFT

cat > Sources/Enquiry/EnquiryViewModel.swift <<'SWIFT'
import SwiftUI

@MainActor
final class EnquiryViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var message = ""
    @Published var isSubmitting = false
    @Published var showThanks = false
    @Published var error: String?

    let product: Product
    private let service: EnquiryService

    init(product: Product, service: EnquiryService = MockEnquiryService()) {
        self.product = product
        self.service = service
    }

    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty
            && trimmedEmail.range(
                of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#,
                options: .regularExpression
            ) != nil
            && phone.filter { $0.isNumber }.count >= 8
    }

    func submit() async {
        guard isValid, !isSubmitting else { return }
        isSubmitting = true
        error = nil
        defer { isSubmitting = false }

        do {
            try await service.submit(
                Enquiry(
                    productID: product.id,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    phone: phone,
                    message: message
                )
            )
            showThanks = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
SWIFT

cat > Sources/Enquiry/EnquiryView.swift <<'SWIFT'
import SwiftUI

struct EnquiryView: View {
    @StateObject var vm: EnquiryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Demo form: no enquiry will be sent.")
                        .foregroundStyle(.secondary)
                }

                Section("Product") {
                    Text(vm.product.title)
                }

                Section("Contact details") {
                    TextField("Full name", text: $vm.name)
                        .textContentType(.name)
                    TextField("Email", text: $vm.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Phone", text: $vm.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Message (optional)") {
                    TextField("Your enquiry", text: $vm.message, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = vm.error {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await vm.submit() }
                    } label: {
                        HStack {
                            Text(vm.isSubmitting ? "Submitting…" : "Submit")
                            if vm.isSubmitting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(!vm.isValid || vm.isSubmitting)
                }
            }
            .navigationTitle("Enquiry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(vm.isSubmitting)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                }
            }
            .interactiveDismissDisabled(vm.isSubmitting)
            .alert("Thank you!", isPresented: $vm.showThanks) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your demo enquiry is complete. No enquiry was sent.")
            }
        }
    }
}
SWIFT

echo "Restructure complete. Now run: xcodegen generate"
