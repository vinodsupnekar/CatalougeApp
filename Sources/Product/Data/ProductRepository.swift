import Foundation

protocol ProductRepository {
    func categories() async throws -> [String]
    func products(for categories: [String]) async throws -> [Product]
    func search(_ query: String) async throws -> [Product]
}
