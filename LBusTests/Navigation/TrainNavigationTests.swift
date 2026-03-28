import Foundation
import Testing
@testable import LBus

@Suite struct TrainNavigationTests {

    private let lineDTO = TrainLineDTO(routeId: "Red", name: "Red Line", color: "#c60c30", textColor: "#ffffff")
    private let otherLineDTO = TrainLineDTO(routeId: "Blue", name: "Blue Line", color: "#00a1de", textColor: "#ffffff")

    @Test func stationsEqualWithSameLine() {
        let line = TrainLine(from: lineDTO)
        let a = TrainNavigation.stations(line: line)
        let b = TrainNavigation.stations(line: line)
        #expect(a == b)
    }

    @Test func stationsNotEqualWithDifferentLine() {
        let a = TrainNavigation.stations(line: TrainLine(from: lineDTO))
        let b = TrainNavigation.stations(line: TrainLine(from: otherLineDTO))
        #expect(a != b)
    }

    @Test func arrivalsEqualWithSameData() {
        let line = TrainLine(from: lineDTO)
        let a = TrainNavigation.arrivals(stopId: "40360", stationName: "Southport", line: line)
        let b = TrainNavigation.arrivals(stopId: "40360", stationName: "Southport", line: line)
        #expect(a == b)
    }

    @Test func arrivalsWithAndWithoutLineAreDistinct() {
        let line = TrainLine(from: lineDTO)
        let a = TrainNavigation.arrivals(stopId: "40360", stationName: "Southport", line: line)
        let b = TrainNavigation.arrivals(stopId: "40360", stationName: "Southport", line: nil)
        #expect(a != b)
    }

    @Test func arrivalsNotEqualWithDifferentStop() {
        let line = TrainLine(from: lineDTO)
        let a = TrainNavigation.arrivals(stopId: "40360", stationName: "Southport", line: line)
        let b = TrainNavigation.arrivals(stopId: "40380", stationName: "Clark/Lake", line: line)
        #expect(a != b)
    }

    @Test func followEqualWithSameData() {
        let a = TrainNavigation.follow(runNumber: "421", stopId: "40360")
        let b = TrainNavigation.follow(runNumber: "421", stopId: "40360")
        #expect(a == b)
    }

    @Test func followNotEqualWithDifferentRun() {
        let a = TrainNavigation.follow(runNumber: "421", stopId: "40360")
        let b = TrainNavigation.follow(runNumber: "422", stopId: "40360")
        #expect(a != b)
    }

    @Test func differentCasesAreNotEqual() {
        let line = TrainLine(from: lineDTO)
        let stations = TrainNavigation.stations(line: line)
        let arrivals = TrainNavigation.arrivals(stopId: "40360", stationName: "Southport", line: line)
        let follow = TrainNavigation.follow(runNumber: "421", stopId: "40360")
        #expect(stations != arrivals)
        #expect(arrivals != follow)
        #expect(stations != follow)
    }

    @Test func hashableWorksInSet() {
        let line = TrainLine(from: lineDTO)
        let a = TrainNavigation.stations(line: line)
        let b = TrainNavigation.stations(line: line)
        let c = TrainNavigation.follow(runNumber: "421", stopId: "40360")
        let set: Set<TrainNavigation> = [a, b, c]
        #expect(set.count == 2)
    }
}
