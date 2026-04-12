import Foundation
@testable import LBus

actor MockTrainRepository: TrainRepositoryProtocol {
    private(set) var getTrainDataResult: TrainData?
    private(set) var getTrainDataError: Error?
    private(set) var getArrivalsResult: [TrainArrival]?
    private(set) var getArrivalsError: Error?

    func setGetTrainDataResult(_ value: TrainData?) { getTrainDataResult = value }
    func setGetTrainDataError(_ error: Error?) { getTrainDataError = error }
    func setGetArrivalsResult(_ value: [TrainArrival]?) { getArrivalsResult = value }
    func setGetArrivalsError(_ error: Error?) { getArrivalsError = error }

    func getTrainData() async throws -> TrainData {
        if let error = getTrainDataError { throw error }
        return getTrainDataResult ?? TrainData(lines: [], stations: [], stopSequences: [])
    }

    func getArrivals(stopId: String) async throws -> [TrainArrival] {
        if let error = getArrivalsError { throw error }
        return getArrivalsResult ?? []
    }

    func getFollow(vehicleId: String) async throws -> [TrainArrival] {
        fatalError("Not implemented")
    }
}
