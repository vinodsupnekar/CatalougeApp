import Foundation

struct CategorySection: Identifiable {
    var id: String { name }
    let name: String
    let products: [Product]
}
