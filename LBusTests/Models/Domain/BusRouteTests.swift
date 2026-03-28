import Foundation
import Testing
@testable import LBus

@Suite struct BusRouteTests {

    @Test func mapsFromDTO() {
        let dto = BusRouteDTO(rt: "20", rtnm: "Madison", rtclr: "#336633", rtdd: "20")
        let route = BusRoute(from: dto)
        #expect(route.id == "20")
        #expect(route.name == "Madison")
        #expect(route.colorHex == "#336633")
        #expect(route.shortName == "20")
    }

    @Test func mapsExpressRoute() {
        let dto = BusRouteDTO(rt: "X20", rtnm: "Madison Express", rtclr: "#009900", rtdd: "X20")
        let route = BusRoute(from: dto)
        #expect(route.id == "X20")
        #expect(route.name == "Madison Express")
    }

    @Test func mapsDirectionFromDTO() {
        let dto = BusDirectionDTO(dir: "Eastbound")
        let direction = BusDirection(from: dto)
        #expect(direction.direction == "Eastbound")
    }
}
