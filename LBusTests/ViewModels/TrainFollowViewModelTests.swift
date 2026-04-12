import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private func makeArrival(
    staId: String = "40380",
    stpId: String = "30070",
    staNm: String = "Clark/Lake",
    stpDe: String = "Service toward Howard",
    rn: String = "421",
    rt: String = "Red",
    destNm: String = "Howard",
    arrT: String = "2026-03-30T12:05:00",
    isApp: String = "0",
    isDly: String = "0",
    isSch: String = "0"
) -> TrainArrival {
    TrainArrival(from: TrainEtaPredictionDTO(
        staId: staId,
        stpId: stpId,
        staNm: staNm,
        stpDe: stpDe,
        rn: rn,
        rt: rt,
        destSt: "30173",
        destNm: destNm,
        trDr: "1",
        prdt: "2026-03-30T12:00:00",
        arrT: arrT,
        isApp: isApp,
        isSch: isSch,
        isDly: isDly,
        isFlt: "0",
        flags: nil,
        lat: nil,
        lon: nil,
        heading: nil
    ))
}

private func makeArrivals() -> [TrainArrival] {
    [
        makeArrival(staId: "40380", stpId: "30070", staNm: "Clark/Lake"),
        makeArrival(staId: "40430", stpId: "30080", staNm: "State/Lake"),
        makeArrival(staId: "40710", stpId: "30141", staNm: "Lake")
    ]
}

@MainActor
private func makeViewModel(
    arrivals: [TrainArrival]? = makeArrivals(),
    error: Error? = nil,
    originatingStationId: String = "40380"
) async -> (TrainFollowViewModel, MockTrainRepository) {
    let trainRepo = MockTrainRepository()
    if let arrivals { await trainRepo.setGetFollowResult(arrivals) }
    if let error { await trainRepo.setGetFollowError(error) }
    let vm = TrainFollowViewModel(
        runNumber: "421",
        originatingStationId: originatingStationId,
        trainRepository: trainRepo
    )
    return (vm, trainRepo)
}

@MainActor
private func makeViewModelWithMockRefresh(
    arrivals: [TrainArrival]? = makeArrivals(),
    error: Error? = nil,
    originatingStationId: String = "40380"
) async -> (TrainFollowViewModel, MockTrainRepository, MockAutoRefreshManager) {
    let trainRepo = MockTrainRepository()
    if let arrivals { await trainRepo.setGetFollowResult(arrivals) }
    if let error { await trainRepo.setGetFollowError(error) }
    let mockRefresh = MockAutoRefreshManager()
    let vm = TrainFollowViewModel(
        runNumber: "421",
        originatingStationId: originatingStationId,
        trainRepository: trainRepo,
        refreshManager: mockRefresh
    )
    return (vm, trainRepo, mockRefresh)
}

// MARK: - Tests

@Suite @MainActor struct TrainFollowViewModelTests {

    // MARK: - Loading

