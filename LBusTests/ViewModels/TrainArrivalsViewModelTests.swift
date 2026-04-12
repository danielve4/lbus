import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private let redLine = TrainLine(id: "Red", name: "Red Line", colorHex: "C60C30", textColorHex: "FFFFFF")
private let blueLine = TrainLine(id: "Blue", name: "Blue Line", colorHex: "00A1DE", textColorHex: "FFFFFF")
private let orangeLine = TrainLine(id: "Org", name: "Orange Line", colorHex: "F9461C", textColorHex: "FFFFFF")

private func makeTrainData(
    lines: [TrainLine] = [redLine, blueLine, orangeLine],
    stationIds: [String] = ["40380"],
    lineIdsForStation: [String] = ["Red", "Blue"]
) -> TrainData {
    let stations = stationIds.map { TrainStation(id: $0, name: "Station \($0)", latitude: 0, longitude: 0) }
    var sequences: [TrainStopSequence] = []
    for lineId in lineIdsForStation {
        sequences.append(TrainStopSequence(id: "\(lineId)-N", line: lineId, stops: stationIds))
    }
    return TrainData(lines: lines, stations: stations, stopSequences: sequences)
}

private func makeArrival(
    stationId: String = "40380",
    stopId: String = "30070",
    runNumber: String = "420",
    line: String = "Red",
    destinationName: String = "Howard",
    direction: String = "1",
    arrivalMinutes: Int = 5,
    isApproaching: Bool = false,
    isDelayed: Bool = false,
    hasAlert: Bool = false
) -> TrainArrival {
    let predTime = "2026-03-30T12:00:00"
    let arrMinOffset = String(format: "%02d", arrivalMinutes)
    let arrTime = "2026-03-30T12:\(arrMinOffset):00"
    return TrainArrival(from: TrainEtaPredictionDTO(
        staId: stationId,
        stpId: stopId,
        staNm: "Clark/Lake",
        stpDe: "Service toward \(destinationName)",
        rn: runNumber,
        rt: line,
        destSt: "30173",
        destNm: destinationName,
        trDr: direction,
        prdt: predTime,
        arrT: arrTime,
        isApp: isApproaching ? "1" : "0",
        isSch: "0",
        isDly: isDelayed ? "1" : "0",
        isFlt: hasAlert ? "1" : "0",
        flags: nil,
        lat: nil,
        lon: nil,
        heading: nil
    ))
}

@MainActor
private func makeViewModel(
    stationId: String = "40380",
    stationName: String = "Clark/Lake",
    line: TrainLine? = redLine,
    trainData: TrainData? = makeTrainData(),
    trainDataError: Error? = nil,
    arrivals: [TrainArrival]? = [makeArrival()],
    arrivalsError: Error? = nil,
    favorites: [Favorite] = []
) async -> (TrainArrivalsViewModel, MockTrainRepository, MockFavoritesRepository) {
    let trainRepo = MockTrainRepository()
    if let trainData { await trainRepo.setGetTrainDataResult(trainData) }
    if let trainDataError { await trainRepo.setGetTrainDataError(trainDataError) }
    if let arrivals { await trainRepo.setGetArrivalsResult(arrivals) }
    if let arrivalsError { await trainRepo.setGetArrivalsError(arrivalsError) }
    let favRepo = MockFavoritesRepository()
    for fav in favorites { try? favRepo.add(fav) }
    let vm = TrainArrivalsViewModel(
        stationId: stationId,
        stationName: stationName,
        line: line,
        trainRepository: trainRepo,
        favoritesRepository: favRepo
    )
    return (vm, trainRepo, favRepo)
}

@MainActor
private func makeViewModelWithMockRefresh(
    line: TrainLine? = redLine,
    trainData: TrainData? = makeTrainData(),
    arrivals: [TrainArrival]? = [makeArrival()],
    favorites: [Favorite] = []
) async -> (TrainArrivalsViewModel, MockTrainRepository, MockFavoritesRepository, MockAutoRefreshManager) {
    let trainRepo = MockTrainRepository()
    if let trainData { await trainRepo.setGetTrainDataResult(trainData) }
    if let arrivals { await trainRepo.setGetArrivalsResult(arrivals) }
    let favRepo = MockFavoritesRepository()
    for fav in favorites { try? favRepo.add(fav) }
    let mockRefresh = MockAutoRefreshManager()
    let vm = TrainArrivalsViewModel(
        stationId: "40380",
        stationName: "Clark/Lake",
        line: line,
        trainRepository: trainRepo,
        favoritesRepository: favRepo,
        refreshManager: mockRefresh
    )
    return (vm, trainRepo, favRepo, mockRefresh)
}

