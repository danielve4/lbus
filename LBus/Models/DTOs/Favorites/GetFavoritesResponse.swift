import Foundation

struct GetFavoritesResponse: Codable, Equatable, Sendable {
    let id: String
    let favorites: [FavoriteDTO]
}
