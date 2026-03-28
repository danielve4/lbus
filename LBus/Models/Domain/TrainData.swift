import Foundation

struct TrainData: Equatable, Sendable {
    let lines: [TrainLine]
    let stations: [TrainStation]
    let stopSequences: [TrainStopSequence]
}
