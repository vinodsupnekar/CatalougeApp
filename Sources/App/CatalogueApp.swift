import SwiftUI

@main
struct CatalogueApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environmentObject(container.navigator)
        }
    }
}
