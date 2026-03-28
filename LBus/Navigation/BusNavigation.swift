import Foundation

enum BusNavigation: Hashable {
    case directions(route: BusRoute)
    case stops(route: BusRoute, direction: String)
    case arrivals(stopId: String, stopName: String, route: String, direction: String)
    case follow(vehicleId: String, stopId: String)
}
