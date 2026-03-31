import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private func makeArrival(
    vehicleId: String = "8184",
    stopId: String = "456",
    route: String = "20",
    routeDirection: String = "Westbound",
    destination: String = "Austin",
    distanceToStop: Int = 686,
    isDelayed: Bool = false,
    countdown: ArrivalCountdown = .minutes(5),
    predictedArrival: Date = Date().addingTimeInterval(300)
) -> BusArrival {
    BusArrival(
        timestamp: Date(),
        stopId: stopId,
        stopName: "Madison & Jefferson",
        vehicleId: vehicleId,
        distanceToStop: distanceToStop,
        route: route,
        routeDirection: routeDirection,
        destination: destination,
        predictedArrival: predictedArrival,
        isDelayed: isDelayed,
        countdown: countdown
    )
}

private func makeArrivals() -> [BusArrival] {
    [
        makeArrival(vehicleId: "8184", destination: "Austin", countdown: .minutes(5)),
        makeArrival(vehicleId: "8200", destination: "Austin", countdown: .minutes(12)),
        makeArrival(vehicleId: "8210", destination: "Austin", countdown: .due)
    ]
}

/// Creates a ViewModel with the real AutoRefreshManager (for data-loading tests).
@MainActor
private func makeViewModel(
    arrivals: [BusArrival]? = makeArrivals(),
    error: Error? = nil,
    favorites: [Favorite] = []
) async -> (BusArrivalsViewModel, MockBusRepository, MockFavoritesRepository) {
    let busRepo = MockBusRepository()
    if let arrivals { await busRepo.setGetArrivalsResult(arrivals) }
    if let error { await busRepo.setGetArrivalsError(error) }
    let favRepo = MockFavoritesRepository()
    for fav in favorites { try? favRepo.add(fav) }
    let vm = BusArrivalsViewModel(
        stopId: "456",
        stopName: "Madison & Jefferson",
        route: "20",
        direction: "Westbound",
        busRepository: busRepo,
        favoritesRepository: favRepo
    )
    return (vm, busRepo, favRepo)
}

/// Creates a ViewModel with an injected MockAutoRefreshManager (for refresh-seam tests).
@MainActor
private func makeViewModelWithMockRefresh(
    arrivals: [BusArrival]? = makeArrivals(),
    error: Error? = nil,
    favorites: [Favorite] = []
) async -> (BusArrivalsViewModel, MockBusRepository, MockFavoritesRepository, MockAutoRefreshManager) {
    let busRepo = MockBusRepository()
    if let arrivals { await busRepo.setGetArrivalsResult(arrivals) }
    if let error { await busRepo.setGetArrivalsError(error) }
    let favRepo = MockFavoritesRepository()
    for fav in favorites { try? favRepo.add(fav) }
    let mockRefresh = MockAutoRefreshManager()
    let vm = BusArrivalsViewModel(
        stopId: "456",
        stopName: "Madison & Jefferson",
        route: "20",
        direction: "Westbound",
        busRepository: busRepo,
        favoritesRepository: favRepo,
        refreshManager: mockRefresh
    )
    return (vm, busRepo, favRepo, mockRefresh)
}

// MARK: - Tests

@Suite @MainActor struct BusArrivalsViewModelTests {

    // MARK: - Loading

