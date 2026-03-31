import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private func makeRouteDTO(rt: String = "20", rtnm: String = "Madison", rtclr: String = "#336633", rtdd: String = "20") -> BusRouteDTO {
    BusRouteDTO(rt: rt, rtnm: rtnm, rtclr: rtclr, rtdd: rtdd)
}

private func makeDirectionDTO(dir: String = "Eastbound") -> BusDirectionDTO {
    BusDirectionDTO(dir: dir)
}

private func makeStopDTO(stpid: String = "456", stpnm: String = "State & Lake", lat: Double = 41.886, lon: Double = -87.628) -> BusStopDTO {
    BusStopDTO(stpid: stpid, stpnm: stpnm, lat: lat, lon: lon)
}

private func makePredictionDTO(
    vid: String = "8184",
    stpid: String = "456",
    stpnm: String = "State & Lake",
    rt: String = "20",
    rtdir: String = "Eastbound",
    des: String = "Austin",
    dly: Bool = false
) -> BusPredictionDTO {
    BusPredictionDTO(
        tmstmp: "20260328 12:00",
        typ: "A",
        stpid: stpid,
        stpnm: stpnm,
        vid: vid,
        dstp: 1200,
        rt: rt,
        rtdd: rt,
        rtdir: rtdir,
        des: des,
        prdtm: "20260328 12:05",
        dly: dly,
        tablockid: "20 -653",
        tatripid: "1010",
        origtatripno: "010101010",
        zone: "",
        prdctdn: "5",
        dyn: nil,
        psgld: nil,
        stst: nil,
        stsd: nil,
        flagstop: nil,
        nbus: nil
    )
}

// MARK: - Tests

@Suite struct BusRepositoryTests {

    // MARK: - getRoutes

    @Test func getRoutesReturnsRoutes() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusRoutesResponse(
            routes: [makeRouteDTO(rt: "20", rtnm: "Madison"), makeRouteDTO(rt: "66", rtnm: "Chicago")],
            error: nil
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let routes = try await repo.getRoutes()

        #expect(routes.count == 2)
        #expect(routes[0].id == "20")
        #expect(routes[0].name == "Madison")
        #expect(routes[1].id == "66")
        #expect(routes[1].name == "Chicago")
        #expect(await mock.lastPath == "busroutes")
    }

