import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private let redLine = TrainLine(id: "Red", name: "Red Line", colorHex: "C60C30", textColorHex: "FFFFFF")
private let blueLine = TrainLine(id: "Blue", name: "Blue Line", colorHex: "00A1DE", textColorHex: "FFFFFF")
private let orangeLine = TrainLine(id: "Orange", name: "Orange Line", colorHex: "F9461C", textColorHex: "FFFFFF")

private func station(_ id: String, _ name: String) -> TrainStation {
    TrainStation(id: id, name: name, latitude: 0, longitude: 0)
}

private func makeTrainData(
    lines: [TrainLine] = [redLine, blueLine, orangeLine],
    stations: [TrainStation] = [],
    stopSequences: [TrainStopSequence] = []
) -> TrainData {
    TrainData(lines: lines, stations: stations, stopSequences: stopSequences)
}

@MainActor
private func makeViewModel(
    line: TrainLine = redLine,
    data: TrainData? = nil,
    error: Error? = nil
) async -> (TrainStationsViewModel, MockTrainRepository) {
    let repo = MockTrainRepository()
    if let data { await repo.setGetTrainDataResult(data) }
    if let error { await repo.setGetTrainDataError(error) }
    let vm = TrainStationsViewModel(line: line, trainRepository: repo)
    return (vm, repo)
}

// MARK: - normalizeStopSequences

@Suite struct NormalizeStopSequencesTests {

    @Test func convertsDisplayNamesToRouteIds() {
        let data = makeTrainData(stopSequences: [
            TrainStopSequence(id: "Red-N", line: "Red Line", stops: ["A", "B"]),
            TrainStopSequence(id: "Blue-W", line: "Blue Line", stops: ["C", "D"])
        ])
        let normalized = TrainStationsViewModel.normalizeStopSequences(data)
        #expect(normalized.stopSequences.first { $0.id == "Red-N" }?.line == "Red")
        #expect(normalized.stopSequences.first { $0.id == "Blue-W" }?.line == "Blue")
    }

    @Test func passesThoughAlreadyNormalizedData() {
        let data = makeTrainData(stopSequences: [
            TrainStopSequence(id: "Red-N", line: "Red", stops: ["A", "B"])
        ])
        let normalized = TrainStationsViewModel.normalizeStopSequences(data)
        #expect(normalized.stopSequences.first?.line == "Red")
    }

    @Test func preservesStationsAndLines() {
        let data = makeTrainData(
            stations: [station("A", "Howard")],
            stopSequences: [
                TrainStopSequence(id: "Red-N", line: "Red Line", stops: ["A"])
            ]
        )
        let normalized = TrainStationsViewModel.normalizeStopSequences(data)
        #expect(normalized.lines == data.lines)
        #expect(normalized.stations == data.stations)
    }

    @Test func unknownLineNamePassesThrough() {
        let data = makeTrainData(stopSequences: [
            TrainStopSequence(id: "X-N", line: "Unknown Line", stops: ["A"])
        ])
        let normalized = TrainStationsViewModel.normalizeStopSequences(data)
        #expect(normalized.stopSequences.first?.line == "Unknown Line")
    }
}

// MARK: - orderedStationIds

@Suite struct OrderedStationIdsTests {

    @Test func canonicalSequenceOrderPreserved() {
        let data = makeTrainData(stopSequences: [
            TrainStopSequence(id: "Red-N", line: "Red", stops: ["A", "B", "C", "D"])
        ])
        let result = TrainStationsViewModel.orderedStationIds(for: redLine, data: data)
        #expect(result == ["A", "B", "C", "D"])
    }

    @Test func reversedDirectionIsDedupedAgainstCanonical() {
        // Red-N and Red-S cover the same four stations in opposite order.
        // Canonical (Red-N sorts first alphabetically) wins; Red-S adds nothing.
        let data = makeTrainData(stopSequences: [
            TrainStopSequence(id: "Red-N", line: "Red", stops: ["A", "B", "C", "D"]),
            TrainStopSequence(id: "Red-S", line: "Red", stops: ["D", "C", "B", "A"])
        ])
        let result = TrainStationsViewModel.orderedStationIds(for: redLine, data: data)
        #expect(result == ["A", "B", "C", "D"])
    }

