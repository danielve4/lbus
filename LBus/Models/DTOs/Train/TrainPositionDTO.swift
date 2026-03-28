import Foundation

struct TrainPositionDTO: Codable, Equatable, Sendable {
    let lat: String
    let lon: String
    let heading: String
}
