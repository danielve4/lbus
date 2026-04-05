import Foundation
import Testing
@testable import LBus

@Suite struct BusRouteSheetCoordinatorTests {

    private let routeDTO = BusRouteDTO(rt: "20", rtnm: "Madison", rtclr: "#336633", rtdd: "20")
    private let arrivals = BusNavigation.arrivals(stopId: "456", stopName: "State & Lake", route: "20", direction: "Eastbound")

    @Test @MainActor func selectRouteSetsSelectedRoute() {
        let coordinator = BusRouteSheetCoordinator()
        let route = BusRoute(from: routeDTO)

        coordinator.selectRoute(route)

        #expect(coordinator.selectedRoute == route)
        #expect(coordinator.pendingArrivals == nil)
    }

    @Test @MainActor func selectStopSetsPendingAndClearsRoute() {
        let coordinator = BusRouteSheetCoordinator()
        let route = BusRoute(from: routeDTO)

        coordinator.selectRoute(route)
        coordinator.selectStop(navigation: arrivals)

        #expect(coordinator.selectedRoute == nil)
        #expect(coordinator.pendingArrivals == arrivals)
    }

    @Test @MainActor func handleDismissForwardsPendingAndClears() {
        let coordinator = BusRouteSheetCoordinator()

        coordinator.selectRoute(BusRoute(from: routeDTO))
        coordinator.selectStop(navigation: arrivals)

        var received: BusNavigation?
        coordinator.handleDismiss { received = $0 }

        #expect(received == arrivals)
        #expect(coordinator.pendingArrivals == nil)
    }

    @Test @MainActor func handleDismissWithoutPendingDoesNotNavigate() {
        let coordinator = BusRouteSheetCoordinator()

        var navigateCalled = false
        coordinator.handleDismiss { _ in navigateCalled = true }

        #expect(!navigateCalled)
    }

    @Test @MainActor func closeClearsBothWithoutNavigating() {
        let coordinator = BusRouteSheetCoordinator()
        let route = BusRoute(from: routeDTO)

        coordinator.selectRoute(route)
        coordinator.selectStop(navigation: arrivals)
        coordinator.close()

        #expect(coordinator.selectedRoute == nil)
        #expect(coordinator.pendingArrivals == nil)
    }

    @Test @MainActor func closeAfterSelectRouteDoesNotLeavePending() {
        let coordinator = BusRouteSheetCoordinator()

        coordinator.selectRoute(BusRoute(from: routeDTO))
        coordinator.close()

        var navigateCalled = false
        coordinator.handleDismiss { _ in navigateCalled = true }

        #expect(!navigateCalled)
        #expect(coordinator.selectedRoute == nil)
        #expect(coordinator.pendingArrivals == nil)
    }

    @Test @MainActor func fullFlowSelectRouteSelectStopDismiss() {
        let coordinator = BusRouteSheetCoordinator()
        let route = BusRoute(from: routeDTO)

        // 1. User taps a route → sheet opens
        coordinator.selectRoute(route)
        #expect(coordinator.selectedRoute == route)

        // 2. User drills to stops and taps one → pending set, sheet dismissed
        coordinator.selectStop(navigation: arrivals)
        #expect(coordinator.selectedRoute == nil)
        #expect(coordinator.pendingArrivals == arrivals)

        // 3. Sheet onDismiss fires → navigation forwarded
        var received: BusNavigation?
        coordinator.handleDismiss { received = $0 }
        #expect(received == arrivals)
        #expect(coordinator.pendingArrivals == nil)
    }
}
