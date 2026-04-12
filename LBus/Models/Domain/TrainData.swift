import Foundation

nonisolated struct TrainData: Equatable, Sendable, Codable {
    let lines: [TrainLine]
    let stations: [TrainStation]
    let stopSequences: [TrainStopSequence]

    init(lines: [TrainLine], stations: [TrainStation], stopSequences: [TrainStopSequence]) {
        self.lines = lines
        self.stations = stations
        self.stopSequences = stopSequences
    }

    /// Normalizes stop sequence line values from display names ("Red Line") to route IDs ("Red").
    init(from dto: TrainDataResponse) {
        let lines = dto.lines.map { TrainLine(from: $0) }
        let nameToId = Dictionary(uniqueKeysWithValues: lines.map { ($0.name, $0.id) })
        let stations = TrainStation.mapAll(from: dto.stations)
        let sequences = TrainStopSequence.mapAll(from: dto.stopSequences).map { seq in
            TrainStopSequence(id: seq.id, line: nameToId[seq.line] ?? seq.line, stops: seq.stops)
        }
        self.init(lines: lines, stations: stations, stopSequences: sequences)
    }
}
