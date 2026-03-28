import Foundation

nonisolated struct SaveFavoritesRequestBody: Codable, Equatable, Sendable {
    let id: String
    let favorites: [FavoriteDTO]
}
