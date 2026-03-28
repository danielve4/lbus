import SwiftUI

struct RootView: View {
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
                    SettingsPlaceholderView()
                }
            }
        }
    }
}

#Preview {
    RootView()
}
