import Foundation
import Testing
@testable import LBus

@Suite struct BusAPIErrorTests {
    private let decoder = JSONDecoder()

    @Test func decodesMinimalError() throws {
        let json = """
        {"msg": "Something went wrong"}
        """.data(using: .utf8)!

        let error = try decoder.decode(BusAPIError.self, from: json)
        #expect(error.msg == "Something went wrong")
        #expect(error.rt == nil)
        #expect(error.rtdir == nil)
        #expect(error.stpid == nil)
        #expect(error.vid == nil)
    }

    @Test func decodesErrorWithAllFields() throws {
        let json = """
        {"msg": "No data found", "rt": "20", "rtdir": "Eastbound", "stpid": "456", "vid": "8184"}
        """.data(using: .utf8)!

        let error = try decoder.decode(BusAPIError.self, from: json)
        #expect(error.msg == "No data found")
        #expect(error.rt == "20")
        #expect(error.rtdir == "Eastbound")
        #expect(error.stpid == "456")
        #expect(error.vid == "8184")
    }
}
