import Foundation

struct TrainDataResponse: Codable, Equatable, Sendable {
    let lines: [TrainLineDTO]
    let stations: [String: TrainStationDTO]
    let stopSequences: [String: TrainStopSequenceDTO]
    let lastUpdated: String
}

struct TrainLineDTO: Codable, Equatable, Sendable {
    let routeId: String
    let name: String
    let color: String
    let textColor: String

    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case name
        case color
        case textColor = "text_color"
    }
}

struct TrainStationDTO: Codable, Equatable, Sendable {
    let name: String
    let latitude: Double
    let longitude: Double
}

struct TrainStopSequenceDTO: Codable, Equatable, Sendable {
    let line: String
    let stops: [String]
}
