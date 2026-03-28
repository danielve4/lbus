import Foundation

struct BusRoutesResponse: Codable, Equatable, Sendable {
    let routes: [BusRouteDTO]?
    let error: [BusAPIError]?
}

struct BusRouteDTO: Codable, Equatable, Sendable {
    let rt: String
    let rtnm: String
    let rtclr: String
    let rtdd: String
}
