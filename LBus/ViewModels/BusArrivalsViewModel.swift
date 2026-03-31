import Foundation

@MainActor
@Observable
final class BusArrivalsViewModel {

    enum ScreenState {
        case loading
        case error(String)
        case loaded
    }

    private(set) var arrivals: [BusArrival] = []
    private(set) var isLoading = true
    private(set) var error: String? = nil
    private(set) var isFavorite: Bool = false

    let stopId: String
    let stopName: String
    let route: String
    let direction: String

    private let busRepository: BusRepositoryProtocol
    private let favoritesRepository: FavoritesRepositoryProtocol
    private(set) var refreshManager: AutoRefreshManagerProtocol
    private var isFetching = false
    private var lastFetchError: Error?

    init(
        stopId: String,
        stopName: String,
        route: String,
        direction: String,
        busRepository: BusRepositoryProtocol,
        favoritesRepository: FavoritesRepositoryProtocol,
        refreshManager: AutoRefreshManagerProtocol? = nil
    ) {
        self.stopId = stopId
        self.stopName = stopName
        self.route = route
        self.direction = direction
        self.busRepository = busRepository
        self.favoritesRepository = favoritesRepository

        // @Observable requires all backing stores initialized before capturing self.
        // Assign a throwaway first, then replace with the real manager that captures self.
        self.refreshManager = refreshManager ?? AutoRefreshManager(action: { })

        if refreshManager == nil {
            self.refreshManager = AutoRefreshManager { [weak self] in
                try await self?.fetchArrivals() ?? ()
            }
        }
    }

    var screenState: ScreenState {
        if isLoading && arrivals.isEmpty { return .loading }
        if let error, arrivals.isEmpty { return .error(error) }
        return .loaded
    }

    var lastUpdated: Date? { refreshManager.lastUpdated }
    var isRefreshing: Bool { refreshManager.isRefreshing }

    // MARK: - Lifecycle

    func initialLoad() async {
        await loadArrivals()
        loadFavoriteState()
    }

    func startAutoRefresh() {
        refreshManager.start()
    }

    func stopAutoRefresh() {
        refreshManager.stop()
    }

    func manualRefresh() async {
        await loadArrivals()
    }

    // MARK: - Data Loading

    func loadArrivals() async {
        guard !isFetching else { return }
        isFetching = true
        isLoading = true
        error = nil
        lastFetchError = nil

        await refreshManager.refreshNow()

        if lastFetchError != nil {
            self.error = "Unable to load arrivals. Check your connection and try again."
        }

        isLoading = false
        isFetching = false
    }

    /// Throwing fetch used as the AutoRefreshManager action.
    /// Errors propagate so the manager correctly withholds `lastUpdated` on failure.
    /// Stores errors in `lastFetchError` so `loadArrivals()` can surface them to the UI.
    private func fetchArrivals() async throws {
        do {
            arrivals = try await busRepository.getArrivals(stopId: stopId)
        } catch {
            lastFetchError = error
            throw error
        }
    }

    // MARK: - Favorites

    private var favorite: Favorite {
        .bus(BusFavorite(route: route, stopId: stopId, stopName: stopName, direction: direction))
    }

    func loadFavoriteState() {
        isFavorite = favoritesRepository.contains(favorite)
    }

    func toggleFavorite() {
        do {
            if isFavorite {
                try favoritesRepository.remove(favorite)
            } else {
                try favoritesRepository.add(favorite)
            }
            isFavorite.toggle()
        } catch {
            // Silently fail — state reverts on next loadFavoriteState()
        }
    }
}
