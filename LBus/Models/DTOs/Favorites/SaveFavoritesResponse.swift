import Foundation

struct SaveFavoritesResponse: Codable, Equatable, Sendable {
    let id: String
    let favorites: [FavoriteDTO]
}
