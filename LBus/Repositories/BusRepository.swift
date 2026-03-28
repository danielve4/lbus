import Foundation

protocol BusRepositoryProtocol: Sendable {
    func getRoutes() async throws -> [BusRoute]
    func getDirections(route: String) async throws -> [BusDirection]
    func getStops(route: String, direction: String) async throws -> [BusStop]
    func getArrivals(stopId: String) async throws -> [BusArrival]
    func getFollow(vehicleId: String) async throws -> [BusArrival]
}

final class BusRepository: BusRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func getRoutes() async throws -> [BusRoute] {
        let response: BusRoutesResponse = try await apiClient.get(path: "busroutes")
        if let data = response.routes {
            return data.map(BusRoute.init(from:))
        }
        try throwIfAPIError(response.error)
        return []
    }

    func getDirections(route: String) async throws -> [BusDirection] {
        let response: BusDirectionsResponse = try await apiClient.get(
            path: "busroutedirections",
            queryItems: [URLQueryItem(name: "route", value: route)]
        )
        if let data = response.directions {
            return data.map(BusDirection.init(from:))
        }
        try throwIfAPIError(response.error)
        return []
    }

    func getStops(route: String, direction: String) async throws -> [BusStop] {
        let response: BusStopsResponse = try await apiClient.get(
            path: "busroutestops",
            queryItems: [
                URLQueryItem(name: "route", value: route),
                URLQueryItem(name: "direction", value: direction)
            ]
        )
        if let data = response.stops {
            return data.map(BusStop.init(from:))
        }
        try throwIfAPIError(response.error)
        return []
    }

    func getArrivals(stopId: String) async throws -> [BusArrival] {
        let response: BusPredictionsResponse = try await apiClient.get(
            path: "busstoparrivals",
            queryItems: [URLQueryItem(name: "stopId", value: stopId)]
        )
        if let data = response.prd {
            return data.map(BusArrival.init(from:))
        }
        try throwIfAPIError(response.error)
        return []
    }

    func getFollow(vehicleId: String) async throws -> [BusArrival] {
        let response: BusPredictionsResponse = try await apiClient.get(
            path: "busfollow",
            queryItems: [URLQueryItem(name: "vehicleId", value: vehicleId)]
        )
        if let data = response.prd {
            return data.map(BusArrival.init(from:))
        }
        try throwIfAPIError(response.error)
        return []
    }

    private func throwIfAPIError(_ errors: [BusAPIError]?) throws {
        if let message = errors?.first?.msg {
            throw APIError.apiError(message: message)
        }
    }
}
