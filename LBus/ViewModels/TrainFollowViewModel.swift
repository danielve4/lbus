import Foundation

@MainActor
@Observable
final class TrainFollowViewModel {

    enum ScreenState {
        case loading
        case error(String)
        case loaded
    }

    private(set) var stations: [TrainArrival] = []
    private(set) var isLoading = true
    private(set) var error: String? = nil
    private(set) var isLocationUnavailable = false

    let runNumber: String
    let originatingStationId: String

    private let trainRepository: TrainRepositoryProtocol
    private(set) var refreshManager: AutoRefreshManagerProtocol
    private var isFetching = false
    private var lastFetchError: Error?
    private var hasCompletedInitialLoad = false

    init(
        runNumber: String,
        originatingStationId: String,
        trainRepository: TrainRepositoryProtocol,
        refreshManager: AutoRefreshManagerProtocol? = nil
    ) {
        self.runNumber = runNumber
        self.originatingStationId = originatingStationId
        self.trainRepository = trainRepository

        // @Observable requires all backing stores initialized before capturing self.
        // Assign a throwaway first, then replace with the real manager that captures self.
        self.refreshManager = refreshManager ?? AutoRefreshManager(action: { })

        if refreshManager == nil {
            self.refreshManager = AutoRefreshManager { [weak self] in
                try await self?.fetchStations() ?? ()
            }
        }
    }

    var screenState: ScreenState {
        if isLoading && stations.isEmpty && !hasCompletedInitialLoad { return .loading }
        if let error, stations.isEmpty { return .error(error) }
        return .loaded
    }

    var line: String? { stations.first?.line }
    var destinationName: String? { stations.first?.destinationName }
    var lastUpdated: Date? { refreshManager.lastUpdated }
    var isRefreshing: Bool { refreshManager.isRefreshing }

    var emptyStateMessage: String {
        isLocationUnavailable
            ? "Unable to load train location"
            : "No upcoming stations predicted for this train right now."
    }

    // MARK: - Lifecycle

    func initialLoad() async {
        await loadStations()
    }

    func startAutoRefresh() {
        refreshManager.start()
    }

    func stopAutoRefresh() {
        refreshManager.stop()
    }

    func manualRefresh() async {
        await loadStations()
    }

    // MARK: - Data Loading

    func loadStations() async {
        guard !isFetching else { return }
        isFetching = true
        isLoading = true
        error = nil
        lastFetchError = nil

        await refreshManager.refreshNow()

        if lastFetchError != nil {
            self.error = "Unable to load stations. Check your connection and try again."
        }

        isLoading = false
        isFetching = false
        if lastFetchError == nil {
            hasCompletedInitialLoad = true
        }
    }

    /// Throwing fetch used as the AutoRefreshManager action.
    private func fetchStations() async throws {
        do {
            stations = try await trainRepository.getFollow(vehicleId: runNumber)
            isLocationUnavailable = false
        } catch let error as APIError {
            if case .apiError(let message) = error,
               message.localizedCaseInsensitiveContains("unable to determine") {
                stations = []
                isLocationUnavailable = true
                return   // do NOT throw — this is a successful empty refresh
            }
            lastFetchError = error
            throw error
        } catch {
            lastFetchError = error
            throw error
        }
    }
}
