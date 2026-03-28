import Foundation
import Testing
@testable import LBus

@Suite struct BusNavigationTests {

    private let routeDTO = BusRouteDTO(rt: "20", rtnm: "Madison", rtclr: "#336633", rtdd: "20")
    private let otherRouteDTO = BusRouteDTO(rt: "66", rtnm: "Chicago", rtclr: "#009900", rtdd: "66")

    @Test func directionsEqualWithSameRoute() {
        let route = BusRoute(from: routeDTO)
        let a = BusNavigation.directions(route: route)
        let b = BusNavigation.directions(route: route)
        #expect(a == b)
    }

    @Test func directionsNotEqualWithDifferentRoute() {
        let a = BusNavigation.directions(route: BusRoute(from: routeDTO))
        let b = BusNavigation.directions(route: BusRoute(from: otherRouteDTO))
        #expect(a != b)
    }

    @Test func stopsEqualWithSameData() {
        let route = BusRoute(from: routeDTO)
        let a = BusNavigation.stops(route: route, direction: "Eastbound")
        let b = BusNavigation.stops(route: route, direction: "Eastbound")
        #expect(a == b)
    }

    @Test func stopsNotEqualWithDifferentDirection() {
        let route = BusRoute(from: routeDTO)
        let a = BusNavigation.stops(route: route, direction: "Eastbound")
        let b = BusNavigation.stops(route: route, direction: "Westbound")
        #expect(a != b)
    }

    @Test func arrivalsEqualWithSameData() {
        let a = BusNavigation.arrivals(stopId: "456", stopName: "State & Lake", route: "20", direction: "Eastbound")
        let b = BusNavigation.arrivals(stopId: "456", stopName: "State & Lake", route: "20", direction: "Eastbound")
        #expect(a == b)
    }

    @Test func arrivalsNotEqualWithDifferentStop() {
        let a = BusNavigation.arrivals(stopId: "456", stopName: "State & Lake", route: "20", direction: "Eastbound")
        let b = BusNavigation.arrivals(stopId: "789", stopName: "Clark & Lake", route: "20", direction: "Eastbound")
        #expect(a != b)
    }

    @Test func followEqualWithSameData() {
        let a = BusNavigation.follow(vehicleId: "1234", stopId: "456")
        let b = BusNavigation.follow(vehicleId: "1234", stopId: "456")
        #expect(a == b)
    }

    @Test func followNotEqualWithDifferentVehicle() {
        let a = BusNavigation.follow(vehicleId: "1234", stopId: "456")
        let b = BusNavigation.follow(vehicleId: "5678", stopId: "456")
        #expect(a != b)
    }

    @Test func differentCasesAreNotEqual() {
        let route = BusRoute(from: routeDTO)
        let directions = BusNavigation.directions(route: route)
        let stops = BusNavigation.stops(route: route, direction: "Eastbound")
        let arrivals = BusNavigation.arrivals(stopId: "456", stopName: "State", route: "20", direction: "Eastbound")
        let follow = BusNavigation.follow(vehicleId: "1234", stopId: "456")
        #expect(directions != stops)
        #expect(arrivals != follow)
        #expect(directions != arrivals)
    }

    @Test func hashableWorksInSet() {
        let route = BusRoute(from: routeDTO)
        let a = BusNavigation.directions(route: route)
        let b = BusNavigation.directions(route: route)
        let c = BusNavigation.follow(vehicleId: "1234", stopId: "456")
        let set: Set<BusNavigation> = [a, b, c]
        #expect(set.count == 2)
    }
}
