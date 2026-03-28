import Foundation

enum FavoritesAPI {
    static func push(apiClient: APIClientProtocol, deviceId: String, favorites: [FavoriteDTO]) async throws {
        let body = SaveFavoritesRequestBody(id: deviceId, favorites: favorites)
        let _: SaveFavoritesResponse = try await apiClient.post(path: "savefavorites", body: body)
    }

    static func pull(apiClient: APIClientProtocol, deviceId: String) async throws -> GetFavoritesResponse {
        let body = GetFavoritesRequestBody(id: deviceId)
        return try await apiClient.post(path: "myfavorites", body: body)
    }
}