    @Test func loadStationsPopulatesStations() async {
        let (vm, _) = await makeViewModel()

        await vm.loadStations()

        #expect(vm.stations.count == 3)
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - Error handling

    @Test func loadStationsSetsErrorOnFailure() async {
        let (vm, _) = await makeViewModel(
            arrivals: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadStations()

        #expect(vm.stations.isEmpty)
        #expect(vm.error != nil)
    }

    @Test func loadStationsClearsErrorOnRetry() async {
        let (vm, trainRepo) = await makeViewModel(
            arrivals: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )
        await vm.loadStations()
        #expect(vm.error != nil)

        await trainRepo.setGetFollowError(nil)
        await trainRepo.setGetFollowResult(makeArrivals())
        await vm.loadStations()

        #expect(vm.error == nil)
        #expect(vm.stations.count == 3)
    }

    @Test func loadStationsKeepsCachedDataOnFailure() async {
        let (vm, trainRepo) = await makeViewModel()
        await vm.loadStations()
        #expect(vm.stations.count == 3)

        await trainRepo.setGetFollowResult(nil)
        await trainRepo.setGetFollowError(APIError.networkError(URLError(.notConnectedToInternet)))
        await vm.loadStations()

        #expect(vm.stations.count == 3)
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
            arrivals: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadStations()

        if case .error(let message) = vm.screenState {
            #expect(message.contains("Unable to load"))
        } else {
            Issue.record("Expected .error, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsLoadedWhenDataExists() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStations()

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsLoadedWhenStationsEmpty() async {
        let (vm, _) = await makeViewModel(arrivals: [])
        await vm.loadStations()

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded for empty stations, got \(vm.screenState)")
        }
    }

    // MARK: - Computed properties

    @Test func lineIsDerivedFromFirstStation() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStations()
        #expect(vm.line == "Red")
    }

    @Test func destinationIsDerivedFromFirstStation() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStations()
        #expect(vm.destinationName == "Howard")
    }

    // MARK: - Context

    @Test func originatingStationIdIsStoredFromInit() async {
        let (vm, _) = await makeViewModel()
        #expect(vm.originatingStationId == "40380")
    }

    @Test func loadStationsUsesRunNumberAsVehicleId() async {
        let (vm, trainRepo) = await makeViewModel()
        await vm.loadStations()
        let calledWith = await trainRepo.getFollowCalledWithVehicleId
        #expect(calledWith == "421")
    }

    // MARK: - Refresh integration (with MockAutoRefreshManager)

    @Test func startAutoRefreshCallsStart() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()
        vm.startAutoRefresh()
        #expect(mockRefresh.startCallCount == 1)
    }

    @Test func stopAutoRefreshCallsStop() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()
        vm.stopAutoRefresh()
        #expect(mockRefresh.stopCallCount == 1)
    }

    @Test func manualRefreshRoutesThrough() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()
        await vm.manualRefresh()
        #expect(mockRefresh.refreshNowCallCount == 1)
    }

    @Test func lastUpdatedPassthrough() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()

        #expect(vm.lastUpdated == nil)
        let now = Date()
        mockRefresh.lastUpdated = now
        #expect(vm.lastUpdated == now)
    }

    @Test func isRefreshingPassthrough() async {
        let (vm, _, mockRefresh) = await makeViewModelWithMockRefresh()

        #expect(vm.isRefreshing == false)
        mockRefresh.isRefreshing = true
        #expect(vm.isRefreshing == true)
    }

    // MARK: - Location unavailable handling

    @Test func apiErrorUnableToDetermineShowsEmptyLoaded() async {
        let (vm, _) = await makeViewModel(
            arrivals: nil,
            error: APIError.apiError(message: "Unable to determine upcoming stops.")
        )

        await vm.loadStations()

        #expect(vm.stations.isEmpty)
        #expect(vm.error == nil)
        #expect(vm.isLocationUnavailable == true)
        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded for unable-to-determine, got \(vm.screenState)")
        }
    }

    @Test func otherApiErrorShowsErrorState() async {
        let (vm, _) = await makeViewModel(
            arrivals: nil,
            error: APIError.apiError(message: "Invalid run number")
        )

        await vm.loadStations()

        #expect(vm.stations.isEmpty)
        #expect(vm.error != nil)
        #expect(vm.isLocationUnavailable == false)
        if case .error = vm.screenState {} else {
            Issue.record("Expected .error for non-determine API error, got \(vm.screenState)")
        }
    }

    @Test func apiErrorUnableToDetermineClearsCachedStations() async {
        let (vm, trainRepo) = await makeViewModel()
        await vm.loadStations()
        #expect(vm.stations.count == 3)

        await trainRepo.setGetFollowResult(nil)
        await trainRepo.setGetFollowError(APIError.apiError(message: "Unable to determine upcoming stops."))
        await vm.loadStations()

        #expect(vm.stations.isEmpty)
        #expect(vm.error == nil)
        #expect(vm.isLocationUnavailable == true)
        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded after unable-to-determine clears data, got \(vm.screenState)")
        }
    }

    @Test func normalEmptyResponseKeepsLocationAvailable() async {
        let (vm, _) = await makeViewModel(arrivals: [])

        await vm.loadStations()

        #expect(vm.stations.isEmpty)
        #expect(vm.error == nil)
        #expect(vm.isLocationUnavailable == false)
        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded for normal empty, got \(vm.screenState)")
        }
    }
}
