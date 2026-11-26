import SwiftUI

@main
struct CatalogueApp: App {
    @StateObject private var container = AppContainer(
        productRemoteDataSource: FakeStoreAPI(),
        productLocalDataSource: FileProductStore())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
        }
    }
}
