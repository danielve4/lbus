import Foundation

protocol TrainRepositoryProtocol: Sendable {
    func getTrainData() async throws -> TrainData
    func getArrivals(stopId: String) async throws -> [TrainArrival]
    func getFollow(vehicleId: String) async throws -> [TrainArrival]
}

final class TrainRepository: TrainRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let cache: PersistentCacheProtocol
    private var inFlightRefreshTasks: [String: Task<Void, Never>] = [:]

    init(apiClient: APIClientProtocol, cache: PersistentCacheProtocol = PersistentCache()) {
        self.apiClient = apiClient
        self.cache = cache
    }

    func getTrainData() async throws -> TrainData {
        let key = CacheKeys.trainData

        if let entry = await cache.read(TrainData.self, forKey: key) {
            if !(await cache.isExpired(entry)) {
                return entry.data
            }
            if inFlightRefreshTasks[key] == nil {
                inFlightRefreshTasks[key] = Task { [weak self, apiClient, cache] in
                    defer { self?.inFlightRefreshTasks.removeValue(forKey: key) }
                    if let fresh = try? await Self.fetchTrainData(apiClient: apiClient) {
                        await cache.write(fresh, forKey: key)
                    }
                }
            }
            return entry.data
        }

        let data = try await Self.fetchTrainData(apiClient: apiClient)
        await cache.write(data, forKey: key)
        return data
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

    // MARK: - Network Fetch Helpers

    private static func fetchTrainData(apiClient: APIClientProtocol) async throws -> TrainData {
        let response: TrainDataResponse = try await apiClient.get(path: "traindata")
        return TrainData(from: response)
    }

    private func throwIfAPIError(errCd: String, errNm: String?) throws {
        if errCd != "0", let message = errNm {
            throw APIError.apiError(message: message)
        }
    }
}