// MARK: - Tests

@Suite @MainActor struct TrainArrivalsViewModelTests {

    // MARK: - Metadata

    @Test func metadataLineLookupsUseTrainLineId() async {
        let (vm, _, _) = await makeViewModel()
        await vm.initialLoad()
        // linesById should be keyed by route ID ("Red"), not display name ("Red Line")
        let red = vm.trainLine(for: "Red")
        #expect(red?.name == "Red Line")
        let byName = vm.trainLine(for: "Red Line")
        #expect(byName == nil)
    }

    @Test func lineDisplayNameFallsBackToRouteId() async {
        let (vm, _, _) = await makeViewModel()
        await vm.initialLoad()
        #expect(vm.lineDisplayName(for: "Red") == "Red Line")
        #expect(vm.lineDisplayName(for: "Unknown") == "Unknown")
    }

    // MARK: - Selected Line

    @Test func selectedLineDefaultsToIncomingLine() async {
        let (vm, _, _) = await makeViewModel(line: redLine)
        #expect(vm.selectedLine == "Red")
    }

    @Test func incomingLineRemainsSelectedWithZeroArrivalsWhenMetadataSucceeds() async {
        // Station serves Red and Blue, but only Blue arrivals exist
        let data = makeTrainData(lineIdsForStation: ["Red", "Blue"])
        let (vm, _, _) = await makeViewModel(
            line: redLine,
            trainData: data,
            arrivals: [makeArrival(line: "Blue", destinationName: "O'Hare")]
        )
        await vm.initialLoad()
        #expect(vm.effectiveSelectedLine == "Red")
        #expect(vm.filteredArrivals.isEmpty)
    }

    @Test func incomingLineRemainsInAvailableWhenMetadataFails() async {
        let (vm, _, _) = await makeViewModel(
            line: redLine,
            trainData: nil,
            trainDataError: APIError.networkError(URLError(.notConnectedToInternet)),
            arrivals: [makeArrival(line: "Blue")]
        )
        await vm.initialLoad()
        #expect(vm.availableLineIds.contains("Red"))
        #expect(vm.effectiveSelectedLine == "Red")
    }

    // MARK: - Metadata Failure Non-Fatal

