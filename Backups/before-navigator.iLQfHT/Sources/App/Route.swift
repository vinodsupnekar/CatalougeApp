import Foundation

enum Route: Hashable {
    case search
    case category(String)
    case product(Product)
}
