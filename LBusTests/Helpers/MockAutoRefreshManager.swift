import Foundation
@testable import LBus

@MainActor
@Observable
final class MockAutoRefreshManager: AutoRefreshManagerProtocol {
    var lastUpdated: Date?
    var isRefreshing: Bool = false

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var refreshNowCallCount = 0

    var onRefreshNow: (() async -> Void)?

    func start() {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }

    func refreshNow() async {
        refreshNowCallCount += 1
        await onRefreshNow?()
    }
}
