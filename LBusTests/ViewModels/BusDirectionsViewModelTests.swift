import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private func makeBusRoute() -> BusRoute {
    BusRoute(id: "20", name: "Madison", colorHex: "#336633", shortName: "20")
}

private func makeDirections() -> [BusDirection] {
    [
        BusDirection(direction: "Northbound"),
        BusDirection(direction: "Southbound")
    ]
}

@MainActor
private func makeViewModel(
    directions: [BusDirection]? = makeDirections(),
    error: Error? = nil
) async -> (BusDirectionsViewModel, MockBusRepository) {
    let repo = MockBusRepository()
    if let directions { await repo.setGetDirectionsResult(directions) }
    if let error { await repo.setGetDirectionsError(error) }
    let vm = BusDirectionsViewModel(route: makeBusRoute(), busRepository: repo)
    return (vm, repo)
}

// MARK: - Tests

@Suite @MainActor struct BusDirectionsViewModelTests {

    // MARK: - Loading

    @Test func loadDirectionsPopulatesDirections() async {
        let (vm, _) = await makeViewModel()

        await vm.loadDirections()

        #expect(vm.directions.count == 2)
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    @Test func isLoadingIsFalseAfterLoadCompletes() async {
        let (vm, _) = await makeViewModel()
        await vm.loadDirections()
        #expect(vm.isLoading == false)
    }

    // MARK: - Error handling

    @Test func loadDirectionsSetsErrorOnFailure() async {
        let (vm, _) = await makeViewModel(
            directions: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadDirections()

        #expect(vm.directions.isEmpty)
        #expect(vm.error != nil)
    }

    @Test func loadDirectionsClearsErrorOnRetry() async {
        let (vm, repo) = await makeViewModel(
            directions: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )
        await vm.loadDirections()
        #expect(vm.error != nil)

        await repo.setGetDirectionsError(nil)
        await repo.setGetDirectionsResult(makeDirections())
        await vm.loadDirections()

        #expect(vm.error == nil)
        #expect(vm.directions.count == 2)
    }

    @Test func loadDirectionsKeepsCachedDataOnFailure() async {
        let (vm, repo) = await makeViewModel()
        await vm.loadDirections()
        #expect(vm.directions.count == 2)

        await repo.setGetDirectionsResult(nil)
        await repo.setGetDirectionsError(APIError.networkError(URLError(.notConnectedToInternet)))
        await vm.loadDirections()

        #expect(vm.directions.count == 2)
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
        let repo = MockBusRepository()
        await repo.setGetDirectionsResult(makeDirections())
        await repo.setShouldSuspendGetDirections(true)
        let vm = BusDirectionsViewModel(route: makeBusRoute(), busRepository: repo)

        let task = Task { await vm.loadDirections() }
        await repo.waitForGetDirectionsCalled()

        if case .loading = vm.screenState {} else {
            Issue.record("Expected .loading during fetch, got \(vm.screenState)")
        }

        await repo.resumeGetDirections()
        await task.value

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded after fetch, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsErrorWhenErrorWithNoData() async {
        let (vm, _) = await makeViewModel(
            directions: nil,
            error: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadDirections()

        if case .error(let message) = vm.screenState {
            #expect(message.contains("Unable to load"))
        } else {
            Issue.record("Expected .error, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsLoadedWhenDataExists() async {
        let (vm, _) = await makeViewModel()
        await vm.loadDirections()

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsLoadedWhenDirectionsEmpty() async {
        let (vm, _) = await makeViewModel(directions: [])
        await vm.loadDirections()

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded for empty directions, got \(vm.screenState)")
        }
    }

    // MARK: - Route context

    @Test func routeIsAccessibleAfterInit() async {
        let (vm, _) = await makeViewModel()
        #expect(vm.route.id == "20")
        #expect(vm.route.name == "Madison")
    }

    @Test func loadDirectionsUsesRouteId() async {
        let (vm, repo) = await makeViewModel()
        await vm.loadDirections()
        let calledWith = await repo.getDirectionsCalledWithRoute
        #expect(calledWith == "20")
    }

    // MARK: - Overlap guard

    @Test func loadDirectionsGuardsOverlappingCalls() async {
        let repo = MockBusRepository()
        await repo.setGetDirectionsResult(makeDirections())
        await repo.setShouldSuspendGetDirections(true)
        let vm = BusDirectionsViewModel(route: makeBusRoute(), busRepository: repo)

        let task = Task { await vm.loadDirections() }
        await repo.waitForGetDirectionsCalled()

        // Second call while first is in flight should be a no-op
        await vm.loadDirections()

        await repo.resumeGetDirections()
        await task.value

        let callCount = await repo.getDirectionsCallCount
        #expect(callCount == 1)
    }
}
