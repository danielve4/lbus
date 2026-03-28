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

// MARK: - Tests

@Suite struct TrainRepositoryTests {

    // MARK: - getTrainData

    @Test func getTrainDataReturnsAllData() async throws {
        let mock = MockAPIClient()
        mock.getResult = TrainDataResponse(
            lines: [makeLineDTO(routeId: "Red", name: "Red Line"), makeLineDTO(routeId: "Blue", name: "Blue Line")],
            stations: [
                "40360": TrainStationDTO(name: "Southport", latitude: 41.943, longitude: -87.663),
                "40380": TrainStationDTO(name: "Clark/Lake", latitude: 41.885, longitude: -87.631)
            ],
            stopSequences: [
                "seq1": TrainStopSequenceDTO(line: "Red", stops: ["40360", "40380"])
            ],
            lastUpdated: "2026-03-28"
        )
        let repo = TrainRepository(apiClient: mock)

        let data = try await repo.getTrainData()

        #expect(data.lines.count == 2)
        #expect(data.lines[0].name == "Blue Line" || data.lines[1].name == "Blue Line")
        #expect(data.stations.count == 2)
        #expect(data.stopSequences.count == 1)
        #expect(data.stopSequences[0].stops == ["40360", "40380"])
        #expect(mock.lastPath == "traindata")
    }

    @Test func getTrainDataThrowsOnNetworkError() async throws {
        let mock = MockAPIClient()
        mock.getError = APIError.networkError(URLError(.notConnectedToInternet))
        let repo = TrainRepository(apiClient: mock)

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
        mock.getResult = TrainArrivalsResponse(
            ctatt: .init(
                tmst: "2026-03-28T12:00:00",
                errCd: "0",
                errNm: nil,
                eta: [makeEtaDTO(rn: "421"), makeEtaDTO(rn: "422")]
            )
        )
        let repo = TrainRepository(apiClient: mock)

        let arrivals = try await repo.getArrivals(stopId: "40360")

        #expect(arrivals.count == 2)
        #expect(arrivals[0].runNumber == "421")
        #expect(arrivals[1].runNumber == "422")
        #expect(mock.lastPath == "trainstoparrivals")
        #expect(mock.lastQueryItems == [URLQueryItem(name: "stopId", value: "40360")])
    }

    @Test func getArrivalsReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        mock.getResult = TrainArrivalsResponse(
            ctatt: .init(tmst: "2026-03-28T12:00:00", errCd: "0", errNm: nil, eta: nil)
        )
        let repo = TrainRepository(apiClient: mock)

        let arrivals = try await repo.getArrivals(stopId: "40360")

        #expect(arrivals.isEmpty)
    }

    @Test func getArrivalsThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        mock.getResult = TrainArrivalsResponse(
            ctatt: .init(tmst: "2026-03-28T12:00:00", errCd: "501", errNm: "Invalid stop id", eta: nil)
        )
        let repo = TrainRepository(apiClient: mock)

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
        mock.getError = APIError.decodingError(NSError(domain: "test", code: 0))
        let repo = TrainRepository(apiClient: mock)

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
        mock.getResult = TrainFollowResponse(
            ctatt: .init(
                tmst: "2026-03-28T12:00:00",
                errCd: "0",
                errNm: nil,
                position: nil,
                eta: [makeEtaDTO(staId: "40360", staNm: "Southport"), makeEtaDTO(staId: "40380", staNm: "Clark/Lake")]
            )
        )
        let repo = TrainRepository(apiClient: mock)

        let arrivals = try await repo.getFollow(vehicleId: "421")

        #expect(arrivals.count == 2)
        #expect(arrivals[0].stationName == "Southport")
        #expect(arrivals[1].stationName == "Clark/Lake")
        #expect(mock.lastPath == "trainfollow")
        #expect(mock.lastQueryItems == [URLQueryItem(name: "vehicleId", value: "421")])
    }

    @Test func getFollowReturnsEmptyWhenNilAndNoError() async throws {
        let mock = MockAPIClient()
        mock.getResult = TrainFollowResponse(
            ctatt: .init(tmst: "2026-03-28T12:00:00", errCd: "0", errNm: nil, position: nil, eta: nil)
        )
        let repo = TrainRepository(apiClient: mock)

        let arrivals = try await repo.getFollow(vehicleId: "421")

        #expect(arrivals.isEmpty)
    }

    @Test func getFollowThrowsOnAPIError() async throws {
        let mock = MockAPIClient()
        mock.getResult = TrainFollowResponse(
            ctatt: .init(tmst: "2026-03-28T12:00:00", errCd: "501", errNm: "Invalid run number", position: nil, eta: nil)
        )
        let repo = TrainRepository(apiClient: mock)

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
        mock.getError = APIError.invalidResponse(statusCode: 500)
        let repo = TrainRepository(apiClient: mock)

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
}