    @Test func loadArrivalsPopulatesArrivals() async {
        let (vm, _, _) = await makeViewModel()

        await vm.loadArrivals()

        #expect(vm.arrivals.count == 3)
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    @Test func isLoadingIsFalseAfterLoadCompletes() async {
        let (vm, _, _) = await makeViewModel()
        await vm.loadArrivals()
        #expect(vm.isLoading == false)
    }

    // MARK: - Error handling

    @Test func loadArrivalsSetsErrorOnFailure() async {
        let (vm, _, _) = await makeViewModel(
            arrivals: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadArrivals()

        #expect(vm.arrivals.isEmpty)
        #expect(vm.error != nil)
    }

    @Test func loadArrivalsClearsErrorOnRetry() async {
        let (vm, busRepo, _) = await makeViewModel(
            arrivals: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )
        await vm.loadArrivals()
        #expect(vm.error != nil)

        await busRepo.setGetArrivalsError(nil)
        await busRepo.setGetArrivalsResult(makeArrivals())
        await vm.loadArrivals()

        #expect(vm.error == nil)
        #expect(vm.arrivals.count == 3)
    }

    @Test func loadArrivalsKeepsCachedDataOnFailure() async {
        let (vm, busRepo, _) = await makeViewModel()
        await vm.loadArrivals()
        #expect(vm.arrivals.count == 3)

        await busRepo.setGetArrivalsResult(nil)
        await busRepo.setGetArrivalsError(APIError.networkError(URLError(.notConnectedToInternet)))
        await vm.loadArrivals()

        #expect(vm.arrivals.count == 3)
        #expect(vm.error != nil)
        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded when cached data exists, got \(vm.screenState)")
        }
    }

    // MARK: - Screen state

    @Test func screenStateIsLoadingBeforeFirstFetch() async {
        let (vm, _, _) = await makeViewModel()
        if case .loading = vm.screenState {} else {
            Issue.record("Expected .loading, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsErrorWhenErrorWithNoData() async {
        let (vm, _, _) = await makeViewModel(
            arrivals: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadArrivals()

        if case .error(let message) = vm.screenState {
            #expect(message.contains("Unable to load"))
        } else {
            Issue.record("Expected .error, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsLoadedWhenDataExists() async {
        let (vm, _, _) = await makeViewModel()
        await vm.loadArrivals()

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsLoadedWhenArrivalsEmpty() async {
        let (vm, _, _) = await makeViewModel(arrivals: [])
        await vm.loadArrivals()

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded for empty arrivals, got \(vm.screenState)")
        }
    }

    // MARK: - Context

    @Test func stopContextIsAccessibleAfterInit() async {
        let (vm, _, _) = await makeViewModel()
        #expect(vm.stopId == "456")
        #expect(vm.stopName == "Madison & Jefferson")
        #expect(vm.route == "20")
        #expect(vm.direction == "Westbound")
    }

    @Test func loadArrivalsUsesStopId() async {
        let (vm, busRepo, _) = await makeViewModel()
        await vm.loadArrivals()
        let calledWith = await busRepo.getArrivalsCalledWithStopId
        #expect(calledWith == "456")
    }

    // MARK: - Favorites

    @Test func isFavoriteReturnsFalseByDefault() async {
        let (vm, _, _) = await makeViewModel()
        await vm.initialLoad()
        #expect(vm.isFavorite == false)
    }

    @Test func isFavoriteReturnsTrueWhenPreSeeded() async {
        let favorite = Favorite.bus(BusFavorite(route: "20", stopId: "456", stopName: "Madison & Jefferson", direction: "Westbound"))
        let (vm, _, _) = await makeViewModel(favorites: [favorite])
        await vm.initialLoad()
        #expect(vm.isFavorite == true)
    }

    @Test func toggleFavoriteAddsFavorite() async {
        let (vm, _, favRepo) = await makeViewModel()
        await vm.initialLoad()
        #expect(vm.isFavorite == false)

        vm.toggleFavorite()

        #expect(vm.isFavorite == true)
        let expected = Favorite.bus(BusFavorite(route: "20", stopId: "456", stopName: "Madison & Jefferson", direction: "Westbound"))
        #expect(favRepo.contains(expected))
    }

    @Test func toggleFavoriteRemovesFavorite() async {
        let favorite = Favorite.bus(BusFavorite(route: "20", stopId: "456", stopName: "Madison & Jefferson", direction: "Westbound"))
        let (vm, _, favRepo) = await makeViewModel(favorites: [favorite])
        await vm.initialLoad()
        #expect(vm.isFavorite == true)

        vm.toggleFavorite()

        #expect(vm.isFavorite == false)
        #expect(!favRepo.contains(favorite))
    }

    // MARK: - initialLoad composite behavior

    @Test func initialLoadPopulatesArrivalsAndFavoriteState() async {
        let favorite = Favorite.bus(BusFavorite(route: "20", stopId: "456", stopName: "Madison & Jefferson", direction: "Westbound"))
        let (vm, _, _) = await makeViewModel(favorites: [favorite])

        await vm.initialLoad()

        #expect(vm.arrivals.count == 3)
        #expect(vm.isFavorite == true)
    }

    // MARK: - Refresh routes through manager

    @Test func loadArrivalsSetsLastUpdatedOnSuccess() async {
        let (vm, _, _) = await makeViewModel()
        #expect(vm.lastUpdated == nil)

        await vm.loadArrivals()

        #expect(vm.lastUpdated != nil)
    }

    @Test func loadArrivalsDoesNotSetLastUpdatedOnFailure() async {
        let (vm, _, _) = await makeViewModel(
            arrivals: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadArrivals()

        #expect(vm.lastUpdated == nil)
        #expect(vm.error != nil)
    }

    // MARK: - Refresh seam (with MockAutoRefreshManager)

    @Test func startAutoRefreshCallsStartOnManager() async {
        let (vm, _, _, mockRefresh) = await makeViewModelWithMockRefresh()
        vm.startAutoRefresh()
        #expect(mockRefresh.startCallCount == 1)
    }

    @Test func stopAutoRefreshCallsStopOnManager() async {
        let (vm, _, _, mockRefresh) = await makeViewModelWithMockRefresh()
        vm.stopAutoRefresh()
        #expect(mockRefresh.stopCallCount == 1)
    }

    @Test func manualRefreshRoutesThoughRefreshManager() async {
        let (vm, _, _, mockRefresh) = await makeViewModelWithMockRefresh()
        await vm.manualRefresh()
        #expect(mockRefresh.refreshNowCallCount == 1)
    }

    @Test func initialLoadRoutesThoughRefreshManager() async {
        let (vm, _, _, mockRefresh) = await makeViewModelWithMockRefresh()
        await vm.initialLoad()
        #expect(mockRefresh.refreshNowCallCount == 1)
    }

    @Test func lastUpdatedPassesThroughFromRefreshManager() async {
        let (vm, _, _, mockRefresh) = await makeViewModelWithMockRefresh()

        #expect(vm.lastUpdated == nil)
        let now = Date()
        mockRefresh.lastUpdated = now
        #expect(vm.lastUpdated == now)
    }

    @Test func isRefreshingPassesThroughFromRefreshManager() async {
        let (vm, _, _, mockRefresh) = await makeViewModelWithMockRefresh()

        #expect(vm.isRefreshing == false)
        mockRefresh.isRefreshing = true
        #expect(vm.isRefreshing == true)
    }
}
