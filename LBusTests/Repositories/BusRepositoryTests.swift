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
        mock.getResult = BusRoutesResponse(
            routes: [makeRouteDTO(rt: "20", rtnm: "Madison"), makeRouteDTO(rt: "66", rtnm: "Chicago")],
            error: nil
        )
        let repo = BusRepository(apiClient: mock)

        let routes = try await repo.getRoutes()

        #expect(routes.count == 2)
        #expect(routes[0].id == "20")
        #expect(routes[0].name == "Madison")
        #expect(routes[1].id == "66")
        #expect(routes[1].name == "Chicago")
        #expect(mock.lastPath == "busroutes")
    }

    @Test func getRoutesReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        mock.getResult = BusRoutesResponse(routes: nil, error: nil)
        let repo = BusRepository(apiClient: mock)

        let routes = try await repo.getRoutes()

        #expect(routes.isEmpty)
    }

    @Test func getRoutesThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        mock.getResult = BusRoutesResponse(
            routes: nil,
            error: [BusAPIError(msg: "No data found for parameter", rt: nil, rtdir: nil, stpid: nil, vid: nil)]
        )
        let repo = BusRepository(apiClient: mock)

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
        mock.getError = APIError.networkError(URLError(.notConnectedToInternet))
        let repo = BusRepository(apiClient: mock)

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
        mock.getResult = BusDirectionsResponse(
            directions: [makeDirectionDTO(dir: "Eastbound"), makeDirectionDTO(dir: "Westbound")],
            error: nil
        )
        let repo = BusRepository(apiClient: mock)

        let directions = try await repo.getDirections(route: "20")

        #expect(directions.count == 2)
        #expect(directions[0].direction == "Eastbound")
        #expect(directions[1].direction == "Westbound")
        #expect(mock.lastPath == "busroutedirections")
        #expect(mock.lastQueryItems == [URLQueryItem(name: "route", value: "20")])
    }

    @Test func getDirectionsReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        mock.getResult = BusDirectionsResponse(directions: nil, error: nil)
        let repo = BusRepository(apiClient: mock)

        let directions = try await repo.getDirections(route: "999")

        #expect(directions.isEmpty)
    }

    @Test func getDirectionsThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        mock.getResult = BusDirectionsResponse(
            directions: nil,
            error: [BusAPIError(msg: "No data found for parameter", rt: "999", rtdir: nil, stpid: nil, vid: nil)]
        )
        let repo = BusRepository(apiClient: mock)

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
        mock.getResult = BusStopsResponse(
            stops: [makeStopDTO(stpid: "456", stpnm: "State & Lake"), makeStopDTO(stpid: "789", stpnm: "Clark & Lake")],
            error: nil
        )
        let repo = BusRepository(apiClient: mock)

        let stops = try await repo.getStops(route: "20", direction: "Eastbound")

        #expect(stops.count == 2)
        #expect(stops[0].id == "456")
        #expect(stops[0].name == "State & Lake")
        #expect(stops[1].id == "789")
        #expect(mock.lastPath == "busroutestops")
        #expect(mock.lastQueryItems == [
            URLQueryItem(name: "route", value: "20"),
            URLQueryItem(name: "direction", value: "Eastbound")
        ])
    }

    @Test func getStopsReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        mock.getResult = BusStopsResponse(stops: nil, error: nil)
        let repo = BusRepository(apiClient: mock)

        let stops = try await repo.getStops(route: "20", direction: "Eastbound")

        #expect(stops.isEmpty)
    }

    @Test func getStopsThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        mock.getResult = BusStopsResponse(
            stops: nil,
            error: [BusAPIError(msg: "No data found for parameter", rt: "20", rtdir: "Eastbound", stpid: nil, vid: nil)]
        )
        let repo = BusRepository(apiClient: mock)

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
        mock.getResult = BusPredictionsResponse(
            prd: [makePredictionDTO(vid: "8184"), makePredictionDTO(vid: "8200")],
            error: nil
        )
        let repo = BusRepository(apiClient: mock)

        let arrivals = try await repo.getArrivals(stopId: "456")

        #expect(arrivals.count == 2)
        #expect(arrivals[0].vehicleId == "8184")
        #expect(arrivals[1].vehicleId == "8200")
        #expect(mock.lastPath == "busstoparrivals")
        #expect(mock.lastQueryItems == [URLQueryItem(name: "stopId", value: "456")])
    }

    @Test func getArrivalsReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        mock.getResult = BusPredictionsResponse(prd: nil, error: nil)
        let repo = BusRepository(apiClient: mock)

        let arrivals = try await repo.getArrivals(stopId: "456")

        #expect(arrivals.isEmpty)
    }

    @Test func getArrivalsThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        mock.getResult = BusPredictionsResponse(
            prd: nil,
            error: [BusAPIError(msg: "No data found for parameter", rt: nil, rtdir: nil, stpid: "456", vid: nil)]
        )
        let repo = BusRepository(apiClient: mock)

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
        mock.getResult = BusPredictionsResponse(
            prd: [makePredictionDTO(vid: "8184", stpid: "456"), makePredictionDTO(vid: "8184", stpid: "789")],
            error: nil
        )
        let repo = BusRepository(apiClient: mock)

        let arrivals = try await repo.getFollow(vehicleId: "8184")

        #expect(arrivals.count == 2)
        #expect(arrivals[0].stopId == "456")
        #expect(arrivals[1].stopId == "789")
        #expect(mock.lastPath == "busfollow")
        #expect(mock.lastQueryItems == [URLQueryItem(name: "vehicleId", value: "8184")])
    }

    @Test func getFollowReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        mock.getResult = BusPredictionsResponse(prd: nil, error: nil)
        let repo = BusRepository(apiClient: mock)

        let arrivals = try await repo.getFollow(vehicleId: "8184")

        #expect(arrivals.isEmpty)
    }

    @Test func getFollowThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        mock.getResult = BusPredictionsResponse(
            prd: nil,
            error: [BusAPIError(msg: "No data found for parameter", rt: nil, rtdir: nil, stpid: nil, vid: "8184")]
        )
        let repo = BusRepository(apiClient: mock)

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
        mock.getError = APIError.decodingError(NSError(domain: "test", code: 0))
        let repo = BusRepository(apiClient: mock)

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
        mock.getError = APIError.invalidResponse(statusCode: 500)
        let repo = BusRepository(apiClient: mock)

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
}
