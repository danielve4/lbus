import Foundation
import Testing
@testable import LBus

@Suite struct PersistentCacheTests {

    private func makeTempDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("PersistentCacheTests-\(UUID().uuidString)")
    }

    // MARK: - Read/Write

    @Test func writeAndReadRoundTrip() async {
        let cache = PersistentCache(directory: makeTempDirectory())
        let routes = [BusRoute(from: BusRouteDTO(rt: "20", rtnm: "Madison", rtclr: "#336633", rtdd: "20"))]

        await cache.write(routes, forKey: "bus_routes")
        let entry = await cache.read([BusRoute].self, forKey: "bus_routes")

        #expect(entry != nil)
        #expect(entry!.data.count == 1)
        #expect(entry!.data[0].id == "20")
        #expect(entry!.data[0].name == "Madison")
    }

    @Test func readReturnsNilWhenEmpty() async {
        let cache = PersistentCache(directory: makeTempDirectory())
        let entry = await cache.read([BusRoute].self, forKey: "bus_routes")
        #expect(entry == nil)
    }

    // MARK: - Persistence across instances

    @Test func dataPersistedAcrossCacheInstances() async {
        let dir = makeTempDirectory()
        let cache1 = PersistentCache(directory: dir)
        let routes = [BusRoute(from: BusRouteDTO(rt: "66", rtnm: "Chicago", rtclr: "#009900", rtdd: "66"))]

        await cache1.write(routes, forKey: "bus_routes")

        let cache2 = PersistentCache(directory: dir)
        let entry = await cache2.read([BusRoute].self, forKey: "bus_routes")

        #expect(entry != nil)
        #expect(entry!.data[0].id == "66")
    }

    // MARK: - Expiry

    @Test func freshEntryIsNotExpired() async {
        let cache = PersistentCache(directory: makeTempDirectory())
        await cache.write(["test"], forKey: "key")
        let entry = await cache.read([String].self, forKey: "key")

        #expect(entry != nil)
        #expect(!entry!.isExpired())
    }

    @Test func staleEntryIsExpired() async {
        let eightDaysAgo = Date().addingTimeInterval(-8 * 24 * 60 * 60)
        let dir = makeTempDirectory()
        let cache = PersistentCache(directory: dir, now: { eightDaysAgo })
        await cache.write(["test"], forKey: "key")

        let entry = await cache.read([String].self, forKey: "key")

        #expect(entry != nil)
        #expect(entry!.isExpired())
    }

    @Test func isExpiredWithInjectedNow() {
        let sixDaysAgo = Date().addingTimeInterval(-6 * 24 * 60 * 60)
        let entry = CacheEntry(data: "test", timestamp: sixDaysAgo)

        #expect(!entry.isExpired(now: Date()))

        let futureNow = Date().addingTimeInterval(2 * 24 * 60 * 60)
        #expect(entry.isExpired(now: futureNow))
    }

    @Test func isExpiredAtExactBoundary() {
        let now = Date()
        let exactlyOneWeekAgo = now.addingTimeInterval(-CacheEntry<String>.defaultTTL)
        let entry = CacheEntry(data: "test", timestamp: exactlyOneWeekAgo)

        #expect(entry.isExpired(now: now))
    }

    // MARK: - Remove

    @Test func removeDeletesEntry() async {
        let cache = PersistentCache(directory: makeTempDirectory())
        await cache.write(["test"], forKey: "key")
        await cache.remove(forKey: "key")
        let entry = await cache.read([String].self, forKey: "key")
        #expect(entry == nil)
    }

    @Test func removeAllClearsAllEntries() async {
        let cache = PersistentCache(directory: makeTempDirectory())
        await cache.write(["a"], forKey: "key1")
        await cache.write(["b"], forKey: "key2")
        await cache.removeAll()

        let entry1 = await cache.read([String].self, forKey: "key1")
        let entry2 = await cache.read([String].self, forKey: "key2")
        #expect(entry1 == nil)
        #expect(entry2 == nil)
    }

    // MARK: - Edge cases

    @Test func readReturnsNilForMissingKey() async {
        let cache = PersistentCache(directory: makeTempDirectory())
        await cache.write(["test"], forKey: "key1")
        let entry = await cache.read([String].self, forKey: "key2")
        #expect(entry == nil)
    }

    @Test func differentKeysStoreIndependently() async {
        let cache = PersistentCache(directory: makeTempDirectory())
        await cache.write(["first"], forKey: "key1")
        await cache.write(["second"], forKey: "key2")

        let entry1 = await cache.read([String].self, forKey: "key1")
        let entry2 = await cache.read([String].self, forKey: "key2")
        #expect(entry1!.data == ["first"])
        #expect(entry2!.data == ["second"])
    }

    @Test func writeOverwritesExistingEntry() async {
        let cache = PersistentCache(directory: makeTempDirectory())
        await cache.write(["old"], forKey: "key")
        await cache.write(["new"], forKey: "key")

        let entry = await cache.read([String].self, forKey: "key")
        #expect(entry!.data == ["new"])
    }
}
