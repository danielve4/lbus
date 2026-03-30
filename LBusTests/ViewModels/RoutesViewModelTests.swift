import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private func makeBusRoutes() -> [BusRoute] {
    [
        BusRoute(id: "20", name: "Madison", colorHex: "#336633", shortName: "20"),
        BusRoute(id: "66", name: "Chicago", colorHex: "#009900", shortName: "66"),
        BusRoute(id: "151", name: "Sheridan", colorHex: "#663366", shortName: "151")
    ]
}

private func makeTrainData() -> TrainData {
    TrainData(
        lines: [
            TrainLine(id: "Red", name: "Red Line", colorHex: "#c60c30", textColorHex: "#ffffff"),
            TrainLine(id: "Blue", name: "Blue Line", colorHex: "#00a1de", textColorHex: "#ffffff")
        ],
        stations: [],
        stopSequences: []
    )
}

@MainActor
private func makeViewModel(
    busRoutes: [BusRoute]? = makeBusRoutes(),
    busError: Error? = nil,
    trainData: TrainData? = makeTrainData(),
    trainError: Error? = nil
) async -> (RoutesViewModel, MockBusRepository, MockTrainRepository) {
    let busRepo = MockBusRepository()
    let trainRepo = MockTrainRepository()
    if let busRoutes { await busRepo.setGetRoutesResult(busRoutes) }
    if let busError { await busRepo.setGetRoutesError(busError) }
    if let trainData { await trainRepo.setGetTrainDataResult(trainData) }
    if let trainError { await trainRepo.setGetTrainDataError(trainError) }
    let vm = RoutesViewModel(busRepository: busRepo, trainRepository: trainRepo)
    return (vm, busRepo, trainRepo)
}

// MARK: - Tests

@Suite @MainActor struct RoutesViewModelTests {

    // MARK: - Loading

    @Test func loadDataPopulatesBusRoutesAndTrainLines() async {
        let (vm, _, _) = await makeViewModel()

        await vm.loadData()

        #expect(vm.busRoutes.count == 3)
        #expect(vm.trainLines.count == 2)
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    @Test func isLoadingIsFalseAfterLoadCompletes() async {
        let (vm, _, _) = await makeViewModel()
        await vm.loadData()
        #expect(vm.isLoading == false)
    }

    // MARK: - Error handling

    @Test func loadDataSetsErrorWhenBothFetchesFail() async {
        let (vm, _, _) = await makeViewModel(
            busRoutes: nil,
            busError: APIError.networkError(URLError(.notConnectedToInternet)),
            trainData: nil,
            trainError: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadData()

        #expect(vm.busRoutes.isEmpty)
        #expect(vm.trainLines.isEmpty)
        #expect(vm.error != nil)
    }

    @Test func loadDataShowsBusRoutesWhenTrainFails() async {
        let (vm, _, _) = await makeViewModel(
            trainData: nil,
            trainError: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadData()

        #expect(vm.busRoutes.count == 3)
        #expect(vm.trainLines.isEmpty)
        #expect(vm.error == nil)
    }

    @Test func loadDataShowsTrainLinesWhenBusFails() async {
        let (vm, _, _) = await makeViewModel(
            busRoutes: nil,
            busError: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadData()

        #expect(vm.busRoutes.isEmpty)
        #expect(vm.trainLines.count == 2)
        #expect(vm.error == nil)
    }

    // MARK: - Screen state

    @Test func screenStateIsLoadingBeforeFirstFetch() async {
        let (vm, _, _) = await makeViewModel()
        if case .loading = vm.screenState {} else {
            Issue.record("Expected .loading, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsLoadingDuringFetch() async {
        let busRepo = MockBusRepository()
        let trainRepo = MockTrainRepository()
        await busRepo.setGetRoutesResult(makeBusRoutes())
        await trainRepo.setGetTrainDataResult(makeTrainData())
        await busRepo.setShouldSuspendGetRoutes(true)
        let vm = RoutesViewModel(busRepository: busRepo, trainRepository: trainRepo)

        let task = Task { await vm.loadData() }
        await busRepo.waitForGetRoutesCalled()

        if case .loading = vm.screenState {} else {
            Issue.record("Expected .loading during fetch, got \(vm.screenState)")
        }

        await busRepo.resumeGetRoutes()
        await task.value

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded after fetch, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsErrorWhenErrorWithNoData() async {
        let (vm, _, _) = await makeViewModel(
            busRoutes: nil,
            busError: APIError.networkError(URLError(.notConnectedToInternet)),
            trainData: nil,
            trainError: APIError.networkError(URLError(.notConnectedToInternet))
        )

        await vm.loadData()

        if case .error(let message) = vm.screenState {
            #expect(message.contains("Unable to load"))
        } else {
            Issue.record("Expected .error, got \(vm.screenState)")
        }
    }

    @Test func screenStateIsLoadedWhenDataExists() async {
        let (vm, _, _) = await makeViewModel()

        await vm.loadData()

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded, got \(vm.screenState)")
        }
    }

    // MARK: - Search filtering

    @Test func filteredBusRoutesMatchesById() async {
        let (vm, _, _) = await makeViewModel()
        await vm.loadData()

        let result = vm.filteredBusRoutes(searchText: "20")

        #expect(result.count == 1)
        #expect(result[0].id == "20")
    }

    @Test func filteredBusRoutesMatchesByName() async {
        let (vm, _, _) = await makeViewModel()
        await vm.loadData()

        let result = vm.filteredBusRoutes(searchText: "madison")

        #expect(result.count == 1)
        #expect(result[0].name == "Madison")
    }

    @Test func filteredTrainLinesMatchesByName() async {
        let (vm, _, _) = await makeViewModel()
        await vm.loadData()

        let result = vm.filteredTrainLines(searchText: "red")

        #expect(result.count == 1)
        #expect(result[0].name == "Red Line")
    }

    @Test func filteredReturnsAllWhenSearchEmpty() async {
        let (vm, _, _) = await makeViewModel()
        await vm.loadData()

        #expect(vm.filteredBusRoutes(searchText: "").count == 3)
        #expect(vm.filteredTrainLines(searchText: "").count == 2)
    }

    @Test func filteredReturnsEmptyWhenNoMatch() async {
        let (vm, _, _) = await makeViewModel()
        await vm.loadData()

        #expect(vm.filteredBusRoutes(searchText: "zzzzz").isEmpty)
        #expect(vm.filteredTrainLines(searchText: "zzzzz").isEmpty)
    }
}
