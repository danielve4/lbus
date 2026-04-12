import Foundation
import Testing
@testable import LBus

@Suite struct TrainLineTests {

    @Test func fromIdReturnsRedLine() {
        let line = TrainLine.fromId("Red")
        #expect(line != nil)
        #expect(line?.name == "Red Line")
        #expect(line?.colorHex == "C60C30")
        #expect(line?.textColorHex == "FFFFFF")
    }

    @Test func fromIdReturnsYellowLineWithBlackText() {
        let line = TrainLine.fromId("Y")
        #expect(line != nil)
        #expect(line?.name == "Yellow Line")
        #expect(line?.textColorHex == "000000")
    }

    @Test func fromIdReturnsNilForUnknownId() {
        let line = TrainLine.fromId("Unknown")
        #expect(line == nil)
    }

    @Test func mapsFromDTO() {
        let dto = TrainLineDTO(routeId: "Red", name: "Red Line", color: "C60C30", textColor: "FFFFFF")
        let line = TrainLine(from: dto)
        #expect(line.id == "Red")
        #expect(line.name == "Red Line")
        #expect(line.colorHex == "C60C30")
        #expect(line.textColorHex == "FFFFFF")
    }
}
