import Foundation
import Testing
@testable import LBus

@Suite struct BusStopTests {

    @Test func mapsFromDTO() {
        let dto = BusStopDTO(stpid: "1577", stpnm: "1509 S Michigan", lat: 41.8617, lon: -87.6239)
        let stop = BusStop(from: dto)
        #expect(stop.id == "1577")
        #expect(stop.name == "1509 S Michigan")
        #expect(stop.latitude == 41.8617)
        #expect(stop.longitude == -87.6239)
    }
}