    @Test func metadataFailureDoesNotSetErrorWhenArrivalsSucceed() async {
        let (vm, _, _) = await makeViewModel(
            trainData: nil,
            trainDataError: APIError.networkError(URLError(.notConnectedToInternet)),
            arrivals: [makeArrival()]
        )
        await vm.initialLoad()
        #expect(vm.error == nil)
        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded, got \(vm.screenState)")
        }
    }

    // MARK: - Screen State

    @Test func screenStateIsLoadingBeforeFirstFetch() async {
        let (vm, _, _) = await makeViewModel()
        if case .loading = vm.screenState {} else {
            Issue.record("Expected .loading, got \(vm.screenState)")
        }
    }

    @Test func arrivalFailureWithNoExistingDataSetsError() async {
        let (vm, _, _) = await makeViewModel(
            arrivals: nil,
            arrivalsError: APIError.networkError(URLError(.notConnectedToInternet))
        )
        await vm.initialLoad()
        if case .error = vm.screenState {} else {
            Issue.record("Expected .error, got \(vm.screenState)")
        }
    }

    @Test func arrivalFailureWithExistingDataStaysLoaded() async {
        let (vm, trainRepo, _) = await makeViewModel()
        await vm.initialLoad()
        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded after initial load, got \(vm.screenState)")
        }

        await trainRepo.setGetArrivalsResult(nil)
        await trainRepo.setGetArrivalsError(APIError.networkError(URLError(.notConnectedToInternet)))
        await vm.loadArrivals()

        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded with cached data, got \(vm.screenState)")
        }
    }

    // MARK: - Grouping

    @Test func groupsSortByLineThenDestinationHeader() async {
        let (vm, _, _) = await makeViewModel(arrivals: [
            makeArrival(runNumber: "1", line: "Red", destinationName: "Howard", direction: "1"),
            makeArrival(runNumber: "2", line: "Blue", destinationName: "O'Hare", direction: "1"),
            makeArrival(runNumber: "3", line: "Red", destinationName: "95th/Dan Ryan", direction: "5"),
            makeArrival(runNumber: "4", line: "Blue", destinationName: "Forest Park", direction: "5")
        ])
        await vm.initialLoad()
        vm.selectLine(nil)
        let groups = vm.groupedArrivals
        let titles = groups.map { vm.groupTitle(for: $0) }
        #expect(titles == [
            "Blue Line to Forest Park",
            "Blue Line to O'Hare",
            "Red Line to 95th/Dan Ryan",
            "Red Line to Howard"
        ])
    }

    @Test func sameDirectionDifferentDestinationsMergeIntoOneGroup() async {
        let (vm, _, _) = await makeViewModel(line: nil, arrivals: [
            makeArrival(runNumber: "1", line: "Blue", destinationName: "Forest Park", direction: "5", arrivalMinutes: 3),
            makeArrival(runNumber: "2", line: "Blue", destinationName: "UIC-Halsted", direction: "5", arrivalMinutes: 7),
            makeArrival(runNumber: "3", line: "Blue", destinationName: "Forest Park", direction: "5", arrivalMinutes: 12)
        ])
        await vm.initialLoad()
        vm.selectLine(nil)
        let groups = vm.groupedArrivals
        #expect(groups.count == 1)
        #expect(groups[0].destinations == ["Forest Park", "UIC-Halsted"])
        #expect(vm.groupTitle(for: groups[0]) == "Blue Line to Forest Park / UIC-Halsted")
        #expect(groups[0].arrivals.map(\.runNumber) == ["1", "2", "3"])
    }

    @Test func differentDirectionsRemainSeparateGroups() async {
        let (vm, _, _) = await makeViewModel(line: nil, arrivals: [
            makeArrival(runNumber: "1", line: "Blue", destinationName: "O'Hare", direction: "1"),
            makeArrival(runNumber: "2", line: "Blue", destinationName: "Forest Park", direction: "5")
        ])
        await vm.initialLoad()
        vm.selectLine(nil)
        let groups = vm.groupedArrivals
        #expect(groups.count == 2)
        #expect(groups[0].destinations == ["Forest Park"])
        #expect(groups[1].destinations == ["O'Hare"])
    }

    @Test func groupTitleConcatenatesDestinationsWhenLineSelected() async {
        let (vm, _, _) = await makeViewModel(line: blueLine, trainData: makeTrainData(lineIdsForStation: ["Blue"]), arrivals: [
            makeArrival(runNumber: "1", line: "Blue", destinationName: "Forest Park", direction: "5"),
            makeArrival(runNumber: "2", line: "Blue", destinationName: "UIC-Halsted", direction: "5")
        ])
        await vm.initialLoad()
        let groups = vm.groupedArrivals
        #expect(groups.count == 1)
        #expect(vm.groupTitle(for: groups[0]) == "Forest Park / UIC-Halsted")
    }

    @Test func arrivalsWithinGroupSortByArrivalTimeThenRunNumber() async {
        let (vm, _, _) = await makeViewModel(arrivals: [
            makeArrival(runNumber: "300", line: "Red", destinationName: "Howard", arrivalMinutes: 10),
            makeArrival(runNumber: "200", line: "Red", destinationName: "Howard", arrivalMinutes: 5),
            makeArrival(runNumber: "100", line: "Red", destinationName: "Howard", arrivalMinutes: 5)
        ])
        await vm.initialLoad()
        vm.selectLine("Red")
        let arrivals = vm.groupedArrivals.flatMap(\.arrivals)
        #expect(arrivals.map(\.runNumber) == ["100", "200", "300"])
    }

    // MARK: - Favorites

    @Test func favoriteUsesIncomingLineNotFilterPill() async {
        let (vm, _, favRepo) = await makeViewModel(line: redLine, arrivals: [
            makeArrival(line: "Red"),
            makeArrival(runNumber: "2", line: "Blue")
        ])
        await vm.initialLoad()
        vm.selectLine("Blue") // Switch filter to Blue
        vm.toggleFavorite()

        let expected = Favorite.train(TrainFavorite(line: "Red", stopId: "40380", stopName: "Clark/Lake", direction: ""))
        #expect(favRepo.contains(expected))
    }

    @Test func isFavoriteReturnsTrueWhenPreSeeded() async {
        let fav = Favorite.train(TrainFavorite(line: "Red", stopId: "40380", stopName: "Clark/Lake", direction: ""))
        let (vm, _, _) = await makeViewModel(favorites: [fav])
        await vm.initialLoad()
        #expect(vm.isFavorite == true)
    }

    @Test func toggleFavoriteRemovesFavorite() async {
        let fav = Favorite.train(TrainFavorite(line: "Red", stopId: "40380", stopName: "Clark/Lake", direction: ""))
        let (vm, _, favRepo) = await makeViewModel(favorites: [fav])
        await vm.initialLoad()
        #expect(vm.isFavorite == true)
        vm.toggleFavorite()
        #expect(vm.isFavorite == false)
        #expect(!favRepo.contains(fav))
    }

    // MARK: - Refresh Manager Proxy

    @Test func isRefreshingPassesThroughFromManager() async {
        let (vm, _, _, mockRefresh) = await makeViewModelWithMockRefresh()
        #expect(vm.isRefreshing == false)
        mockRefresh.isRefreshing = true
        #expect(vm.isRefreshing == true)
    }

    @Test func lastUpdatedPassesThroughFromManager() async {
        let (vm, _, _, mockRefresh) = await makeViewModelWithMockRefresh()
        #expect(vm.lastUpdated == nil)
        let now = Date()
        mockRefresh.lastUpdated = now
        #expect(vm.lastUpdated == now)
    }

    @Test func startAutoRefreshCallsManager() async {
        let (vm, _, _, mockRefresh) = await makeViewModelWithMockRefresh()
        vm.startAutoRefresh()
        #expect(mockRefresh.startCallCount == 1)
    }

    @Test func stopAutoRefreshCallsManager() async {
        let (vm, _, _, mockRefresh) = await makeViewModelWithMockRefresh()
        vm.stopAutoRefresh()
        #expect(mockRefresh.stopCallCount == 1)
    }

    // MARK: - Line Filtering

    @Test func filteredEmptyStateReachableWithIncomingLineAndNoArrivals() async {
        let data = makeTrainData(lineIdsForStation: ["Red"])
        let (vm, _, _) = await makeViewModel(line: redLine, trainData: data, arrivals: [])
        await vm.initialLoad()
        #expect(vm.effectiveSelectedLine == "Red")
        #expect(vm.filteredArrivals.isEmpty)
        #expect(vm.groupedArrivals.isEmpty)
    }

    @Test func availableLineIdsSortedByDisplayName() async {
        // Org (Orange Line) should sort after Blue Line alphabetically by display name
        let data = makeTrainData(lineIdsForStation: ["Org", "Blue", "Red"])
        let (vm, _, _) = await makeViewModel(line: nil, trainData: data, arrivals: [])
        await vm.initialLoad()
        #expect(vm.availableLineIds == ["Blue", "Org", "Red"])
        // Display names: Blue Line, Orange Line, Red Line — sorted correctly
    }

    @Test func selectLineUpdatesEffectiveSelectedLine() async {
        let (vm, _, _) = await makeViewModel(arrivals: [
            makeArrival(line: "Red"),
            makeArrival(runNumber: "2", line: "Blue")
        ])
        await vm.initialLoad()
        vm.selectLine("Blue")
        #expect(vm.effectiveSelectedLine == "Blue")
        #expect(vm.filteredArrivals.allSatisfy { $0.line == "Blue" })
        vm.selectLine(nil)
        #expect(vm.effectiveSelectedLine == nil)
        #expect(vm.filteredArrivals.count == 2)
    }
}
