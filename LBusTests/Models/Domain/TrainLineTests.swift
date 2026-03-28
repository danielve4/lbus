import Foundation
import Testing
@testable import LBus

@Suite struct TrainLineTests {

    @Test func mapsFromDTO() {
        let dto = TrainLineDTO(routeId: "Red", name: "Red Line", color: "C60C30", textColor: "FFFFFF")
        let line = TrainLine(from: dto)
        #expect(line.id == "Red")
        #expect(line.name == "Red Line")
        #expect(line.colorHex == "C60C30")
        #expect(line.textColorHex == "FFFFFF")
    }
}
