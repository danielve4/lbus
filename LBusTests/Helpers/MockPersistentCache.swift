import Foundation
@testable import LBus

actor MockPersistentCache: PersistentCacheProtocol {
    var storage: [String: Data] = [:]
    var readCount = 0
    var writeCount = 0

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func read<T: Codable & Sendable>(_ type: T.Type, forKey key: String) -> CacheEntry<T>? {
        readCount += 1
        guard let data = storage[key] else { return nil }
        return try? decoder.decode(CacheEntry<T>.self, from: data)
    }

    func write<T: Codable & Sendable>(_ value: T, forKey key: String) {
        writeCount += 1
        let entry = CacheEntry(data: value, timestamp: Date())
        storage[key] = try? encoder.encode(entry)
    }

    func writeStale<T: Codable & Sendable>(_ value: T, forKey key: String) {
        let entry = CacheEntry(data: value, timestamp: Date().addingTimeInterval(-8 * 24 * 60 * 60))
        storage[key] = try? encoder.encode(entry)
    }

    func isExpired<T: Codable & Sendable>(_ entry: CacheEntry<T>) -> Bool {
        entry.isExpired()
    }

    func remove(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    func removeAll() {
        storage.removeAll()
    }
}
