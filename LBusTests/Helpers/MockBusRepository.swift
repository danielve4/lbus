import Foundation
@testable import LBus

actor MockBusRepository: BusRepositoryProtocol {
    private(set) var getRoutesResult: [BusRoute]?
    private(set) var getRoutesError: Error?
    private var shouldSuspendGetRoutes = false
    private var getRoutesContinuation: CheckedContinuation<Void, Never>?
    private var getRoutesEnteredContinuation: CheckedContinuation<Void, Never>?

    func setGetRoutesResult(_ value: [BusRoute]?) { getRoutesResult = value }
    func setGetRoutesError(_ error: Error?) { getRoutesError = error }
    func setShouldSuspendGetRoutes(_ value: Bool) { shouldSuspendGetRoutes = value }

    /// Suspends until getRoutes() is entered. Call before triggering the code that calls getRoutes().
    func waitForGetRoutesCalled() async {
        await withCheckedContinuation { continuation in
            getRoutesEnteredContinuation = continuation
        }
    }

    /// Resumes a suspended getRoutes() call.
    func resumeGetRoutes() {
        getRoutesContinuation?.resume()
        getRoutesContinuation = nil
    }

    func getRoutes() async throws -> [BusRoute] {
        if shouldSuspendGetRoutes {
            getRoutesEnteredContinuation?.resume()
            getRoutesEnteredContinuation = nil
            await withCheckedContinuation { continuation in
                getRoutesContinuation = continuation
            }
        }
        if let error = getRoutesError { throw error }
        return getRoutesResult ?? []
    }

    // MARK: - getDirections

    private(set) var getDirectionsResult: [BusDirection]?
    private(set) var getDirectionsError: Error?
    private(set) var getDirectionsCalledWithRoute: String?
    private(set) var getDirectionsCallCount = 0
    private var shouldSuspendGetDirections = false
    private var getDirectionsContinuation: CheckedContinuation<Void, Never>?
    private var getDirectionsEnteredContinuation: CheckedContinuation<Void, Never>?

    func setGetDirectionsResult(_ value: [BusDirection]?) { getDirectionsResult = value }
    func setGetDirectionsError(_ error: Error?) { getDirectionsError = error }
    func setShouldSuspendGetDirections(_ value: Bool) { shouldSuspendGetDirections = value }

    func waitForGetDirectionsCalled() async {
        await withCheckedContinuation { continuation in
            getDirectionsEnteredContinuation = continuation
        }
    }

    func resumeGetDirections() {
        getDirectionsContinuation?.resume()
        getDirectionsContinuation = nil
    }

    func getDirections(route: String) async throws -> [BusDirection] {
        getDirectionsCalledWithRoute = route
        getDirectionsCallCount += 1
        if shouldSuspendGetDirections {
            getDirectionsEnteredContinuation?.resume()
            getDirectionsEnteredContinuation = nil
            await withCheckedContinuation { continuation in
                getDirectionsContinuation = continuation
            }
        }
        if let error = getDirectionsError { throw error }
        return getDirectionsResult ?? []
    }

    func getStops(route: String, direction: String) async throws -> [BusStop] {
        fatalError("Not implemented for RoutesViewModel tests")
    }

    func getArrivals(stopId: String) async throws -> [BusArrival] {
        fatalError("Not implemented for RoutesViewModel tests")
    }

    func getFollow(vehicleId: String) async throws -> [BusArrival] {
        fatalError("Not implemented for RoutesViewModel tests")
    }
}
