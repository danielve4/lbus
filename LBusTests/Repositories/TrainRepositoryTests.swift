import Foundation
import Testing
@testable import LBus

// MARK: - Test Helpers

private func makeLineDTO(routeId: String = "Red", name: String = "Red Line", color: String = "#c60c30", textColor: String = "#ffffff") -> TrainLineDTO {
    TrainLineDTO(routeId: routeId, name: name, color: color, textColor: textColor)
}

private func makeEtaDTO(
    staId: String = "40360",
    stpId: String = "30070",
    staNm: String = "Southport",
    stpDe: String = "Service toward 95th/Dan Ryan",
    rn: String = "421",
    rt: String = "Red",
    destSt: String = "30089",
    destNm: String = "95th/Dan Ryan",
    trDr: String = "5",
    isApp: String = "0",
    isDly: String = "0"
) -> TrainEtaPredictionDTO {
    TrainEtaPredictionDTO(
        staId: staId,
        stpId: stpId,
        staNm: staNm,
        stpDe: stpDe,
        rn: rn,
        rt: rt,
        destSt: destSt,
        destNm: destNm,
        trDr: trDr,
        prdt: "2026-03-28T12:00:00",
        arrT: "2026-03-28T12:05:00",
        isApp: isApp,
        isSch: "0",
        isDly: isDly,
        isFlt: "0",
        flags: nil,
        lat: nil,
        lon: nil,
        heading: nil
    )
}

private func makeTrainData() -> TrainData {
    TrainData(
        lines: [TrainLine(id: "Red", name: "Red Line", colorHex: "#c60c30", textColorHex: "#ffffff")],
        stations: [TrainStation(id: "40360", name: "Southport", latitude: 41.943, longitude: -87.663)],
        stopSequences: [TrainStopSequence(id: "seq1", line: "Red", stops: ["40360"])]
    )
}

private func makeTrainDataResponse() -> TrainDataResponse {
    TrainDataResponse(
        lines: [makeLineDTO(routeId: "Red", name: "Red Line")],
        stations: ["40360": TrainStationDTO(name: "Southport", latitude: 41.943, longitude: -87.663)],
        stopSequences: ["seq1": TrainStopSequenceDTO(line: "Red", stops: ["40360"])],
        lastUpdated: "2026-03-28"
    )
}

// MARK: - Tests

@Suite struct TrainRepositoryTests {

    // MARK: - getTrainData

    @Test func getTrainDataReturnsAllData() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(TrainDataResponse(
            lines: [makeLineDTO(routeId: "Red", name: "Red Line"), makeLineDTO(routeId: "Blue", name: "Blue Line")],
            stations: [
                "40360": TrainStationDTO(name: "Southport", latitude: 41.943, longitude: -87.663),
                "40380": TrainStationDTO(name: "Clark/Lake", latitude: 41.885, longitude: -87.631)
            ],
            stopSequences: [
                "seq1": TrainStopSequenceDTO(line: "Red", stops: ["40360", "40380"])
            ],
            lastUpdated: "2026-03-28"
        ))
        let repo = TrainRepository(apiClient: mock, cache: MockPersistentCache())

        let data = try await repo.getTrainData()

