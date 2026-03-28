import Foundation
import Testing
@testable import LBus

@Suite struct FavoriteTests {

    @Test func mapsBusFavoriteFromDTO() {
        let dto = FavoriteDTO(route: "20", stopId: "456", stopName: "Madison & Jefferson", direction: "Westbound", type: "bus")
        let fav = Favorite(from: dto)
        guard case .bus(let bus) = fav else {
            Issue.record("Expected .bus case")
            return
        }
        #expect(bus.route == "20")
        #expect(bus.stopId == "456")
        #expect(bus.stopName == "Madison & Jefferson")
        #expect(bus.direction == "Westbound")
        #expect(fav.transitType == .bus)
    }

    @Test func mapsTrainFavoriteFromDTO() {
        let dto = FavoriteDTO(route: "Red", stopId: "40960", stopName: "Pulaski", direction: "Loop-bound", type: "train")
        let fav = Favorite(from: dto)
        guard case .train(let train) = fav else {
            Issue.record("Expected .train case")
            return
        }
        #expect(train.line == "Red")
        #expect(train.stopId == "40960")
        #expect(train.stopName == "Pulaski")
        #expect(train.direction == "Loop-bound")
        #expect(fav.transitType == .train)
    }

    @Test func defaultsToBusWhenTypeNil() {
        let dto = FavoriteDTO(route: "20", stopId: "456", stopName: "Madison & Jefferson", direction: "Westbound", type: nil)
        let fav = Favorite(from: dto)
        #expect(fav.transitType == .bus)
    }

    @Test func defaultsToBusWhenTypeUnrecognized() {
        let dto = FavoriteDTO(route: "20", stopId: "456", stopName: "Madison & Jefferson", direction: "Westbound", type: "unknown")
        let fav = Favorite(from: dto)
        #expect(fav.transitType == .bus)
    }

    @Test func convertsBusFavoriteToDTO() {
        let fav = Favorite.bus(BusFavorite(route: "20", stopId: "456", stopName: "Madison & Jefferson", direction: "Westbound"))
        let dto = fav.toDTO()
        #expect(dto.route == "20")
        #expect(dto.stopId == "456")
        #expect(dto.stopName == "Madison & Jefferson")
        #expect(dto.direction == "Westbound")
        #expect(dto.type == "bus")
    }

    @Test func convertsTrainFavoriteToDTO() {
        let fav = Favorite.train(TrainFavorite(line: "Red", stopId: "40960", stopName: "Pulaski", direction: "Loop-bound"))
        let dto = fav.toDTO()
        #expect(dto.route == "Red")
        #expect(dto.stopId == "40960")
        #expect(dto.stopName == "Pulaski")
        #expect(dto.direction == "Loop-bound")
        #expect(dto.type == "train")
    }

    @Test func busAndTrainHaveDifferentIds() {
        let bus = Favorite.bus(BusFavorite(route: "20", stopId: "456", stopName: "Stop", direction: "East"))
        let train = Favorite.train(TrainFavorite(line: "Red", stopId: "456", stopName: "Station", direction: "North"))
        #expect(bus.id != train.id)
    }

    @Test func computedPropertiesForBus() {
        let fav = Favorite.bus(BusFavorite(route: "20", stopId: "456", stopName: "Madison & Jefferson", direction: "Westbound"))
        #expect(fav.name == "Madison & Jefferson")
        #expect(fav.stopId == "456")
        #expect(fav.routeOrLine == "20")
        #expect(fav.direction == "Westbound")
    }

    @Test func computedPropertiesForTrain() {
        let fav = Favorite.train(TrainFavorite(line: "Red", stopId: "40960", stopName: "Pulaski", direction: "Loop-bound"))
        #expect(fav.name == "Pulaski")
        #expect(fav.stopId == "40960")
        #expect(fav.routeOrLine == "Red")
        #expect(fav.direction == "Loop-bound")
    }
}
