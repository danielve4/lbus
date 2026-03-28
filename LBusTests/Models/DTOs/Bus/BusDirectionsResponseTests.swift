import Foundation
import Testing
@testable import LBus

@Suite struct BusDirectionsResponseTests {
    private let decoder = JSONDecoder()

    @Test func decodesDirections() throws {
        let json = """
        {
          "directions": [
            {"dir": "Eastbound"},
            {"dir": "Westbound"}
          ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(BusDirectionsResponse.self, from: json)
        #expect(response.directions?.count == 2)
        #expect(response.directions?[0].dir == "Eastbound")
        #expect(response.directions?[1].dir == "Westbound")
        #expect(response.error == nil)
    }

    @Test func decodesErrorResponse() throws {
        let json = """
        {
          "error": [{"msg": "No service scheduled"}]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(BusDirectionsResponse.self, from: json)
        #expect(response.directions == nil)
        #expect(response.error?.first?.msg == "No service scheduled")
    }
}
