import Foundation
import Testing
@testable import LBus

@Suite struct TrainArrivalsResponseTests {
    private let decoder = JSONDecoder()

    @Test func decodesArrivals() throws {
        let json = """
        {
          "ctatt": {
            "tmst": "2025-04-30T20:23:53",
            "errCd": "0",
            "errNm": null,
            "eta": [{
              "staId": "40960",
              "stpId": "30185",
              "staNm": "Pulaski",
              "stpDe": "Service toward Loop",
              "rn": "726",
              "rt": "Org",
              "destSt": "30182",
              "destNm": "Loop",
              "trDr": "1",
              "prdt": "2025-04-30T20:23:32",
              "arrT": "2025-04-30T20:25:32",
              "isApp": "0",
              "isSch": "0",
              "isDly": "0",
              "isFlt": "0",
              "flags": null,
              "lat": "41.78661",
              "lon": "-87.73796",
              "heading": "357"
            }]
          }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(TrainArrivalsResponse.self, from: json)
        #expect(response.ctatt.tmst == "2025-04-30T20:23:53")
        #expect(response.ctatt.errCd == "0")
        #expect(response.ctatt.errNm == nil)

        let eta = try #require(response.ctatt.eta?.first)
        #expect(eta.staId == "40960")
        #expect(eta.stpId == "30185")
        #expect(eta.staNm == "Pulaski")
        #expect(eta.stpDe == "Service toward Loop")
        #expect(eta.rn == "726")
        #expect(eta.rt == "Org")
        #expect(eta.destNm == "Loop")
        #expect(eta.trDr == "1")
        #expect(eta.isApp == "0")
        #expect(eta.isSch == "0")
        #expect(eta.isDly == "0")
        #expect(eta.isFlt == "0")
        #expect(eta.flags == nil)
        #expect(eta.lat == "41.78661")
        #expect(eta.lon == "-87.73796")
        #expect(eta.heading == "357")
    }

    @Test func decodesScheduleBasedPredictionWithoutPosition() throws {
        let json = """
        {
          "ctatt": {
            "tmst": "2025-04-30T20:23:53",
            "errCd": "0",
            "errNm": null,
            "eta": [{
              "staId": "40960",
              "stpId": "30185",
              "staNm": "Pulaski",
              "stpDe": "Service toward Loop",
              "rn": "726",
              "rt": "Org",
              "destSt": "0",
              "destNm": "Loop",
              "trDr": "1",
              "prdt": "2025-04-30T20:23:32",
              "arrT": "2025-04-30T20:35:32",
              "isApp": "0",
              "isSch": "1",
              "isDly": "0",
              "isFlt": "1",
              "flags": null
            }]
          }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(TrainArrivalsResponse.self, from: json)
        let eta = try #require(response.ctatt.eta?.first)
        #expect(eta.isSch == "1")
        #expect(eta.isFlt == "1")
        #expect(eta.lat == nil)
        #expect(eta.lon == nil)
        #expect(eta.heading == nil)
    }

    @Test func decodesErrorResponse() throws {
        let json = """
        {
          "ctatt": {
            "tmst": "2025-04-30T20:23:53",
            "errCd": "501",
            "errNm": "Invalid mapid"
          }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(TrainArrivalsResponse.self, from: json)
        #expect(response.ctatt.errCd == "501")
        #expect(response.ctatt.errNm == "Invalid mapid")
        #expect(response.ctatt.eta == nil)
    }
}
