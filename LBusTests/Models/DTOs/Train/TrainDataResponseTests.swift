import Foundation
import Testing
@testable import LBus

@Suite struct TrainDataResponseTests {
    private let decoder = JSONDecoder()

    @Test func decodesTrainData() throws {
        let json = """
        {
          "lines": [
            {"route_id": "Red", "name": "Red Line", "color": "C60C30", "text_color": "FFFFFF"},
            {"route_id": "Blue", "name": "Blue Line", "color": "00A1DE", "text_color": "FFFFFF"}
          ],
          "stations": {
            "40960": {"name": "Pulaski", "latitude": 41.7899, "longitude": -87.7242},
            "40380": {"name": "Clark/Lake", "latitude": 41.8858, "longitude": -87.6309}
          },
          "stopSequences": {
            "Red-N": {"line": "Red", "stops": ["40900", "41190", "40100"]},
            "Red-S": {"line": "Red", "stops": ["40100", "41190", "40900"]}
          },
          "lastUpdated": "2025-04-30T12:00:00"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(TrainDataResponse.self, from: json)

        #expect(response.lines.count == 2)
        #expect(response.lines[0].routeId == "Red")
        #expect(response.lines[0].name == "Red Line")
        #expect(response.lines[0].color == "C60C30")
        #expect(response.lines[0].textColor == "FFFFFF")

        let pulaski = try #require(response.stations["40960"])
        #expect(pulaski.name == "Pulaski")
        #expect(pulaski.latitude == 41.7899)
        #expect(pulaski.longitude == -87.7242)

        let redN = try #require(response.stopSequences["Red-N"])
        #expect(redN.line == "Red")
        #expect(redN.stops == ["40900", "41190", "40100"])

        #expect(response.lastUpdated == "2025-04-30T12:00:00")
    }

    @Test func decodesEmptyCollections() throws {
        let json = """
        {
          "lines": [],
          "stations": {},
          "stopSequences": {},
          "lastUpdated": "2025-04-30T12:00:00"
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(TrainDataResponse.self, from: json)
        #expect(response.lines.isEmpty)
        #expect(response.stations.isEmpty)
        #expect(response.stopSequences.isEmpty)
    }
}
