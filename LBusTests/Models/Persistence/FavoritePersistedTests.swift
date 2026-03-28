import Foundation
import SwiftData
import Testing
@testable import LBus

@Suite struct FavoritePersistedTests {

    // MARK: - Bus Favorite Roundtrip

    @Test func busFavoriteRoundtrip() {
        let original = Favorite.bus(BusFavorite(
            route: "20",
            stopId: "456",
            stopName: "State & Lake",
            direction: "Eastbound"
        ))

        let persisted = FavoritePersisted(from: original)
        let restored = persisted.toFavorite()

        #expect(restored == original)
        #expect(persisted.favoriteId == "bus-20-456")
        #expect(persisted.transitType == "bus")
        #expect(persisted.routeOrLine == "20")
        #expect(persisted.stopId == "456")
        #expect(persisted.stopName == "State & Lake")
        #expect(persisted.direction == "Eastbound")
    }

    // MARK: - Train Favorite Roundtrip

    @Test func trainFavoriteRoundtrip() {
        let original = Favorite.train(TrainFavorite(
            line: "Red",
            stopId: "30089",
            stopName: "Howard",
            direction: "Service toward 95th/Dan Ryan"
        ))

        let persisted = FavoritePersisted(from: original)
        let restored = persisted.toFavorite()

        #expect(restored == original)
        #expect(persisted.favoriteId == "train-Red-30089")
        #expect(persisted.transitType == "train")
        #expect(persisted.routeOrLine == "Red")
        #expect(persisted.stopId == "30089")
        #expect(persisted.stopName == "Howard")
        #expect(persisted.direction == "Service toward 95th/Dan Ryan")
    }

    // MARK: - Unknown Transit Type Defaults to Bus

    @Test func unknownTransitTypeDefaultsToBus() {
        let persisted = FavoritePersisted(
            favoriteId: "mystery-X-123",
            transitType: "ferry",
            routeOrLine: "X",
            stopId: "123",
            stopName: "Dock",
            direction: "North"
        )

        let favorite = persisted.toFavorite()

        guard case .bus(let bus) = favorite else {
            Issue.record("Expected bus case for unknown transit type")
            return
        }
        #expect(bus.route == "X")
        #expect(bus.stopId == "123")
        #expect(bus.stopName == "Dock")
        #expect(bus.direction == "North")
    }

    // MARK: - sortOrder

    @Test func sortOrderDefaultsToZero() {
        let persisted = FavoritePersisted(from: Favorite.bus(BusFavorite(
            route: "20", stopId: "456", stopName: "State & Lake", direction: "Eastbound"
        )))

        #expect(persisted.sortOrder == 0)
    }

    @Test func sortOrderRespectsCustomValue() {
        let persisted = FavoritePersisted(from: Favorite.train(TrainFavorite(
            line: "Red", stopId: "30089", stopName: "Howard", direction: "South"
        )), sortOrder: 5)

        #expect(persisted.sortOrder == 5)
    }
}
