import Foundation
import Testing
@testable import LBus

@Suite struct BusRoutesResponseTests {
    private let decoder = JSONDecoder()

    @Test func decodesRoutes() throws {
        let json = """
        {
          "routes": [
            {"rt": "1", "rtnm": "Indiana/Hyde Park", "rtclr": "#dc78af", "rtdd": "1"},
            {"rt": "X20", "rtnm": "Madison Express", "rtclr": "#336633", "rtdd": "X20"}
          ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(BusRoutesResponse.self, from: json)
        #expect(response.routes?.count == 2)
        #expect(response.routes?[0].rt == "1")
        #expect(response.routes?[0].rtnm == "Indiana/Hyde Park")
        #expect(response.routes?[0].rtclr == "#dc78af")
        #expect(response.routes?[0].rtdd == "1")
        #expect(response.routes?[1].rt == "X20")
        #expect(response.error == nil)
    }

    @Test func decodesErrorResponse() throws {
        let json = """
        {
          "error": [{"msg": "No data found for parameter", "rt": "999"}]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(BusRoutesResponse.self, from: json)
        #expect(response.routes == nil)
        #expect(response.error?.count == 1)
        #expect(response.error?[0].msg == "No data found for parameter")
        #expect(response.error?[0].rt == "999")
        #expect(response.error?[0].stpid == nil)
    }
}
