import Foundation
import Testing
@testable import LBus

@Suite struct TrainFollowResponseTests {
    private let decoder = JSONDecoder()

    @Test func decodesFollowWithPositionAndEtas() throws {
        let json = """
        {
          "ctatt": {
            "tmst": "2025-04-30T20:28:37",
            "errCd": "0",
            "errNm": null,
            "position": {
              "lat": "42.01588",
              "lon": "-87.66909",
              "heading": "310"
            },
            "eta": [{
              "staId": "40900",
              "stpId": "30173",
              "staNm": "Howard",
              "stpDe": "Terminal arrival",
              "rn": "827",
              "rt": "Red",
              "destSt": "30173",
              "destNm": "Howard",
              "trDr": "1",
              "prdt": "2025-04-30T20:28:37",
              "arrT": "2025-04-30T20:31:37",
              "isApp": "0",
              "isSch": "0",
              "isDly": "0",
              "isFlt": "0",
              "flags": null
            }]
          }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(TrainFollowResponse.self, from: json)
        #expect(response.ctatt.tmst == "2025-04-30T20:28:37")
        #expect(response.ctatt.errCd == "0")

        let position = try #require(response.ctatt.position)
        #expect(position.lat == "42.01588")
        #expect(position.lon == "-87.66909")
        #expect(position.heading == "310")

        let eta = try #require(response.ctatt.eta?.first)
        #expect(eta.rn == "827")
        #expect(eta.rt == "Red")
        #expect(eta.destNm == "Howard")
    }

    @Test func decodesErrorResponse() throws {
        let json = """
        {
          "ctatt": {
            "tmst": "2025-04-30T20:28:37",
            "errCd": "502",
            "errNm": "Invalid run number"
          }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(TrainFollowResponse.self, from: json)
        #expect(response.ctatt.errCd == "502")
        #expect(response.ctatt.errNm == "Invalid run number")
        #expect(response.ctatt.position == nil)
        #expect(response.ctatt.eta == nil)
    }
}
