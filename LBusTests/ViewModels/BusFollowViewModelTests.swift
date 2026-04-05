import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private func makeStop(
    vehicleId: String = "8184",
    stopId: String = "456",
    stopName: String = "Madison & Jefferson",
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
        stopName: stopName,
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

private func makeStops() -> [BusArrival] {
    [
        makeStop(stopId: "100", stopName: "Stop A", countdown: .minutes(3)),
        makeStop(stopId: "200", stopName: "Stop B", countdown: .minutes(8)),
        makeStop(stopId: "300", stopName: "Stop C", countdown: .minutes(14))
    ]
}

@MainActor
private func makeViewModel(
    stops: [BusArrival]? = makeStops(),
    error: Error? = nil,
    originatingStopId: String = "100"
) async -> (BusFollowViewModel, MockBusRepository) {
    let busRepo = MockBusRepository()
    if let stops { await busRepo.setGetFollowResult(stops) }
    if let error { await busRepo.setGetFollowError(error) }
    let vm = BusFollowViewModel(
        vehicleId: "8184",
        originatingStopId: originatingStopId,
        busRepository: busRepo
    )
    return (vm, busRepo)
}

@MainActor
private func makeViewModelWithMockRefresh(
    stops: [BusArrival]? = makeStops(),
    error: Error? = nil,
    originatingStopId: String = "100"
) async -> (BusFollowViewModel, MockBusRepository, MockAutoRefreshManager) {
    let busRepo = MockBusRepository()
    if let stops { await busRepo.setGetFollowResult(stops) }
    if let error { await busRepo.setGetFollowError(error) }
    let mockRefresh = MockAutoRefreshManager()
    let vm = BusFollowViewModel(
        vehicleId: "8184",
        originatingStopId: originatingStopId,
        busRepository: busRepo,
        refreshManager: mockRefresh
    )
    return (vm, busRepo, mockRefresh)
}

// MARK: - Tests

@Suite @MainActor struct BusFollowViewModelTests {

    // MARK: - Loading

    @Test func loadStopsPopulatesStops() async {
        let (vm, _) = await makeViewModel()

        await vm.loadStops()

        #expect(vm.stops.count == 3)
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    @Test func isLoadingIsFalseAfterLoadCompletes() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStops()
        #expect(vm.isLoading == false)
    }

    // MARK: - Error handling

    @Test func loadStopsSetsErrorOnFailure() async {
        let (vm, _) = await makeViewModel(
            stops: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadStops()

        #expect(vm.stops.isEmpty)
        #expect(vm.error != nil)
    }

    @Test func loadStopsClearsErrorOnRetry() async {
        let (vm, busRepo) = await makeViewModel(
            stops: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )
        await vm.loadStops()
        #expect(vm.error != nil)

        await busRepo.setGetFollowError(nil)
        await busRepo.setGetFollowResult(makeStops())
        await vm.loadStops()

        #expect(vm.error == nil)
        #expect(vm.stops.count == 3)
    }

    @Test func loadStopsKeepsCachedDataOnFailure() async {
        let (vm, busRepo) = await makeViewModel()
        await vm.loadStops()
        #expect(vm.stops.count == 3)

        await busRepo.setGetFollowResult(nil)
        await busRepo.setGetFollowError(APIError.networkError(URLError(.notConnectedToInternet)))
        await vm.loadStops()

        #expect(vm.stops.count == 3)
        #expect(vm.error != nil)
        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded when cached data exists, got \(vm.screenState)")
        }
    }

    // MARK: - Screen state

    @Test func screenStateIsLoadingBeforeFirstFetch() async {
        let (vm, _) = await makeViewModel()
        if case .loading = vm.screenState {} else {
            Issue.record("Expected .loading, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsErrorWhenErrorWithNoData() async {
        let (vm, _) = await makeViewModel(
            stops: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadStops()

        if case .error(let message) = vm.screenState {
            #expect(message.contains("Unable to load"))
        } else {
            Issue.record("Expected .error, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsLoadedWhenDataExists() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStops()

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsLoadedWhenStopsEmpty() async {
        let (vm, _) = await makeViewModel(stops: [])
        await vm.loadStops()

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded for empty stops, got \(vm.screenState)")
        }
    }

    // MARK: - Computed properties

    @Test func routeIsNilBeforeLoad() async {
        let (vm, _) = await makeViewModel()
        #expect(vm.route == nil)
    }

    @Test func routeIsDerivedFromFirstStop() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStops()
        #expect(vm.route == "20")
    }

    @Test func directionIsDerivedFromFirstStop() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStops()
        #expect(vm.routeDirection == "Westbound")
    }

    @Test func destinationIsDerivedFromFirstStop() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStops()
        #expect(vm.destination == "Austin")
    }

    // MARK: - Context

    @Test func originatingStopIdIsStoredFromInit() async {
        let (vm, _) = await makeViewModel()
        #expect(vm.originatingStopId == "100")
    }

    @Test func loadStopsUsesVehicleId() async {
        let (vm, busRepo) = await makeViewModel()
        await vm.loadStops()
        let calledWith = await busRepo.getFollowCalledWithVehicleId
        #expect(calledWith == "8184")
    }

    // MARK: - Refresh seam (with MockAutoRefreshManager)

    @Test func startAutoRefreshCallsStartOnManager() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()
        vm.startAutoRefresh()
        #expect(mockRefresh.startCallCount == 1)
    }

    @Test func stopAutoRefreshCallsStopOnManager() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()
        vm.stopAutoRefresh()
        #expect(mockRefresh.stopCallCount == 1)
    }

    @Test func manualRefreshRoutesThoughRefreshManager() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()
        await vm.manualRefresh()
        #expect(mockRefresh.refreshNowCallCount == 1)
    }

    @Test func initialLoadRoutesThoughRefreshManager() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()
        await vm.initialLoad()
        #expect(mockRefresh.refreshNowCallCount == 1)
    }

    @Test func lastUpdatedPassesThroughFromRefreshManager() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()

        #expect(vm.lastUpdated == nil)
        let now = Date()
        mockRefresh.lastUpdated = now
        #expect(vm.lastUpdated == now)
    }

    @Test func isRefreshingPassesThroughFromRefreshManager() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()

        #expect(vm.isRefreshing == false)
        mockRefresh.isRefreshing = true
        #expect(vm.isRefreshing == true)
    }
}
