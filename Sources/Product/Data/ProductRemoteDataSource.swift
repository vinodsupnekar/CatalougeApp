import Foundation

protocol ProductRemoteDataSource {
    func fetchCategories() async throws -> [String]
    func fetchAll() async throws -> [Product]
    func fetch(category: String) async throws -> [Product]
}
