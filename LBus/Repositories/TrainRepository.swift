import Foundation

protocol TrainRepositoryProtocol: Sendable {
    func getTrainData() async throws -> TrainData
    func getArrivals(stopId: String) async throws -> [TrainArrival]
    func getFollow(vehicleId: String) async throws -> [TrainArrival]
}

final class TrainRepository: TrainRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func getTrainData() async throws -> TrainData {
        let response: TrainDataResponse = try await apiClient.get(path: "traindata")
        return TrainData(
            lines: response.lines.map(TrainLine.init(from:)),
            stations: TrainStation.mapAll(from: response.stations),
            stopSequences: TrainStopSequence.mapAll(from: response.stopSequences)
        )
    }

    func getArrivals(stopId: String) async throws -> [TrainArrival] {
        let response: TrainArrivalsResponse = try await apiClient.get(
            path: "trainstoparrivals",
            queryItems: [URLQueryItem(name: "stopId", value: stopId)]
        )
        if let data = response.ctatt.eta {
            return data.map(TrainArrival.init(from:))
        }
        try throwIfAPIError(errCd: response.ctatt.errCd, errNm: response.ctatt.errNm)
        return []
    }

    func getFollow(vehicleId: String) async throws -> [TrainArrival] {
        let response: TrainFollowResponse = try await apiClient.get(
            path: "trainfollow",
            queryItems: [URLQueryItem(name: "vehicleId", value: vehicleId)]
        )
        if let data = response.ctatt.eta {
            return data.map(TrainArrival.init(from:))
        }
        try throwIfAPIError(errCd: response.ctatt.errCd, errNm: response.ctatt.errNm)
        return []
    }

    private func throwIfAPIError(errCd: String, errNm: String?) throws {
        if errCd != "0", let message = errNm {
            throw APIError.apiError(message: message)
        }
    }
}
