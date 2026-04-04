import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKeys.theme) private var theme: AppTheme = .system
    @State private var selectedTab: AppTab = .favorites
    @State private var favoritesRepository: FavoritesRepository?

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
        Group {
            if let favoritesRepository {
                mainContent(favoritesRepository: favoritesRepository)
            } else {
                Color.clear
            }
        }
        .task {
            if favoritesRepository == nil {
                favoritesRepository = FavoritesRepository(
                    modelContext: modelContext,
                    apiClient: apiClient,
                    deviceIdentifier: DeviceIdentifier()
                )
            }
        }
        .preferredColorScheme(theme.colorScheme)
    }

    private func mainContent(favoritesRepository: FavoritesRepository) -> some View {
        TabView(selection: $selectedTab) {
            Tab("Favorites", systemImage: "star", value: .favorites) {
                NavigationStack {
                    FavoritesView(
                        favoritesRepository: favoritesRepository,
                        onExploreRoutes: { selectedTab = .search }
                    )
                    .modifier(TransitNavigationDestinations(
                        busRepository: busRepository,
                        trainRepository: trainRepository,
                        favoritesRepository: favoritesRepository
                    ))
                }
            }
            Tab(value: .search, role: .search) {
                NavigationStack {
                    RoutesView(
                        busRepository: busRepository,
                        trainRepository: trainRepository
                    )
                    .modifier(TransitNavigationDestinations(
                        busRepository: busRepository,
                        trainRepository: trainRepository,
                        favoritesRepository: favoritesRepository
                    ))
                }
            }
            Tab("Settings", systemImage: "gear", value: .settings) {
                NavigationStack {
                    SettingsView(favoritesRepository: favoritesRepository)
                }
            }
        }
    }
}

#Preview {
    RootView()
}
