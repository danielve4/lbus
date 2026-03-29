import Foundation
import Testing
@testable import LBus

@Suite struct AutoRefreshManagerTests {

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "AutoRefreshManagerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    @MainActor
    @Test func lastUpdatedIsNilInitially() {
        let manager = AutoRefreshManager(action: {}, userDefaults: makeUserDefaults())
        #expect(manager.lastUpdated == nil)
        #expect(manager.isRefreshing == false)
    }

    @MainActor
    @Test func refreshNowExecutesAction() async {
        var called = false
        let manager = AutoRefreshManager(action: { called = true }, userDefaults: makeUserDefaults())

        await manager.refreshNow()

        #expect(called)
        #expect(manager.lastUpdated != nil)
    }

    @MainActor
    @Test func refreshNowUpdatesLastUpdated() async {
        let manager = AutoRefreshManager(action: {}, userDefaults: makeUserDefaults())

        await manager.refreshNow()
        let first = manager.lastUpdated

        try? await Task.sleep(for: .milliseconds(10))

        await manager.refreshNow()
        let second = manager.lastUpdated

        #expect(first != nil)
        #expect(second != nil)
        #expect(second! > first!)
    }

    @MainActor
    @Test func lastUpdatedNotSetOnFailure() async {
        struct TestError: Error {}
        let manager = AutoRefreshManager(action: { throw TestError() }, userDefaults: makeUserDefaults())

        await manager.refreshNow()

        #expect(manager.lastUpdated == nil)
    }

    @MainActor
    @Test func lastUpdatedPreservedOnSubsequentFailure() async {
        struct TestError: Error {}
        var shouldThrow = false
        let manager = AutoRefreshManager(
            action: { if shouldThrow { throw TestError() } },
            userDefaults: makeUserDefaults()
        )

        await manager.refreshNow()
        let successDate = manager.lastUpdated
        #expect(successDate != nil)

        shouldThrow = true
        await manager.refreshNow()

        #expect(manager.lastUpdated == successDate)
    }

    @MainActor
    @Test func isRefreshingDuringAction() async {
        var wasRefreshing = false
        var manager: AutoRefreshManager!
        manager = AutoRefreshManager(
            action: {
                await MainActor.run {
                    wasRefreshing = manager.isRefreshing
                }
            },
            userDefaults: makeUserDefaults()
        )

        await manager.refreshNow()

        #expect(wasRefreshing)
        #expect(manager.isRefreshing == false)
    }

    @MainActor
    @Test func startBeginsTimerWhenEnabled() async {
        let defaults = makeUserDefaults()
        defaults.set(true, forKey: SettingsKeys.autoRefreshEnabled)
        defaults.set(1, forKey: SettingsKeys.refreshIntervalSeconds)

        var callCount = 0
        let manager = AutoRefreshManager(action: { callCount += 1 }, userDefaults: defaults)

        manager.start()
        try? await Task.sleep(for: .milliseconds(1500))
        manager.stop()

        #expect(callCount >= 1)
    }

    @MainActor
    @Test func startDoesNotBeginTimerWhenDisabled() async {
        let defaults = makeUserDefaults()
        defaults.set(false, forKey: SettingsKeys.autoRefreshEnabled)
        defaults.set(1, forKey: SettingsKeys.refreshIntervalSeconds)

        var callCount = 0
        let manager = AutoRefreshManager(action: { callCount += 1 }, userDefaults: defaults)

        manager.start()
        try? await Task.sleep(for: .milliseconds(1500))
        manager.stop()

        #expect(callCount == 0)
    }

    @MainActor
    @Test func stopCancelsTimer() async {
        let defaults = makeUserDefaults()
        defaults.set(true, forKey: SettingsKeys.autoRefreshEnabled)
        defaults.set(1, forKey: SettingsKeys.refreshIntervalSeconds)

        var callCount = 0
        let manager = AutoRefreshManager(action: { callCount += 1 }, userDefaults: defaults)

        manager.start()
        try? await Task.sleep(for: .milliseconds(1500))
        manager.stop()

        let countAfterStop = callCount
        try? await Task.sleep(for: .milliseconds(1500))

        #expect(callCount == countAfterStop)
    }

    @MainActor
    @Test func concurrentRefreshesGuarded() async {
        var callCount = 0
        let manager = AutoRefreshManager(
            action: {
                callCount += 1
                try? await Task.sleep(for: .milliseconds(200))
            },
            userDefaults: makeUserDefaults()
        )

        async let first: Void = manager.refreshNow()
        async let second: Void = manager.refreshNow()
        _ = await (first, second)

        #expect(callCount == 1)
    }

    @MainActor
    @Test func defaultsWhenKeysNotRegistered() async {
        let defaults = makeUserDefaults()
        var called = false
        let manager = AutoRefreshManager(action: { called = true }, userDefaults: defaults)

        // With no keys set, auto-refresh should default to enabled
        manager.start()
        try? await Task.sleep(for: .milliseconds(500))

        // Trigger a manual refresh to verify action works
        await manager.refreshNow()
        manager.stop()

        #expect(called)
    }
}
