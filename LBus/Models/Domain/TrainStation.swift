import Foundation

struct TrainStation: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double

    init(id: String, from dto: TrainStationDTO) {
        self.id = id
        self.name = dto.name
        self.latitude = dto.latitude
        self.longitude = dto.longitude
    }

    static func mapAll(from stations: [String: TrainStationDTO]) -> [TrainStation] {
        stations.map { TrainStation(id: $0.key, from: $0.value) }.sorted { $0.id < $1.id }
    }
}

struct TrainStopSequence: Equatable, Sendable, Identifiable {
    let id: String
    let line: String
    let stops: [String]

    init(id: String, from dto: TrainStopSequenceDTO) {
        self.id = id
        self.line = dto.line
        self.stops = dto.stops
    }

    static func mapAll(from sequences: [String: TrainStopSequenceDTO]) -> [TrainStopSequence] {
        sequences.map { TrainStopSequence(id: $0.key, from: $0.value) }.sorted { $0.id < $1.id }
    }
}
