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
    private let cache: PersistentCacheProtocol
    private var inFlightRefreshTasks: [String: Task<Void, Never>] = [:]

    init(apiClient: APIClientProtocol, cache: PersistentCacheProtocol = PersistentCache()) {
        self.apiClient = apiClient
        self.cache = cache
    }

    func getRoutes() async throws -> [BusRoute] {
        let key = CacheKeys.busRoutes

        if let entry = await cache.read([BusRoute].self, forKey: key) {
            if !(await cache.isExpired(entry)) {
                return entry.data
            }
            if inFlightRefreshTasks[key] == nil {
                inFlightRefreshTasks[key] = Task { [weak self, apiClient, cache] in
                    defer { self?.inFlightRefreshTasks.removeValue(forKey: key) }
                    if let fresh = try? await Self.fetchRoutes(apiClient: apiClient) {
                        await cache.write(fresh, forKey: key)
                    }
                }
            }
            return entry.data
        }

        let routes = try await Self.fetchRoutes(apiClient: apiClient)
        await cache.write(routes, forKey: key)
        return routes
    }

    func getDirections(route: String) async throws -> [BusDirection] {
        let key = CacheKeys.busDirections(route: route)

        if let entry = await cache.read([BusDirection].self, forKey: key) {
            if !(await cache.isExpired(entry)) {
                return entry.data
            }
            if inFlightRefreshTasks[key] == nil {
                inFlightRefreshTasks[key] = Task { [weak self, apiClient, cache] in
                    defer { self?.inFlightRefreshTasks.removeValue(forKey: key) }
                    if let fresh = try? await Self.fetchDirections(apiClient: apiClient, route: route) {
                        await cache.write(fresh, forKey: key)
                    }
                }
            }
            return entry.data
        }

        let directions = try await Self.fetchDirections(apiClient: apiClient, route: route)
        await cache.write(directions, forKey: key)
        return directions
    }

    func getStops(route: String, direction: String) async throws -> [BusStop] {
        let key = CacheKeys.busStops(route: route, direction: direction)

        if let entry = await cache.read([BusStop].self, forKey: key) {
            if !(await cache.isExpired(entry)) {
                return entry.data
            }
            if inFlightRefreshTasks[key] == nil {
                inFlightRefreshTasks[key] = Task { [weak self, apiClient, cache] in
                    defer { self?.inFlightRefreshTasks.removeValue(forKey: key) }
                    if let fresh = try? await Self.fetchStops(apiClient: apiClient, route: route, direction: direction) {
                        await cache.write(fresh, forKey: key)
                    }
                }
            }
            return entry.data
        }

        let stops = try await Self.fetchStops(apiClient: apiClient, route: route, direction: direction)
        await cache.write(stops, forKey: key)
        return stops
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

    // MARK: - Network Fetch Helpers

    private static func fetchRoutes(apiClient: APIClientProtocol) async throws -> [BusRoute] {
        let response: BusRoutesResponse = try await apiClient.get(path: "busroutes")
        if let data = response.routes {
            return data.map(BusRoute.init(from:))
        }
        if let message = response.error?.first?.msg {
            throw APIError.apiError(message: message)
        }
        return []
    }

    private static func fetchDirections(apiClient: APIClientProtocol, route: String) async throws -> [BusDirection] {
        let response: BusDirectionsResponse = try await apiClient.get(
            path: "busroutedirections",
            queryItems: [URLQueryItem(name: "route", value: route)]
        )
        if let data = response.directions {
            return data.map(BusDirection.init(from:))
        }
        if let message = response.error?.first?.msg {
            throw APIError.apiError(message: message)
        }
        return []
    }

    private static func fetchStops(apiClient: APIClientProtocol, route: String, direction: String) async throws -> [BusStop] {
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
        if let message = response.error?.first?.msg {
            throw APIError.apiError(message: message)
        }
        return []
    }

    private func throwIfAPIError(_ errors: [BusAPIError]?) throws {
        if let message = errors?.first?.msg {
            if message == "No arrival times" || message == "No service scheduled" { return }
            throw APIError.apiError(message: message)
        }
    }
}
