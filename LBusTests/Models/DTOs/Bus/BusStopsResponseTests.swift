import Foundation
import Testing
@testable import LBus

@Suite struct BusStopsResponseTests {
    private let decoder = JSONDecoder()

    @Test func decodesStops() throws {
        let json = """
        {
          "stops": [
            {"stpid": "1577", "stpnm": "1509 S Michigan", "lat": 41.861706666665, "lon": -87.623969999999}
          ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(BusStopsResponse.self, from: json)
        #expect(response.stops?.count == 1)
        let stop = try #require(response.stops?.first)
        #expect(stop.stpid == "1577")
        #expect(stop.stpnm == "1509 S Michigan")
        #expect(stop.lat == 41.861706666665)
        #expect(stop.lon == -87.623969999999)
        #expect(response.error == nil)
    }

    @Test func decodesErrorResponse() throws {
        let json = """
        {
          "error": [{"msg": "No data found for parameter", "stpid": "99999"}]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(BusStopsResponse.self, from: json)
        #expect(response.stops == nil)
        #expect(response.error?.first?.msg == "No data found for parameter")
        #expect(response.error?.first?.stpid == "99999")
    }
}
