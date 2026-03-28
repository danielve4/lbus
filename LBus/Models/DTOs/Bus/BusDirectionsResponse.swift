import Foundation

struct BusDirectionsResponse: Codable, Equatable, Sendable {
    let directions: [BusDirectionDTO]?
    let error: [BusAPIError]?
}

struct BusDirectionDTO: Codable, Equatable, Sendable {
    let dir: String
}