    @Test func getRoutesReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusRoutesResponse(routes: nil, error: nil))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let routes = try await repo.getRoutes()

        #expect(routes.isEmpty)
    }

    @Test func getRoutesThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusRoutesResponse(
            routes: nil,
            error: [BusAPIError(msg: "No data found for parameter", rt: nil, rtdir: nil, stpid: nil, vid: nil)]
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getRoutes()
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .apiError(let message) = error else {
                Issue.record("Expected apiError, got \(error)")
                return
            }
            #expect(message == "No data found for parameter")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func getRoutesThrowsOnNetworkError() async throws {
        let mock = MockAPIClient()
        await mock.setGetError(APIError.networkError(URLError(.notConnectedToInternet)))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getRoutes()
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .networkError = error else {
                Issue.record("Expected networkError, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - getDirections

    @Test func getDirectionsReturnsDirections() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusDirectionsResponse(
            directions: [makeDirectionDTO(dir: "Eastbound"), makeDirectionDTO(dir: "Westbound")],
            error: nil
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let directions = try await repo.getDirections(route: "20")

        #expect(directions.count == 2)
        #expect(directions[0].direction == "Eastbound")
        #expect(directions[1].direction == "Westbound")
        #expect(await mock.lastPath == "busroutedirections")
        #expect(await mock.lastQueryItems == [URLQueryItem(name: "route", value: "20")])
    }

    @Test func getDirectionsReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusDirectionsResponse(directions: nil, error: nil))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let directions = try await repo.getDirections(route: "999")

        #expect(directions.isEmpty)
    }

    @Test func getDirectionsThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusDirectionsResponse(
            directions: nil,
            error: [BusAPIError(msg: "No data found for parameter", rt: "999", rtdir: nil, stpid: nil, vid: nil)]
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getDirections(route: "999")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .apiError = error else {
                Issue.record("Expected apiError, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - getStops

    @Test func getStopsReturnsStops() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusStopsResponse(
            stops: [makeStopDTO(stpid: "456", stpnm: "State & Lake"), makeStopDTO(stpid: "789", stpnm: "Clark & Lake")],
            error: nil
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let stops = try await repo.getStops(route: "20", direction: "Eastbound")

        #expect(stops.count == 2)
        #expect(stops[0].id == "456")
        #expect(stops[0].name == "State & Lake")
        #expect(stops[1].id == "789")
        #expect(await mock.lastPath == "busroutestops")
        #expect(await mock.lastQueryItems == [
            URLQueryItem(name: "route", value: "20"),
            URLQueryItem(name: "direction", value: "Eastbound")
        ])
    }

    @Test func getStopsReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusStopsResponse(stops: nil, error: nil))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let stops = try await repo.getStops(route: "20", direction: "Eastbound")

        #expect(stops.isEmpty)
    }

    @Test func getStopsThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusStopsResponse(
            stops: nil,
            error: [BusAPIError(msg: "No data found for parameter", rt: "20", rtdir: "Eastbound", stpid: nil, vid: nil)]
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getStops(route: "20", direction: "Eastbound")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .apiError = error else {
                Issue.record("Expected apiError, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - getArrivals

    @Test func getArrivalsReturnsPredictions() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusPredictionsResponse(
            prd: [makePredictionDTO(vid: "8184"), makePredictionDTO(vid: "8200")],
            error: nil
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let arrivals = try await repo.getArrivals(stopId: "456")

        #expect(arrivals.count == 2)
        #expect(arrivals[0].vehicleId == "8184")
        #expect(arrivals[1].vehicleId == "8200")
        #expect(await mock.lastPath == "busstoparrivals")
        #expect(await mock.lastQueryItems == [URLQueryItem(name: "stopId", value: "456")])
    }

    @Test func getArrivalsReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusPredictionsResponse(prd: nil, error: nil))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let arrivals = try await repo.getArrivals(stopId: "456")

        #expect(arrivals.isEmpty)
    }

    @Test func getArrivalsReturnsEmptyForNoArrivalTimes() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusPredictionsResponse(
            prd: nil,
            error: [BusAPIError(msg: "No arrival times", rt: nil, rtdir: nil, stpid: "456", vid: nil)]
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let arrivals = try await repo.getArrivals(stopId: "456")

        #expect(arrivals.isEmpty)
    }

    @Test func getArrivalsReturnsEmptyForNoServiceScheduled() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusPredictionsResponse(
            prd: nil,
            error: [BusAPIError(msg: "No service scheduled", rt: nil, rtdir: nil, stpid: "456", vid: nil)]
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let arrivals = try await repo.getArrivals(stopId: "456")

        #expect(arrivals.isEmpty)
    }

    @Test func getArrivalsThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusPredictionsResponse(
            prd: nil,
            error: [BusAPIError(msg: "No data found for parameter", rt: nil, rtdir: nil, stpid: "456", vid: nil)]
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getArrivals(stopId: "456")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .apiError = error else {
                Issue.record("Expected apiError, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - getFollow

    @Test func getFollowReturnsPredictions() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusPredictionsResponse(
            prd: [makePredictionDTO(vid: "8184", stpid: "456"), makePredictionDTO(vid: "8184", stpid: "789")],
            error: nil
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let arrivals = try await repo.getFollow(vehicleId: "8184")

        #expect(arrivals.count == 2)
        #expect(arrivals[0].stopId == "456")
        #expect(arrivals[1].stopId == "789")
        #expect(await mock.lastPath == "busfollow")
        #expect(await mock.lastQueryItems == [URLQueryItem(name: "vehicleId", value: "8184")])
    }

    @Test func getFollowReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusPredictionsResponse(prd: nil, error: nil))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        let arrivals = try await repo.getFollow(vehicleId: "8184")

        #expect(arrivals.isEmpty)
    }

    @Test func getFollowThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusPredictionsResponse(
            prd: nil,
            error: [BusAPIError(msg: "No data found for parameter", rt: nil, rtdir: nil, stpid: nil, vid: "8184")]
        ))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getFollow(vehicleId: "8184")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .apiError = error else {
                Issue.record("Expected apiError, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Error propagation

    @Test func decodingErrorPropagates() async throws {
        let mock = MockAPIClient()
        await mock.setGetError(APIError.decodingError(NSError(domain: "test", code: 0)))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getArrivals(stopId: "456")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .decodingError = error else {
                Issue.record("Expected decodingError, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func invalidResponseErrorPropagates() async throws {
        let mock = MockAPIClient()
        await mock.setGetError(APIError.invalidResponse(statusCode: 500))
        let repo = BusRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getStops(route: "20", direction: "Eastbound")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .invalidResponse(let code) = error else {
                Issue.record("Expected invalidResponse, got \(error)")
                return
            }
            #expect(code == 500)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Cache: Fresh hit

    @Test func getRoutesReturnsFreshCacheWithoutAPICall() async throws {
        let mock = MockAPIClient()
        let cache = MockPersistentCache()
        let routes = [BusRoute(id: "20", name: "Madison", colorHex: "#336633", shortName: "20")]
        await cache.write(routes, forKey: CacheKeys.busRoutes)

        let repo = BusRepository(apiClient: mock, cache: cache)
        let result = try await repo.getRoutes()

        #expect(result.count == 1)
        #expect(result[0].id == "20")
        #expect(await mock.getCallCount == 0)
    }

    @Test func getDirectionsReturnsFreshCacheWithoutAPICall() async throws {
        let mock = MockAPIClient()
        let cache = MockPersistentCache()
        let directions = [BusDirection(direction: "Eastbound")]
        await cache.write(directions, forKey: CacheKeys.busDirections(route: "20"))

        let repo = BusRepository(apiClient: mock, cache: cache)
        let result = try await repo.getDirections(route: "20")

        #expect(result.count == 1)
        #expect(result[0].direction == "Eastbound")
        #expect(await mock.getCallCount == 0)
    }

    @Test func getStopsReturnsFreshCacheWithoutAPICall() async throws {
        let mock = MockAPIClient()
        let cache = MockPersistentCache()
        let stops = [BusStop(id: "456", name: "State & Lake", latitude: 41.886, longitude: -87.628)]
        await cache.write(stops, forKey: CacheKeys.busStops(route: "20", direction: "Eastbound"))

        let repo = BusRepository(apiClient: mock, cache: cache)
        let result = try await repo.getStops(route: "20", direction: "Eastbound")

        #expect(result.count == 1)
        #expect(result[0].id == "456")
        #expect(await mock.getCallCount == 0)
    }

    // MARK: - Cache: Stale-while-revalidate

    @Test func getRoutesReturnsStaleCacheAndRefreshesInBackground() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusRoutesResponse(
            routes: [makeRouteDTO(rt: "66", rtnm: "Chicago")],
            error: nil
        ))
        let cache = MockPersistentCache()
        let staleRoutes = [BusRoute(id: "20", name: "Madison", colorHex: "#336633", shortName: "20")]
        await cache.writeStale(staleRoutes, forKey: CacheKeys.busRoutes)

        let repo = BusRepository(apiClient: mock, cache: cache)
        let result = try await repo.getRoutes()

        #expect(result[0].id == "20")

        try await Task.sleep(for: .milliseconds(200))
        #expect(await mock.getCallCount == 1)

        let updated = await cache.read([BusRoute].self, forKey: CacheKeys.busRoutes)
        #expect(updated?.data.first?.id == "66")
    }

    @Test func getDirectionsReturnsStaleCacheAndRefreshesInBackground() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusDirectionsResponse(
            directions: [makeDirectionDTO(dir: "Westbound")],
            error: nil
        ))
        let cache = MockPersistentCache()
        let staleDirections = [BusDirection(direction: "Eastbound")]
        await cache.writeStale(staleDirections, forKey: CacheKeys.busDirections(route: "20"))

        let repo = BusRepository(apiClient: mock, cache: cache)
        let result = try await repo.getDirections(route: "20")

        #expect(result[0].direction == "Eastbound")

        try await Task.sleep(for: .milliseconds(200))
        #expect(await mock.getCallCount == 1)

        let updated = await cache.read([BusDirection].self, forKey: CacheKeys.busDirections(route: "20"))
        #expect(updated?.data.first?.direction == "Westbound")
    }

    @Test func getStopsReturnsStaleCacheAndRefreshesInBackground() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusStopsResponse(
            stops: [makeStopDTO(stpid: "789", stpnm: "Clark & Lake")],
            error: nil
        ))
        let cache = MockPersistentCache()
        let staleStops = [BusStop(id: "456", name: "State & Lake", latitude: 41.886, longitude: -87.628)]
        await cache.writeStale(staleStops, forKey: CacheKeys.busStops(route: "20", direction: "Eastbound"))

        let repo = BusRepository(apiClient: mock, cache: cache)
        let result = try await repo.getStops(route: "20", direction: "Eastbound")

        #expect(result[0].id == "456")

        try await Task.sleep(for: .milliseconds(200))
        #expect(await mock.getCallCount == 1)

        let updated = await cache.read([BusStop].self, forKey: CacheKeys.busStops(route: "20", direction: "Eastbound"))
        #expect(updated?.data.first?.id == "789")
    }

    @Test func staleRefreshFailureKeepsStaleCacheAndNoError() async throws {
        let mock = MockAPIClient()
        await mock.setGetError(APIError.networkError(URLError(.notConnectedToInternet)))
        let cache = MockPersistentCache()
        let staleRoutes = [BusRoute(id: "20", name: "Madison", colorHex: "#336633", shortName: "20")]
        await cache.writeStale(staleRoutes, forKey: CacheKeys.busRoutes)

        let repo = BusRepository(apiClient: mock, cache: cache)
        let result = try await repo.getRoutes()

        #expect(result[0].id == "20")

        try await Task.sleep(for: .milliseconds(200))

        let stillStale = await cache.read([BusRoute].self, forKey: CacheKeys.busRoutes)
        #expect(stillStale?.data.first?.id == "20")
    }

    // MARK: - Cache: Network fetch writes to cache

    @Test func getRoutesWritesToCacheOnNetworkFetch() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusRoutesResponse(routes: [makeRouteDTO()], error: nil))
        let cache = MockPersistentCache()
        let repo = BusRepository(apiClient: mock, cache: cache)

        _ = try await repo.getRoutes()

        let writeCount = await cache.writeCount
        #expect(writeCount == 1)
    }

    // MARK: - Cache: Arrivals and follow NEVER cached

    @Test func getArrivalsDoesNotTouchCache() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusPredictionsResponse(prd: [makePredictionDTO()], error: nil))
        let cache = MockPersistentCache()
        let repo = BusRepository(apiClient: mock, cache: cache)

        _ = try await repo.getArrivals(stopId: "456")

        let readCount = await cache.readCount
        let writeCount = await cache.writeCount
        #expect(readCount == 0)
        #expect(writeCount == 0)
    }

    @Test func getFollowDoesNotTouchCache() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(BusPredictionsResponse(prd: [makePredictionDTO()], error: nil))
        let cache = MockPersistentCache()
        let repo = BusRepository(apiClient: mock, cache: cache)

        _ = try await repo.getFollow(vehicleId: "8184")

        let readCount = await cache.readCount
        let writeCount = await cache.writeCount
        #expect(readCount == 0)
        #expect(writeCount == 0)
    }
}
