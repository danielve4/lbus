import Foundation

struct FavoriteDTO: Codable, Equatable, Sendable {
    let route: String
    let stopId: String
    let stopName: String
    let direction: String
    let type: String?
}
