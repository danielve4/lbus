import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKeys.theme) private var theme: AppTheme = .system
    @State private var selectedTab: AppTab = .home

    private let apiClient: APIClient
    private let busRepository: BusRepository
    private let trainRepository: TrainRepository

    init() {
        let client = APIClient()
        self.apiClient = client
        self.busRepository = BusRepository(apiClient: client)
        self.trainRepository = TrainRepository(apiClient: client)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack {
                    HomePlaceholderView()
                }
            }
            Tab("Routes", systemImage: "bus", value: .routes) {
                NavigationStack {
                    RoutesView(
                        busRepository: busRepository,
                        trainRepository: trainRepository
                    )
                    .modifier(TransitNavigationDestinations(busRepository: busRepository, trainRepository: trainRepository))
                }
            }
            Tab("Favorites", systemImage: "star", value: .favorites) {
                NavigationStack {
                    FavoritesPlaceholderView()
                        .modifier(TransitNavigationDestinations(busRepository: busRepository, trainRepository: trainRepository))
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
            apiClient: apiClient,
            deviceIdentifier: DeviceIdentifier()
        )
    }
}

#Preview {
    RootView()
}