    @Test func nonCanonicalSequenceContributesMissingStations() {
        // Red-S has an extra station "E" not in Red-N — it should be appended.
        let data = makeTrainData(stopSequences: [
            TrainStopSequence(id: "Red-N", line: "Red", stops: ["A", "B", "C"]),
            TrainStopSequence(id: "Red-S", line: "Red", stops: ["C", "B", "A", "E"])
        ])
        let result = TrainStationsViewModel.orderedStationIds(for: redLine, data: data)
        #expect(result == ["A", "B", "C", "E"])
    }

    @Test func lineWithNoSequencesReturnsEmpty() {
        let data = makeTrainData(stopSequences: [
            TrainStopSequence(id: "Blue-W", line: "Blue", stops: ["X", "Y"])
        ])
        let result = TrainStationsViewModel.orderedStationIds(for: redLine, data: data)
        #expect(result.isEmpty)
    }

    @Test func matchesByRouteIdNotDisplayName() {
        // Regression: TrainStopSequence.line is a route ID ("Red"), not display name ("Red Line").
        // TrainLine.id == "Red", TrainLine.name == "Red Line", sequence.line == "Red".
        let data = makeTrainData(stopSequences: [
            TrainStopSequence(id: "Red-N", line: "Red", stops: ["A", "B"]),
            TrainStopSequence(id: "Blue-W", line: "Blue", stops: ["B", "C"])
        ])
        let result = TrainStationsViewModel.orderedStationIds(for: redLine, data: data)
        #expect(result == ["A", "B"])
    }
}

// MARK: - buildLineIdsByStation

@Suite struct BuildLineIdsByStationTests {

    @Test func singlePassProducesUnionOfLinesPerStation() {
        let sequences = [
            TrainStopSequence(id: "Red-N", line: "Red", stops: ["A", "B"]),
            TrainStopSequence(id: "Orange-L", line: "Orange", stops: ["B", "C"]),
            TrainStopSequence(id: "Blue-W", line: "Blue", stops: ["C", "D"])
        ]
        let map = TrainStationsViewModel.buildLineIdsByStation(from: sequences)
        #expect(map["A"] == ["Red"])
        #expect(map["B"] == Set(["Red", "Orange"]))
        #expect(map["C"] == Set(["Orange", "Blue"]))
        #expect(map["D"] == ["Blue"])
    }

    @Test func emptySequencesProducesEmptyMap() {
        let map = TrainStationsViewModel.buildLineIdsByStation(from: [])
        #expect(map.isEmpty)
    }
}

// MARK: - loadStations

@Suite @MainActor struct TrainStationsViewModelLoadTests {

    private static func twoDirectionRedData() -> TrainData {
        makeTrainData(
            stations: [
                station("A", "Howard"),
                station("B", "Loyola"),
                station("C", "Roosevelt"),
                station("D", "95th")
            ],
            stopSequences: [
                TrainStopSequence(id: "Red-N", line: "Red", stops: ["A", "B", "C", "D"]),
                TrainStopSequence(id: "Red-S", line: "Red", stops: ["D", "C", "B", "A"])
            ]
        )
    }

    @Test func loadStationsPopulatesOrderedDedupedStations() async {
        let (vm, _) = await makeViewModel(data: Self.twoDirectionRedData())
        await vm.loadStations()

        #expect(vm.stations.map(\.id) == ["A", "B", "C", "D"])
        #expect(vm.error == nil)
        #expect(vm.isLoading == false)
    }

