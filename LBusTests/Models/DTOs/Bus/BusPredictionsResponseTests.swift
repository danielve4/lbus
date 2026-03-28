import Foundation
import Testing
@testable import LBus

@Suite struct BusPredictionsResponseTests {
    private let decoder = JSONDecoder()

    @Test func decodesFullPredictionWithAllFields() throws {
        let json = """
        {
          "prd": [{
            "tmstmp": "20250421 16:04",
            "typ": "A",
            "stpid": "456",
            "stpnm": "Madison & Jefferson",
            "vid": "8184",
            "dstp": 686,
            "rt": "20",
            "rtdd": "20",
            "rtdir": "Westbound",
            "des": "Austin",
            "prdtm": "20250421 16:06",
            "dly": false,
            "dyn": 0,
            "tablockid": "20 -803",
            "tatripid": "1040713",
            "origtatripno": "262522629",
            "zone": "",
            "psgld": "EMPTY",
            "stst": 57120,
            "stsd": "2025-04-21",
            "flagstop": 0,
            "prdctdn": "2"
          }]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(BusPredictionsResponse.self, from: json)
        let prd = try #require(response.prd?.first)
        #expect(prd.tmstmp == "20250421 16:04")
        #expect(prd.typ == "A")
        #expect(prd.stpid == "456")
        #expect(prd.vid == "8184")
        #expect(prd.dstp == 686)
        #expect(prd.rt == "20")
        #expect(prd.rtdir == "Westbound")
        #expect(prd.des == "Austin")
        #expect(prd.prdtm == "20250421 16:06")
        #expect(prd.dly == false)
        #expect(prd.dyn == 0)
        #expect(prd.tablockid == "20 -803")
        #expect(prd.origtatripno == "262522629")
        #expect(prd.psgld == "EMPTY")
        #expect(prd.stst == 57120)
        #expect(prd.stsd == "2025-04-21")
        #expect(prd.flagstop == 0)
        #expect(prd.prdctdn == "2")
        #expect(prd.nbus == nil)
        #expect(response.error == nil)
    }

    @Test func decodesStopArrivalsWithoutFollowOnlyFields() throws {
        let json = """
        {
          "prd": [{
            "tmstmp": "20250421 16:04",
            "typ": "A",
            "stpid": "456",
            "stpnm": "Madison & Jefferson",
            "vid": "8184",
            "dstp": 686,
            "rt": "20",
            "rtdd": "20",
            "rtdir": "Westbound",
            "des": "Austin",
            "prdtm": "20250421 16:06",
            "dly": false,
            "tablockid": "20 -803",
            "tatripid": "1040713",
            "origtatripno": "262522629",
            "zone": "",
            "prdctdn": "2"
          }]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(BusPredictionsResponse.self, from: json)
        let prd = try #require(response.prd?.first)
        #expect(prd.rt == "20")
        #expect(prd.prdctdn == "2")
        #expect(prd.dyn == nil)
        #expect(prd.psgld == nil)
        #expect(prd.stst == nil)
        #expect(prd.stsd == nil)
        #expect(prd.flagstop == nil)
    }

    @Test func decodesDelayedPredictionWithDue() throws {
        let json = """
        {
          "prd": [{
            "tmstmp": "20250421 16:04",
            "typ": "A",
            "stpid": "456",
            "stpnm": "Madison & Jefferson",
            "vid": "8184",
            "dstp": 50,
            "rt": "20",
            "rtdd": "20",
            "rtdir": "Eastbound",
            "des": "Wacker & Columbus",
            "prdtm": "20250421 16:05",
            "dly": true,
            "tablockid": "20 -803",
            "tatripid": "1040713",
            "origtatripno": "262522629",
            "zone": "",
            "prdctdn": "DUE"
          }]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(BusPredictionsResponse.self, from: json)
        let prd = try #require(response.prd?.first)
        #expect(prd.dly == true)
        #expect(prd.prdctdn == "DUE")
    }

    @Test func decodesErrorResponse() throws {
        let json = """
        {
          "error": [{"msg": "No arrival times", "stpid": "456", "vid": "8184"}]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(BusPredictionsResponse.self, from: json)
        #expect(response.prd == nil)
        #expect(response.error?.first?.msg == "No arrival times")
        #expect(response.error?.first?.vid == "8184")
    }
}