        #expect(data.lines.count == 2)
        #expect(data.lines[0].name == "Blue Line" || data.lines[1].name == "Blue Line")
        #expect(data.stations.count == 2)
        #expect(data.stopSequences.count == 1)
        #expect(data.stopSequences[0].stops == ["40360", "40380"])
        #expect(await mock.lastPath == "traindata")
    }

    @Test func getTrainDataThrowsOnNetworkError() async throws {
        let mock = MockAPIClient()
        await mock.setGetError(APIError.networkError(URLError(.notConnectedToInternet)))
        let repo = TrainRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getTrainData()
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

    // MARK: - getArrivals

    @Test func getArrivalsReturnsPredictions() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(TrainArrivalsResponse(
            ctatt: .init(
                tmst: "2026-03-28T12:00:00",
                errCd: "0",
                errNm: nil,
                eta: [makeEtaDTO(rn: "421"), makeEtaDTO(rn: "422")]
            )
        ))
        let repo = TrainRepository(apiClient: mock, cache: MockPersistentCache())

        let arrivals = try await repo.getArrivals(stopId: "40360")

        #expect(arrivals.count == 2)
        #expect(arrivals[0].runNumber == "421")
        #expect(arrivals[1].runNumber == "422")
        #expect(await mock.lastPath == "trainstoparrivals")
        #expect(await mock.lastQueryItems == [URLQueryItem(name: "stopId", value: "40360")])
    }

    @Test func getArrivalsReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(TrainArrivalsResponse(
            ctatt: .init(tmst: "2026-03-28T12:00:00", errCd: "0", errNm: nil, eta: nil)
        ))
        let repo = TrainRepository(apiClient: mock, cache: MockPersistentCache())

        let arrivals = try await repo.getArrivals(stopId: "40360")

        #expect(arrivals.isEmpty)
    }

    @Test func getArrivalsThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(TrainArrivalsResponse(
            ctatt: .init(tmst: "2026-03-28T12:00:00", errCd: "501", errNm: "Invalid stop id", eta: nil)
        ))
        let repo = TrainRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getArrivals(stopId: "99999")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .apiError(let message) = error else {
                Issue.record("Expected apiError, got \(error)")
                return
            }
            #expect(message == "Invalid stop id")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func getArrivalsDecodingErrorPropagates() async throws {
        let mock = MockAPIClient()
        await mock.setGetError(APIError.decodingError(NSError(domain: "test", code: 0)))
        let repo = TrainRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getArrivals(stopId: "40360")
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

    // MARK: - getFollow

    @Test func getFollowReturnsPredictions() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(TrainFollowResponse(
            ctatt: .init(
                tmst: "2026-03-28T12:00:00",
                errCd: "0",
                errNm: nil,
                position: nil,
                eta: [makeEtaDTO(staId: "40360", staNm: "Southport"), makeEtaDTO(staId: "40380", staNm: "Clark/Lake")]
            )
        ))
        let repo = TrainRepository(apiClient: mock, cache: MockPersistentCache())

        let arrivals = try await repo.getFollow(vehicleId: "421")

        #expect(arrivals.count == 2)
        #expect(arrivals[0].stationName == "Southport")
        #expect(arrivals[1].stationName == "Clark/Lake")
        #expect(await mock.lastPath == "trainfollow")
        #expect(await mock.lastQueryItems == [URLQueryItem(name: "vehicleId", value: "421")])
    }

    @Test func getFollowReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(TrainFollowResponse(
            ctatt: .init(tmst: "2026-03-28T12:00:00", errCd: "0", errNm: nil, position: nil, eta: nil)
        ))
        let repo = TrainRepository(apiClient: mock, cache: MockPersistentCache())

        let arrivals = try await repo.getFollow(vehicleId: "421")

        #expect(arrivals.isEmpty)
    }

    @Test func getFollowThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(TrainFollowResponse(
            ctatt: .init(tmst: "2026-03-28T12:00:00", errCd: "501", errNm: "Invalid run number", position: nil, eta: nil)
        ))
        let repo = TrainRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getFollow(vehicleId: "99999")
            Issue.record("Expected error to be thrown")
        } catch let error as APIError {
            guard case .apiError(let message) = error else {
                Issue.record("Expected apiError, got \(error)")
                return
            }
            #expect(message == "Invalid run number")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func getFollowInvalidResponsePropagates() async throws {
        let mock = MockAPIClient()
        await mock.setGetError(APIError.invalidResponse(statusCode: 500))
        let repo = TrainRepository(apiClient: mock, cache: MockPersistentCache())

        do {
            _ = try await repo.getFollow(vehicleId: "421")
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

    @Test func getTrainDataReturnsFreshCacheWithoutAPICall() async throws {
        let mock = MockAPIClient()
        let cache = MockPersistentCache()
        await cache.write(makeTrainData(), forKey: CacheKeys.trainData)

        let repo = TrainRepository(apiClient: mock, cache: cache)
        let data = try await repo.getTrainData()

        #expect(data.lines.count == 1)
        #expect(data.lines[0].id == "Red")
        #expect(await mock.getCallCount == 0)
    }

    // MARK: - Cache: Stale-while-revalidate

    @Test func getTrainDataReturnsStaleCacheAndRefreshesInBackground() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(makeTrainDataResponse())
        let cache = MockPersistentCache()
        let staleData = TrainData(
            lines: [TrainLine(id: "Blue", name: "Blue Line", colorHex: "#00a1de", textColorHex: "#ffffff")],
            stations: [],
            stopSequences: []
        )
        await cache.writeStale(staleData, forKey: CacheKeys.trainData)

        let repo = TrainRepository(apiClient: mock, cache: cache)
        let data = try await repo.getTrainData()

        #expect(data.lines[0].id == "Blue")

        try await Task.sleep(for: .milliseconds(200))
        #expect(await mock.getCallCount == 1)

        let updated = await cache.read(TrainData.self, forKey: CacheKeys.trainData)
        #expect(updated?.data.lines.first?.id == "Red")
    }

    @Test func staleRefreshFailureKeepsStaleCacheAndNoError() async throws {
        let mock = MockAPIClient()
        await mock.setGetError(APIError.networkError(URLError(.notConnectedToInternet)))
        let cache = MockPersistentCache()
        let staleData = TrainData(
            lines: [TrainLine(id: "Blue", name: "Blue Line", colorHex: "#00a1de", textColorHex: "#ffffff")],
            stations: [],
            stopSequences: []
        )
        await cache.writeStale(staleData, forKey: CacheKeys.trainData)

        let repo = TrainRepository(apiClient: mock, cache: cache)
        let data = try await repo.getTrainData()

        #expect(data.lines[0].id == "Blue")

        try await Task.sleep(for: .milliseconds(200))

        let stillStale = await cache.read(TrainData.self, forKey: CacheKeys.trainData)
        #expect(stillStale?.data.lines.first?.id == "Blue")
    }

    // MARK: - Cache: Network fetch writes to cache

    @Test func getTrainDataWritesToCacheOnNetworkFetch() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(makeTrainDataResponse())
        let cache = MockPersistentCache()
        let repo = TrainRepository(apiClient: mock, cache: cache)

        _ = try await repo.getTrainData()

        let writeCount = await cache.writeCount
        #expect(writeCount == 1)
    }

    // MARK: - Cache: Arrivals and follow NEVER cached

    @Test func getArrivalsDoesNotTouchCache() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(TrainArrivalsResponse(
            ctatt: .init(tmst: "2026-03-28T12:00:00", errCd: "0", errNm: nil, eta: [makeEtaDTO()])
        ))
        let cache = MockPersistentCache()
        let repo = TrainRepository(apiClient: mock, cache: cache)

        _ = try await repo.getArrivals(stopId: "40360")

        let readCount = await cache.readCount
        let writeCount = await cache.writeCount
        #expect(readCount == 0)
        #expect(writeCount == 0)
    }

    @Test func getFollowDoesNotTouchCache() async throws {
        let mock = MockAPIClient()
        await mock.setGetResult(TrainFollowResponse(
            ctatt: .init(tmst: "2026-03-28T12:00:00", errCd: "0", errNm: nil, position: nil, eta: [makeEtaDTO()])
        ))
        let cache = MockPersistentCache()
        let repo = TrainRepository(apiClient: mock, cache: cache)

        _ = try await repo.getFollow(vehicleId: "421")

        let readCount = await cache.readCount
        let writeCount = await cache.writeCount
        #expect(readCount == 0)
        #expect(writeCount == 0)
    }
}
