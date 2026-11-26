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
