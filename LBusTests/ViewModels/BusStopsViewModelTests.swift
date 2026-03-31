import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private func makeBusRoute() -> BusRoute {
    BusRoute(id: "20", name: "Madison", colorHex: "#336633", shortName: "20 Madison")
}

private func makeStops() -> [BusStop] {
    [
        BusStop(id: "1001", name: "Madison & Pulaski", latitude: 41.88, longitude: -87.72),
        BusStop(id: "1002", name: "Madison & Cicero", latitude: 41.88, longitude: -87.74),
        BusStop(id: "1003", name: "Madison & Central", latitude: 41.88, longitude: -87.76)
    ]
}

@MainActor
private func makeViewModel(
    stops: [BusStop]? = makeStops(),
    error: Error? = nil
) async -> (BusStopsViewModel, MockBusRepository) {
    let busRepo = MockBusRepository()
    if let stops { await busRepo.setGetStopsResult(stops) }
    if let error { await busRepo.setGetStopsError(error) }
    let vm = BusStopsViewModel(
        route: makeBusRoute(),
        direction: "Eastbound",
        busRepository: busRepo
    )
    return (vm, busRepo)
}

// MARK: - Tests

@Suite @MainActor struct BusStopsViewModelTests {

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

        await busRepo.setGetStopsError(nil)
        await busRepo.setGetStopsResult(makeStops())
        await vm.loadStops()

        #expect(vm.error == nil)
        #expect(vm.stops.count == 3)
    }

    @Test func loadStopsKeepsCachedDataOnFailure() async {
        let (vm, busRepo) = await makeViewModel()
        await vm.loadStops()
        #expect(vm.stops.count == 3)

        await busRepo.setGetStopsResult(nil)
        await busRepo.setGetStopsError(APIError.networkError(URLError(.notConnectedToInternet)))
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

    @Test func screenStateIsLoadingDuringFetch() async {
        let busRepo = MockBusRepository()
        await busRepo.setGetStopsResult(makeStops())
        await busRepo.setShouldSuspendGetStops(true)
        let vm = BusStopsViewModel(
            route: makeBusRoute(),
            direction: "Eastbound",
            busRepository: busRepo
        )

        let task = Task { await vm.loadStops() }
        await busRepo.waitForGetStopsCalled()

        if case .loading = vm.screenState {} else {
            Issue.record("Expected .loading during fetch, got \(vm.screenState)")
        }

        await busRepo.resumeGetStops()
        await task.value

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded after fetch, got \(vm.screenState)")
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

    // MARK: - Route/direction context

    @Test func routeAndDirectionAreAccessibleAfterInit() async {
        let (vm, _) = await makeViewModel()
        #expect(vm.route.id == "20")
        #expect(vm.route.name == "Madison")
        #expect(vm.direction == "Eastbound")
    }

    @Test func loadStopsUsesRouteIdAndDirection() async {
        let (vm, busRepo) = await makeViewModel()
        await vm.loadStops()
        let calledRoute = await busRepo.getStopsCalledWithRoute
        let calledDirection = await busRepo.getStopsCalledWithDirection
        #expect(calledRoute == "20")
        #expect(calledDirection == "Eastbound")
    }

    // MARK: - Overlap guard

    @Test func loadStopsGuardsOverlappingCalls() async {
        let busRepo = MockBusRepository()
        await busRepo.setGetStopsResult(makeStops())
        await busRepo.setShouldSuspendGetStops(true)
        let vm = BusStopsViewModel(
            route: makeBusRoute(),
            direction: "Eastbound",
            busRepository: busRepo
        )

        let task = Task { await vm.loadStops() }
        await busRepo.waitForGetStopsCalled()

        await vm.loadStops()

        await busRepo.resumeGetStops()
        await task.value

        let callCount = await busRepo.getStopsCallCount
        #expect(callCount == 1)
    }

    // MARK: - Search filtering

    @Test func filteredStopsReturnsAllWhenSearchEmpty() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStops()

        let result = vm.filteredStops(searchText: "")
        #expect(result.count == 3)
    }

    @Test func filteredStopsFiltersByName() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStops()

        let result = vm.filteredStops(searchText: "Pulaski")
        #expect(result.count == 1)
        #expect(result.first?.name == "Madison & Pulaski")
    }

    @Test func filteredStopsFiltersByStopId() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStops()

        let result = vm.filteredStops(searchText: "1002")
        #expect(result.count == 1)
        #expect(result.first?.id == "1002")
    }

    @Test func filteredStopsIsCaseInsensitive() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStops()

        let result = vm.filteredStops(searchText: "pulaski")
        #expect(result.count == 1)
    }

    @Test func filteredStopsReturnsEmptyForNoMatch() async {
        let (vm, _) = await makeViewModel()
        await vm.loadStops()

        let result = vm.filteredStops(searchText: "Nonexistent")
        #expect(result.isEmpty)
    }
}
