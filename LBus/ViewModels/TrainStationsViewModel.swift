import Foundation

@MainActor
@Observable
final class TrainStationsViewModel {

    enum ScreenState {
        case loading
        case error(String)
        case loaded
    }

    let line: TrainLine

    private(set) var stations: [TrainStation] = []
    private(set) var linesByStation: [String: [TrainLine]] = [:]
    private(set) var isLoading = true
    private(set) var error: String? = nil

    private let trainRepository: TrainRepositoryProtocol
    private var isFetching = false

    init(line: TrainLine, trainRepository: TrainRepositoryProtocol) {
        self.line = line
        self.trainRepository = trainRepository
    }

    var screenState: ScreenState {
        if isLoading && stations.isEmpty { return .loading }
        if let error, stations.isEmpty { return .error(error) }
        return .loaded
    }

    func loadStations() async {
        guard !isFetching else { return }
        isFetching = true
        isLoading = true
        error = nil

        do {
            let data = try await trainRepository.getTrainData()
            let normalizedData = Self.normalizeStopSequences(data)
            let lineIdsByStation = Self.buildLineIdsByStation(from: normalizedData.stopSequences)
            let stationsById = Dictionary(uniqueKeysWithValues: normalizedData.stations.map { ($0.id, $0) })
            let linesById = Dictionary(uniqueKeysWithValues: normalizedData.lines.map { ($0.id, $0) })

            let orderedIds = Self.orderedStationIds(for: line, data: normalizedData)
            stations = orderedIds.compactMap { stationsById[$0] }
            linesByStation = Self.resolveLinesByStation(
                stationIds: orderedIds,
                lineIdsByStation: lineIdsByStation,
                linesById: linesById,
                currentLine: line
            )
        } catch {
            self.error = "Unable to load stations. Check your connection and try again."
        }

        isLoading = false
        isFetching = false
    }

    func filteredStations(searchText: String) -> [TrainStation] {
        guard !searchText.isEmpty else { return stations }
        return stations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Helpers

    /// Ensures `stopSequence.line` uses route IDs (e.g. "Red") even if cached data has display names ("Red Line").
    nonisolated static func normalizeStopSequences(_ data: TrainData) -> TrainData {
        let nameToId = Dictionary(uniqueKeysWithValues: data.lines.map { ($0.name, $0.id) })
        let needsNormalization = data.stopSequences.contains { nameToId[$0.line] != nil }
        guard needsNormalization else { return data }
        let normalized = data.stopSequences.map { seq in
            TrainStopSequence(id: seq.id, line: nameToId[seq.line] ?? seq.line, stops: seq.stops)
        }
        return TrainData(lines: data.lines, stations: data.stations, stopSequences: normalized)
    }

    nonisolated static func orderedStationIds(for line: TrainLine, data: TrainData) -> [String] {
        let sequences = data.stopSequences
            .filter { $0.line == line.id }
            .sorted { $0.id < $1.id }
        guard let canonical = sequences.first else { return [] }
        var result = canonical.stops
        var seen = Set(result)
        for sequence in sequences.dropFirst() {
            for stationId in sequence.stops where !seen.contains(stationId) {
                result.append(stationId)
                seen.insert(stationId)
            }
        }
        return result
    }

    /// One-pass map of station ID → set of line IDs (route IDs) serving it.
    nonisolated static func buildLineIdsByStation(from sequences: [TrainStopSequence]) -> [String: Set<String>] {
        var map: [String: Set<String>] = [:]
        for sequence in sequences {
            for stationId in sequence.stops {
                map[stationId, default: []].insert(sequence.line)
            }
        }
        return map
    }

    nonisolated static func resolveLinesByStation(
        stationIds: [String],
        lineIdsByStation: [String: Set<String>],
        linesById: [String: TrainLine],
        currentLine: TrainLine
    ) -> [String: [TrainLine]] {
        var result: [String: [TrainLine]] = [:]
        for stationId in stationIds {
            let lineIds = lineIdsByStation[stationId] ?? []
            let resolved = lineIds.compactMap { linesById[$0] }
            let others = resolved
                .filter { $0.id != currentLine.id }
                .sorted { $0.name < $1.name }
            let ordered = lineIds.contains(currentLine.id) ? [currentLine] + others : others
            result[stationId] = ordered
        }
        return result
    }
}
