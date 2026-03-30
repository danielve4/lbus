import Foundation

nonisolated struct TrainStation: Equatable, Sendable, Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double

    init(id: String, name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }

    init(id: String, from dto: TrainStationDTO) {
        self.init(id: id, name: dto.name, latitude: dto.latitude, longitude: dto.longitude)
    }

    static func mapAll(from stations: [String: TrainStationDTO]) -> [TrainStation] {
        stations.map { TrainStation(id: $0.key, from: $0.value) }.sorted { $0.id < $1.id }
    }
}

nonisolated struct TrainStopSequence: Equatable, Sendable, Identifiable, Codable {
    let id: String
    let line: String
    let stops: [String]

    init(id: String, line: String, stops: [String]) {
        self.id = id
        self.line = line
        self.stops = stops
    }

    init(id: String, from dto: TrainStopSequenceDTO) {
        self.init(id: id, line: dto.line, stops: dto.stops)
    }

    static func mapAll(from sequences: [String: TrainStopSequenceDTO]) -> [TrainStopSequence] {
        sequences.map { TrainStopSequence(id: $0.key, from: $0.value) }.sorted { $0.id < $1.id }
    }
}
