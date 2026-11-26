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
