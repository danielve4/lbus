import Foundation
import Testing
@testable import LBus

@Suite struct FavoritesDTOTests {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    @Test func decodesFavoriteWithType() throws {
        let json = """
        {"route": "20", "stopId": "456", "stopName": "Madison & Jefferson", "direction": "Westbound", "type": "bus"}
        """.data(using: .utf8)!

        let favorite = try decoder.decode(FavoriteDTO.self, from: json)
        #expect(favorite.route == "20")
        #expect(favorite.stopId == "456")
        #expect(favorite.stopName == "Madison & Jefferson")
        #expect(favorite.direction == "Westbound")
        #expect(favorite.type == "bus")
    }

    @Test func decodesFavoriteWithoutType() throws {
        let json = """
        {"route": "Red", "stopId": "40960", "stopName": "Pulaski", "direction": "Loop-bound"}
        """.data(using: .utf8)!

        let favorite = try decoder.decode(FavoriteDTO.self, from: json)
        #expect(favorite.route == "Red")
        #expect(favorite.stopId == "40960")
        #expect(favorite.type == nil)
    }

    @Test func encodesAndDecodesSaveFavoritesRequestBody() throws {
        let body = SaveFavoritesRequestBody(
            id: "device-123",
            favorites: [
                FavoriteDTO(route: "20", stopId: "456", stopName: "Madison & Jefferson", direction: "Westbound", type: "bus"),
                FavoriteDTO(route: "Red", stopId: "40960", stopName: "Pulaski", direction: "Loop-bound", type: "train")
            ]
        )

        let data = try encoder.encode(body)
        let decoded = try decoder.decode(SaveFavoritesRequestBody.self, from: data)
        #expect(decoded == body)
    }

    @Test func encodesGetFavoritesRequestBody() throws {
        let body = GetFavoritesRequestBody(id: "device-123")
        let data = try encoder.encode(body)
        let decoded = try decoder.decode(GetFavoritesRequestBody.self, from: data)
        #expect(decoded == body)
    }

    @Test func decodesGetFavoritesResponse() throws {
        let json = """
        {
          "id": "device-123",
          "favorites": [
            {"route": "20", "stopId": "456", "stopName": "Madison & Jefferson", "direction": "Westbound", "type": "bus"}
          ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(GetFavoritesResponse.self, from: json)
        #expect(response.id == "device-123")
        #expect(response.favorites.count == 1)
        #expect(response.favorites[0].stopId == "456")
    }
}
