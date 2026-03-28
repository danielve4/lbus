import SwiftUI
import SwiftData

@main
struct LBusApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: FavoritePersisted.self)
    }
}
