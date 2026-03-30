import Foundation
@testable import LBus

actor MockTrainRepository: TrainRepositoryProtocol {
    private(set) var getTrainDataResult: TrainData?
    private(set) var getTrainDataError: Error?

    func setGetTrainDataResult(_ value: TrainData?) { getTrainDataResult = value }
    func setGetTrainDataError(_ error: Error?) { getTrainDataError = error }

    func getTrainData() async throws -> TrainData {
        if let error = getTrainDataError { throw error }
        return getTrainDataResult ?? TrainData(lines: [], stations: [], stopSequences: [])
    }

    func getArrivals(stopId: String) async throws -> [TrainArrival] {
        fatalError("Not implemented for RoutesViewModel tests")
    }

    func getFollow(vehicleId: String) async throws -> [TrainArrival] {
        fatalError("Not implemented for RoutesViewModel tests")
    }
}