    @Test func noDuplicateStationsWhenBothDirectionsShareIds() async {
        let (vm, _) = await makeViewModel(data: Self.twoDirectionRedData())
        await vm.loadStations()

        let ids = vm.stations.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func linesByStationIncludesCurrentLineFirstForMultiLineStation() async {
        // Roosevelt (C) is served by Red and Orange; current line is Red.
        let data = makeTrainData(
            stations: [station("A", "Howard"), station("C", "Roosevelt"), station("E", "Midway")],
            stopSequences: [
                TrainStopSequence(id: "Red-N", line: "Red", stops: ["A", "C"]),
                TrainStopSequence(id: "Orange-L", line: "Orange", stops: ["C", "E"])
            ]
        )
        let (vm, _) = await makeViewModel(data: data)
        await vm.loadStations()

        let rooseveltLines = vm.linesByStation["C"] ?? []
        #expect(rooseveltLines.map(\.id) == ["Red", "Orange"])
    }

    @Test func linesByStationHasSingleEntryWhenStationServesOnlyCurrentLine() async {
        let data = makeTrainData(
            stations: [station("A", "Howard")],
            stopSequences: [
                TrainStopSequence(id: "Red-N", line: "Red", stops: ["A"])
            ]
        )
        let (vm, _) = await makeViewModel(data: data)
        await vm.loadStations()

        #expect(vm.linesByStation["A"]?.map(\.id) == ["Red"])
    }

    @Test func emptyTrainDataYieldsLoadedWithEmptyStations() async {
        let (vm, _) = await makeViewModel(data: makeTrainData())
        await vm.loadStations()

        #expect(vm.stations.isEmpty)
        #expect(vm.linesByStation.isEmpty)
        #expect(vm.error == nil)
        if case .loaded = vm.screenState {} else {
            Issue.record("Expected .loaded for empty data, got \(vm.screenState)")
        }
    }

    // MARK: - Error & retry

    @Test func loadStationsSetsErrorOnFailure() async {
        let (vm, _) = await makeViewModel(error: APIError.networkError(URLError(.notConnectedToInternet)))
        await vm.loadStations()

        #expect(vm.stations.isEmpty)
        #expect(vm.error != nil)
        if case .error = vm.screenState {} else {
            Issue.record("Expected .error, got \(vm.screenState)")
        }
    }

    @Test func retryClearsPreviousError() async {
        let (vm, repo) = await makeViewModel(error: APIError.networkError(URLError(.notConnectedToInternet)))
        await vm.loadStations()
        #expect(vm.error != nil)

        await repo.setGetTrainDataError(nil)
        await repo.setGetTrainDataResult(Self.twoDirectionRedData())
        await vm.loadStations()

        #expect(vm.error == nil)
        #expect(vm.stations.count == 4)
    }

    // MARK: - Screen state

    @Test func screenStateIsLoadingBeforeFirstFetch() async {
        let (vm, _) = await makeViewModel(data: makeTrainData())
        if case .loading = vm.screenState {} else {
            Issue.record("Expected .loading, got \(vm.screenState)")
        }
    }

    // MARK: - Search filtering

    @Test func filteredStationsReturnsAllWhenSearchEmpty() async {
        let (vm, _) = await makeViewModel(data: Self.twoDirectionRedData())
        await vm.loadStations()

        #expect(vm.filteredStations(searchText: "").count == 4)
    }

    @Test func filteredStationsFiltersByNameCaseInsensitively() async {
        let (vm, _) = await makeViewModel(data: Self.twoDirectionRedData())
        await vm.loadStations()

        let lowercase = vm.filteredStations(searchText: "roosevelt")
        #expect(lowercase.map(\.id) == ["C"])

        let uppercase = vm.filteredStations(searchText: "HOWARD")
        #expect(uppercase.map(\.id) == ["A"])
    }

    @Test func filteredStationsReturnsEmptyForNoMatch() async {
        let (vm, _) = await makeViewModel(data: Self.twoDirectionRedData())
        await vm.loadStations()

        #expect(vm.filteredStations(searchText: "Nonexistent").isEmpty)
    }

    // MARK: - Display name normalization (stale cache regression)

    @Test func loadStationsWorksWithDisplayNameLineValues() async {
        // Regression: cached TrainData may have display names ("Red Line") instead of route IDs ("Red")
        // in stopSequence.line. loadStations must normalize before filtering.
        let data = makeTrainData(
            stations: [station("A", "Howard"), station("B", "Loyola")],
            stopSequences: [
                TrainStopSequence(id: "Red-N", line: "Red Line", stops: ["A", "B"]),
                TrainStopSequence(id: "Red-S", line: "Red Line", stops: ["B", "A"])
            ]
        )
        let (vm, _) = await makeViewModel(data: data)
        await vm.loadStations()

        #expect(vm.stations.map(\.id) == ["A", "B"])
        #expect(vm.linesByStation["A"]?.map(\.id) == ["Red"])
    }

    @Test func loadStationsWithDisplayNamesResolvesMultiLineStations() async {
        let data = makeTrainData(
            stations: [station("A", "Howard"), station("C", "Roosevelt"), station("E", "Midway")],
            stopSequences: [
                TrainStopSequence(id: "Red-N", line: "Red Line", stops: ["A", "C"]),
                TrainStopSequence(id: "Orange-L", line: "Orange Line", stops: ["C", "E"])
            ]
        )
        let (vm, _) = await makeViewModel(data: data)
        await vm.loadStations()

        let rooseveltLines = vm.linesByStation["C"] ?? []
        #expect(rooseveltLines.map(\.id) == ["Red", "Orange"])
    }
}
