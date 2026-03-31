import Foundation
import Testing
@testable import LBus

@Suite struct BusArrivalTests {

    private func makeDTO(
        tmstmp: String = "20250421 16:04",
        typ: String = "A",
        stpid: String = "456",
        stpnm: String = "Madison & Jefferson",
        vid: String = "8184",
        dstp: Int = 686,
        rt: String = "20",
        rtdd: String = "20",
        rtdir: String = "Westbound",
        des: String = "Austin",
        prdtm: String = "20250421 16:06",
        dly: Bool = false,
        tablockid: String = "20 -803",
        tatripid: String = "1040713",
        origtatripno: String = "262522629",
        zone: String = "",
        prdctdn: String? = "2",
        dyn: Int? = nil,
        psgld: String? = nil,
        stst: Int? = nil,
        stsd: String? = nil,
        flagstop: Int? = nil,
        nbus: String? = nil
    ) -> BusPredictionDTO {
        BusPredictionDTO(
            tmstmp: tmstmp, typ: typ, stpid: stpid, stpnm: stpnm,
            vid: vid, dstp: dstp, rt: rt, rtdd: rtdd, rtdir: rtdir,
            des: des, prdtm: prdtm, dly: dly, tablockid: tablockid,
            tatripid: tatripid, origtatripno: origtatripno, zone: zone,
            prdctdn: prdctdn, dyn: dyn, psgld: psgld, stst: stst,
            stsd: stsd, flagstop: flagstop, nbus: nbus
        )
    }

    @Test func mapsAllFields() {
        let arrival = BusArrival(from: makeDTO())
        #expect(arrival.stopId == "456")
        #expect(arrival.stopName == "Madison & Jefferson")
        #expect(arrival.vehicleId == "8184")
        #expect(arrival.distanceToStop == 686)
        #expect(arrival.route == "20")
        #expect(arrival.routeDirection == "Westbound")
        #expect(arrival.destination == "Austin")
        #expect(arrival.isDelayed == false)
    }

    @Test func mapsStandardCountdown() {
        let arrival = BusArrival(from: makeDTO(prdctdn: "5"))
        #expect(arrival.countdown == .minutes(5))
    }

    @Test func mapsDueCountdown() {
        let arrival = BusArrival(from: makeDTO(prdctdn: "DUE"))
        #expect(arrival.countdown == .due)
    }

    @Test func mapsDelayedAndDue() {
        let arrival = BusArrival(from: makeDTO(dly: true, prdctdn: "DUE"))
        #expect(arrival.isDelayed == true)
        #expect(arrival.countdown == .due)
    }

    @Test func parsesTimestampsToDate() {
        let arrival = BusArrival(from: makeDTO(
            tmstmp: "20250421 16:04",
            prdtm: "20250421 16:06"
        ))
        #expect(arrival.predictedArrival > arrival.timestamp)
        let diff = arrival.predictedArrival.timeIntervalSince(arrival.timestamp)
        #expect(diff == 120)
    }

    @Test func fallbackCountdownWhenPrdctdnNil() {
        let arrival = BusArrival(from: makeDTO(
            tmstmp: "20250421 16:00",
            prdtm: "20250421 16:05",
            prdctdn: nil
        ))
        #expect(arrival.countdown == .minutes(5))
    }

    @Test func fallbackCountdownDueWhenTimesEqual() {
        let arrival = BusArrival(from: makeDTO(
            tmstmp: "20250421 16:04",
            prdtm: "20250421 16:04",
            prdctdn: nil
        ))
        #expect(arrival.countdown == .due)
    }

    @Test func computedIdIsComposite() {
        let arrival = BusArrival(from: makeDTO(stpid: "456", vid: "8184", rt: "20"))
        let epoch = String(arrival.predictedArrival.timeIntervalSince1970)
        #expect(arrival.id == "8184-456-20-\(epoch)")
    }
}
