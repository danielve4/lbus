import Foundation

enum TrainNavigation: Hashable {
    case stations(line: TrainLine)
    case arrivals(stationId: String, stationName: String, line: TrainLine?)
    case follow(runNumber: String, stopId: String)
}
