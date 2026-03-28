import Foundation

struct BusStopsResponse: Codable, Equatable, Sendable {
    let stops: [BusStopDTO]?
    let error: [BusAPIError]?
}

struct BusStopDTO: Codable, Equatable, Sendable {
    let stpid: String
    let stpnm: String
    let lat: Double
    let lon: Double
}
