import Foundation

struct BusAPIError: Codable, Equatable, Sendable {
    let msg: String
    let rt: String?
    let rtdir: String?
    let stpid: String?
    let vid: String?
}
