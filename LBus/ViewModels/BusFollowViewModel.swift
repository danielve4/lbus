import Foundation

@MainActor
@Observable
final class BusFollowViewModel {

    enum ScreenState {
        case loading
        case error(String)
        case loaded
    }

    private(set) var stops: [BusArrival] = []
    private(set) var isLoading = true
    private(set) var error: String? = nil
    private(set) var refreshCount: Int = 0

    let vehicleId: String
    let originatingStopId: String

    private let busRepository: BusRepositoryProtocol
    private(set) var refreshManager: AutoRefreshManagerProtocol
    private var isFetching = false
    private var lastFetchError: Error?
    private var hasCompletedInitialLoad = false

    init(
        vehicleId: String,
        originatingStopId: String,
        busRepository: BusRepositoryProtocol,
        refreshManager: AutoRefreshManagerProtocol? = nil
    ) {
        self.vehicleId = vehicleId
        self.originatingStopId = originatingStopId
        self.busRepository = busRepository

        // @Observable requires all backing stores initialized before capturing self.
        // Assign a throwaway first, then replace with the real manager that captures self.
        self.refreshManager = refreshManager ?? AutoRefreshManager(action: { })

        if refreshManager == nil {
            self.refreshManager = AutoRefreshManager { [weak self] in
                try await self?.fetchStops() ?? ()
            }
        }
    }

    var screenState: ScreenState {
        if isLoading && stops.isEmpty && !hasCompletedInitialLoad { return .loading }
        if let error, stops.isEmpty { return .error(error) }
        return .loaded
    }

    var route: String? { stops.first?.route }
    var routeDirection: String? { stops.first?.routeDirection }
    var destination: String? { stops.first?.destination }
    var lastUpdated: Date? { refreshManager.lastUpdated }
    var isRefreshing: Bool { refreshManager.isRefreshing }

    // MARK: - Lifecycle

    func initialLoad() async {
        await loadStops()
    }

    func startAutoRefresh() {
        refreshManager.start()
    }

    func stopAutoRefresh() {
        refreshManager.stop()
    }

    func manualRefresh() async {
        await loadStops()
    }

    // MARK: - Data Loading

    func loadStops() async {
        guard !isFetching else { return }
        isFetching = true
        isLoading = true
        error = nil
        lastFetchError = nil

        await refreshManager.refreshNow()

        if lastFetchError != nil {
            self.error = "Unable to load stops. Check your connection and try again."
        }

        isLoading = false
        isFetching = false
        if lastFetchError == nil {
            hasCompletedInitialLoad = true
        }
    }

    /// Throwing fetch used as the AutoRefreshManager action.
    private func fetchStops() async throws {
        let hadStops = !stops.isEmpty
        do {
            stops = try await busRepository.getFollow(vehicleId: vehicleId)
            if hadStops {
                refreshCount += 1
            }
        } catch {
            lastFetchError = error
            throw error
        }
    }
}
