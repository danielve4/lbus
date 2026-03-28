import Foundation
import Testing
@testable import LBus

@Suite struct TrainArrivalTests {

    private func makeDTO(
        staId: String = "40960",
        stpId: String = "30185",
        staNm: String = "Pulaski",
        stpDe: String = "Service toward Loop",
        rn: String = "726",
        rt: String = "Org",
        destSt: String = "30182",
        destNm: String = "Loop",
        trDr: String = "1",
        prdt: String = "2025-04-30T20:23:32",
        arrT: String = "2025-04-30T20:25:32",
        isApp: String = "0",
        isSch: String = "0",
        isDly: String = "0",
        isFlt: String = "0",
        flags: String? = nil,
        lat: String? = "41.78661",
        lon: String? = "-87.73796",
        heading: String? = "357"
    ) -> TrainEtaPredictionDTO {
        TrainEtaPredictionDTO(
            staId: staId, stpId: stpId, staNm: staNm, stpDe: stpDe,
            rn: rn, rt: rt, destSt: destSt, destNm: destNm, trDr: trDr,
            prdt: prdt, arrT: arrT, isApp: isApp, isSch: isSch,
            isDly: isDly, isFlt: isFlt, flags: flags, lat: lat,
            lon: lon, heading: heading
        )
    }

    @Test func mapsAllFields() {
        let arrival = TrainArrival(from: makeDTO())
        #expect(arrival.stationId == "40960")
        #expect(arrival.stopId == "30185")
        #expect(arrival.stationName == "Pulaski")
        #expect(arrival.stopDescription == "Service toward Loop")
        #expect(arrival.runNumber == "726")
        #expect(arrival.line == "Org")
        #expect(arrival.destinationStopId == "30182")
        #expect(arrival.destinationName == "Loop")
        #expect(arrival.direction == "1")
    }

    @Test func mapsStandardCountdown() {
        let arrival = TrainArrival(from: makeDTO(
            prdt: "2025-04-30T20:23:32",
            arrT: "2025-04-30T20:28:32",
            isApp: "0"
        ))
        #expect(arrival.countdown == .minutes(5))
        #expect(arrival.isApproaching == false)
    }

    @Test func mapsApproachingAsDue() {
        let arrival = TrainArrival(from: makeDTO(isApp: "1"))
        #expect(arrival.countdown == .due)
        #expect(arrival.isApproaching == true)
    }

    @Test func mapsDelayedFlag() {
        let arrival = TrainArrival(from: makeDTO(isDly: "1"))
        #expect(arrival.isDelayed == true)
    }

    @Test func mapsNotDelayed() {
        let arrival = TrainArrival(from: makeDTO(isDly: "0"))
        #expect(arrival.isDelayed == false)
    }

    @Test func mapsServiceAlert() {
        let arrival = TrainArrival(from: makeDTO(isFlt: "1"))
        #expect(arrival.hasAlert == true)
    }

    @Test func mapsScheduledFlag() {
        let arrival = TrainArrival(from: makeDTO(isSch: "1"))
        #expect(arrival.isScheduled == true)
    }

    @Test func parsesPositionFields() {
        let arrival = TrainArrival(from: makeDTO(
            lat: "41.78661", lon: "-87.73796", heading: "357"
        ))
        #expect(arrival.latitude == 41.78661)
        #expect(arrival.longitude == -87.73796)
        #expect(arrival.heading == 357)
    }

    @Test func nilPositionWhenFieldsMissing() {
        let arrival = TrainArrival(from: makeDTO(lat: nil, lon: nil, heading: nil))
        #expect(arrival.latitude == nil)
        #expect(arrival.longitude == nil)
        #expect(arrival.heading == nil)
    }

    @Test func parsesArrivalTimes() {
        let arrival = TrainArrival(from: makeDTO(
            prdt: "2025-04-30T20:23:32",
            arrT: "2025-04-30T20:25:32"
        ))
        let diff = arrival.arrivalTime.timeIntervalSince(arrival.predictionTime)
        #expect(diff == 120)
    }

    @Test func countdownDueWhenTimesEqual() {
        let arrival = TrainArrival(from: makeDTO(
            prdt: "2025-04-30T20:25:32",
            arrT: "2025-04-30T20:25:32",
            isApp: "0"
        ))
        #expect(arrival.countdown == .due)
    }

    @Test func computedIdIsComposite() {
        let arrival = TrainArrival(from: makeDTO(staId: "40960", stpId: "30185", rn: "726"))
        #expect(arrival.id == "726-40960-30185")
    }

    @Test func mapsTrainPositionFromDTO() {
        let dto = TrainPositionDTO(lat: "42.01588", lon: "-87.66909", heading: "310")
        let position = TrainPosition(from: dto)
        #expect(position?.latitude == 42.01588)
        #expect(position?.longitude == -87.66909)
        #expect(position?.heading == 310)
    }

    @Test func trainPositionReturnsNilForInvalidInput() {
        let dto = TrainPositionDTO(lat: "", lon: "", heading: "")
        let position = TrainPosition(from: dto)
        #expect(position == nil)
    }
}
