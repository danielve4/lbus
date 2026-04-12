import Foundation
@testable import LBus

actor MockTrainRepository: TrainRepositoryProtocol {
    private(set) var getTrainDataResult: TrainData?
    private(set) var getTrainDataError: Error?
    private(set) var getArrivalsResult: [TrainArrival]?
    private(set) var getArrivalsError: Error?
    private(set) var getFollowResult: [TrainArrival]?
    private(set) var getFollowError: Error?
    private(set) var getFollowCallCount: Int = 0
    private(set) var getFollowCalledWithVehicleId: String?

    func setGetTrainDataResult(_ value: TrainData?) { getTrainDataResult = value }
    func setGetTrainDataError(_ error: Error?) { getTrainDataError = error }
    func setGetArrivalsResult(_ value: [TrainArrival]?) { getArrivalsResult = value }
    func setGetArrivalsError(_ error: Error?) { getArrivalsError = error }
    func setGetFollowResult(_ value: [TrainArrival]?) { getFollowResult = value }
    func setGetFollowError(_ error: Error?) { getFollowError = error }

    func getTrainData() async throws -> TrainData {
        if let error = getTrainDataError { throw error }
        return getTrainDataResult ?? TrainData(lines: [], stations: [], stopSequences: [])
    }

    func getArrivals(stopId: String) async throws -> [TrainArrival] {
        if let error = getArrivalsError { throw error }
        return getArrivalsResult ?? []
    }

    func getFollow(vehicleId: String) async throws -> [TrainArrival] {
        getFollowCallCount += 1
        getFollowCalledWithVehicleId = vehicleId
        if let error = getFollowError { throw error }
        return getFollowResult ?? []
    }
}
