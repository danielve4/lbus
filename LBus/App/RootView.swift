import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKeys.theme) private var theme: AppTheme = .system
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack {
                    HomePlaceholderView()
                }
            }
            Tab("Routes", systemImage: "bus", value: .routes) {
                NavigationStack {
                    RoutesPlaceholderView()
                        .modifier(TransitNavigationDestinations())
                }
            }
            Tab("Favorites", systemImage: "star", value: .favorites) {
                NavigationStack {
                    FavoritesPlaceholderView()
                        .modifier(TransitNavigationDestinations())
                }
            }
            Tab("Settings", systemImage: "gear", value: .settings) {
                NavigationStack {
                    SettingsView(favoritesRepository: makeFavoritesRepository())
                }
            }
        }
        .preferredColorScheme(theme.colorScheme)
    }

    private func makeFavoritesRepository() -> FavoritesRepository {
        FavoritesRepository(
            modelContext: modelContext,
            apiClient: APIClient(),
            deviceIdentifier: DeviceIdentifier()
        )
    }
}

#Preview {
    RootView()
}
