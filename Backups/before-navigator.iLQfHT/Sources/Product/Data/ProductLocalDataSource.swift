import Foundation

protocol ProductLocalDataSource {
    func all() async throws -> [Product]
    func save(_ products: [Product]) async throws
}
