import XCTest
@testable import CatalogueApp

final class ProductRepositoryTests: XCTestCase {
    func testLocalSearchDoesNotFetchBackend() async throws {
        let product = makeProduct(title: "Running Shoes")
        let local = MemoryStore(products: [product])
        let remote = RemoteStub(products: [])
        let repository = DefaultProductRepository(remote: remote, local: local)

        let results = try await repository.search(" shoes ")

        XCTAssertEqual(results, [product])
        let calls = await remote.allFetchCount()
        XCTAssertEqual(calls, 0)
    }

    func testLocalMissFetchesAndPersistsBackendProducts() async throws {
        let product = makeProduct(title: "Sports Watch")
        let local = MemoryStore(products: [])
        let remote = RemoteStub(products: [product])
        let repository = DefaultProductRepository(remote: remote, local: local)

        let results = try await repository.search("WATCH")

        XCTAssertEqual(results, [product])
        let calls = await remote.allFetchCount()
        XCTAssertEqual(calls, 1)
        let saved = try await local.all()
        XCTAssertEqual(saved, [product])
    }

    func testBlankQueryDoesNotFetchBackend() async throws {
        let local = MemoryStore(products: [])
        let remote = RemoteStub(products: [])
        let repository = DefaultProductRepository(remote: remote, local: local)

        let results = try await repository.search(" \n ")

        XCTAssertTrue(results.isEmpty)
        let calls = await remote.allFetchCount()
        XCTAssertEqual(calls, 0)
    }

    private func makeProduct(title: String) -> Product {
        Product(
            id: 1,
            title: title,
            price: 49.99,
            description: "Test product",
            category: "electronics",
            image: "https://example.com/product.png",
            rating: .init(rate: 4.5, count: 10)
        )
    }
}

private actor MemoryStore: ProductLocalDataSource {
    private var products: [Product]

    init(products: [Product]) {
        self.products = products
    }

    func all() async throws -> [Product] {
        products
    }

    func save(_ incoming: [Product]) async throws {
        for product in incoming {
            products.removeAll { $0.id == product.id }
            products.append(product)
        }
    }
}

private actor RemoteStub: ProductRemoteDataSource {
    private let products: [Product]
    private var fetchCount = 0

    init(products: [Product]) {
        self.products = products
    }

    func fetchCategories() async throws -> [String] {
        Array(Set(products.map(\.category))).sorted()
    }

    func fetchAll() async throws -> [Product] {
        fetchCount += 1
        return products
    }

    func fetch(category: String) async throws -> [Product] {
        products.filter { $0.category == category }
    }

    func allFetchCount() -> Int {
        fetchCount
    }
}
