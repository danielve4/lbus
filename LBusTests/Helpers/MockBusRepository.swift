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

    // MARK: - getStops

    private(set) var getStopsResult: [BusStop]?
    private(set) var getStopsError: Error?
    private(set) var getStopsCalledWithRoute: String?
    private(set) var getStopsCalledWithDirection: String?
    private(set) var getStopsCallCount = 0
    private var shouldSuspendGetStops = false
    private var getStopsContinuation: CheckedContinuation<Void, Never>?
    private var getStopsEnteredContinuation: CheckedContinuation<Void, Never>?
    private var getStopsAlreadyCalled = false

    func setGetStopsResult(_ value: [BusStop]?) { getStopsResult = value }
    func setGetStopsError(_ error: Error?) { getStopsError = error }
    func setShouldSuspendGetStops(_ value: Bool) { shouldSuspendGetStops = value }

    /// Waits until getStops() is entered. Uses a latched flag so it returns
    /// immediately if getStops() was already called before this method.
    func waitForGetStopsCalled() async {
        if getStopsAlreadyCalled { return }
        await withCheckedContinuation { continuation in
            getStopsEnteredContinuation = continuation
        }
    }

    func resumeGetStops() {
        getStopsContinuation?.resume()
        getStopsContinuation = nil
    }

    func getStops(route: String, direction: String) async throws -> [BusStop] {
        getStopsCalledWithRoute = route
        getStopsCalledWithDirection = direction
        getStopsCallCount += 1
        if shouldSuspendGetStops {
            if let entered = getStopsEnteredContinuation {
                getStopsEnteredContinuation = nil
                entered.resume()
            } else {
                getStopsAlreadyCalled = true
            }
            await withCheckedContinuation { continuation in
                getStopsContinuation = continuation
            }
        }
        if let error = getStopsError { throw error }
        return getStopsResult ?? []
    }

    // MARK: - getArrivals

    private(set) var getArrivalsResult: [BusArrival]?
    private(set) var getArrivalsError: Error?
    private(set) var getArrivalsCalledWithStopId: String?
    private(set) var getArrivalsCallCount = 0
    private var shouldSuspendGetArrivals = false
    private var getArrivalsContinuation: CheckedContinuation<Void, Never>?
    private var getArrivalsEnteredContinuation: CheckedContinuation<Void, Never>?
    private var getArrivalsAlreadyCalled = false

    func setGetArrivalsResult(_ value: [BusArrival]?) { getArrivalsResult = value }
    func setGetArrivalsError(_ error: Error?) { getArrivalsError = error }
    func setShouldSuspendGetArrivals(_ value: Bool) { shouldSuspendGetArrivals = value }

    func waitForGetArrivalsCalled() async {
        if getArrivalsAlreadyCalled { return }
        await withCheckedContinuation { continuation in
            getArrivalsEnteredContinuation = continuation
        }
    }

    func resumeGetArrivals() {
        getArrivalsContinuation?.resume()
        getArrivalsContinuation = nil
    }

    func getArrivals(stopId: String) async throws -> [BusArrival] {
        getArrivalsCalledWithStopId = stopId
        getArrivalsCallCount += 1
        if shouldSuspendGetArrivals {
            if let entered = getArrivalsEnteredContinuation {
                getArrivalsEnteredContinuation = nil
                entered.resume()
            } else {
                getArrivalsAlreadyCalled = true
            }
            await withCheckedContinuation { continuation in
                getArrivalsContinuation = continuation
            }
        }
        if let error = getArrivalsError { throw error }
        return getArrivalsResult ?? []
    }

    // MARK: - getFollow

    private(set) var getFollowResult: [BusArrival]?
    private(set) var getFollowError: Error?
    private(set) var getFollowCalledWithVehicleId: String?
    private(set) var getFollowCallCount = 0
    private var shouldSuspendGetFollow = false
    private var getFollowContinuation: CheckedContinuation<Void, Never>?
    private var getFollowEnteredContinuation: CheckedContinuation<Void, Never>?
    private var getFollowAlreadyCalled = false

    func setGetFollowResult(_ value: [BusArrival]?) { getFollowResult = value }
    func setGetFollowError(_ error: Error?) { getFollowError = error }
    func setShouldSuspendGetFollow(_ value: Bool) { shouldSuspendGetFollow = value }

    func waitForGetFollowCalled() async {
        if getFollowAlreadyCalled { return }
        await withCheckedContinuation { continuation in
            getFollowEnteredContinuation = continuation
        }
    }

    func resumeGetFollow() {
        getFollowContinuation?.resume()
        getFollowContinuation = nil
    }

    func getFollow(vehicleId: String) async throws -> [BusArrival] {
        getFollowCalledWithVehicleId = vehicleId
        getFollowCallCount += 1
        if shouldSuspendGetFollow {
            if let entered = getFollowEnteredContinuation {
                getFollowEnteredContinuation = nil
                entered.resume()
            } else {
                getFollowAlreadyCalled = true
            }
            await withCheckedContinuation { continuation in
                getFollowContinuation = continuation
            }
        }
        if let error = getFollowError { throw error }
        return getFollowResult ?? []
    }
}
