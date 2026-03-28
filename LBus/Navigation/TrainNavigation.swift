import Foundation

enum TrainNavigation: Hashable {
    case stations(line: TrainLine)
    case arrivals(stopId: String, stationName: String, line: TrainLine?)
    case follow(runNumber: String, stopId: String)
}
