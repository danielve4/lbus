import Foundation

nonisolated struct TrainData: Equatable, Sendable, Codable {
    let lines: [TrainLine]
    let stations: [TrainStation]
    let stopSequences: [TrainStopSequence]
}
