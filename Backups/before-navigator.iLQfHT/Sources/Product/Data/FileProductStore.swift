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
