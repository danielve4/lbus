import Foundation
import Testing
@testable import LBus

@Suite struct TrainStationTests {

    @Test func mapsFromDTOWithId() {
        let dto = TrainStationDTO(name: "Pulaski", latitude: 41.7899, longitude: -87.7242)
        let station = TrainStation(id: "40960", from: dto)
        #expect(station.id == "40960")
        #expect(station.name == "Pulaski")
        #expect(station.latitude == 41.7899)
        #expect(station.longitude == -87.7242)
    }

    @Test func mapAllFromDictionary() {
        let stations: [String: TrainStationDTO] = [
            "40960": TrainStationDTO(name: "Pulaski", latitude: 41.7899, longitude: -87.7242),
            "41190": TrainStationDTO(name: "Midway", latitude: 41.7866, longitude: -87.7378)
        ]
        let mapped = TrainStation.mapAll(from: stations)
        #expect(mapped.count == 2)
        #expect(mapped.contains { $0.id == "40960" && $0.name == "Pulaski" })
        #expect(mapped.contains { $0.id == "41190" && $0.name == "Midway" })
    }

    @Test func mapAllFromEmptyDictionary() {
        let mapped = TrainStation.mapAll(from: [:])
        #expect(mapped.isEmpty)
    }

    @Test func mapsStopSequence() {
        let dto = TrainStopSequenceDTO(line: "Red", stops: ["40900", "41190"])
        let seq = TrainStopSequence(id: "Red-N", from: dto)
        #expect(seq.id == "Red-N")
        #expect(seq.line == "Red")
        #expect(seq.stops == ["40900", "41190"])
    }

    @Test func mapAllStopSequences() {
        let sequences: [String: TrainStopSequenceDTO] = [
            "Red-N": TrainStopSequenceDTO(line: "Red", stops: ["40900"]),
            "Blue-W": TrainStopSequenceDTO(line: "Blue", stops: ["40890", "40820"])
        ]
        let mapped = TrainStopSequence.mapAll(from: sequences)
        #expect(mapped.count == 2)
        #expect(mapped.contains { $0.id == "Red-N" })
        #expect(mapped.contains { $0.id == "Blue-W" })
    }
}
