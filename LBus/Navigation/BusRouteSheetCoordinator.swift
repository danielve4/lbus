import SwiftUI

@Observable
@MainActor
final class BusRouteSheetCoordinator {
    var selectedRoute: BusRoute?
    var pendingArrivals: BusNavigation?

    func selectRoute(_ route: BusRoute) {
        selectedRoute = route
    }

    func selectStop(navigation: BusNavigation) {
        pendingArrivals = navigation
        selectedRoute = nil
    }

    func handleDismiss(navigate: (BusNavigation) -> Void) {
        if let pending = pendingArrivals {
            navigate(pending)
            pendingArrivals = nil
        }
    }

    func close() {
        pendingArrivals = nil
        selectedRoute = nil
    }
}
