import Foundation
import SwiftData

@Model
nonisolated final class FavoritePersisted {
    @Attribute(.unique) var favoriteId: String
    var transitType: String
    var routeOrLine: String
    var stopId: String
    var stopName: String
    var direction: String
    var sortOrder: Int

    init(favoriteId: String, transitType: String, routeOrLine: String, stopId: String, stopName: String, direction: String, sortOrder: Int = 0) {
        self.favoriteId = favoriteId
        self.transitType = transitType
        self.routeOrLine = routeOrLine
        self.stopId = stopId
        self.stopName = stopName
        self.direction = direction
        self.sortOrder = sortOrder
    }

    convenience init(from favorite: Favorite, sortOrder: Int = 0) {
        self.init(
            favoriteId: favorite.id,
            transitType: favorite.transitType.rawValue,
            routeOrLine: favorite.routeOrLine,
            stopId: favorite.stopId,
            stopName: favorite.name,
            direction: favorite.direction,
            sortOrder: sortOrder
        )
    }

    func toFavorite() -> Favorite {
        switch transitType {
        case "train":
            return .train(TrainFavorite(
                line: routeOrLine,
                stopId: stopId,
                stopName: stopName,
                direction: direction
            ))
        default:
            return .bus(BusFavorite(
                route: routeOrLine,
                stopId: stopId,
                stopName: stopName,
                direction: direction
            ))
        }
    }
}
