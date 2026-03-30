import Foundation

enum CacheKeys {
    static let busRoutes = "bus_routes"
    static func busDirections(route: String) -> String { "bus_directions_\(route)" }
    static func busStops(route: String, direction: String) -> String { "bus_stops_\(route)_\(direction)" }
    static let trainData = "train_data"
}
