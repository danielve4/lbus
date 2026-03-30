import Foundation
import CryptoKit

struct CacheEntry<T: Codable & Sendable>: Codable, Sendable {
    let data: T
    let timestamp: Date

    func isExpired(now: Date = Date()) -> Bool {
        now.timeIntervalSince(timestamp) >= Self.defaultTTL
    }

    static var defaultTTL: TimeInterval { 7 * 24 * 60 * 60 }
}

protocol PersistentCacheProtocol: Sendable {
    func read<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async -> CacheEntry<T>?
    func write<T: Codable & Sendable>(_ value: T, forKey key: String) async
    func remove(forKey key: String) async
    func removeAll() async
    func isExpired<T: Codable & Sendable>(_ entry: CacheEntry<T>) async -> Bool
}

actor PersistentCache: PersistentCacheProtocol {
    private let directory: URL
    private let now: @Sendable () -> Date
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(directory: URL? = nil, now: @escaping @Sendable () -> Date = { Date() }) {
        if let directory {
            self.directory = directory
        } else {
            self.directory = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("LBusRouteCache", isDirectory: true)
        }
        self.now = now
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func read<T: Codable & Sendable>(_ type: T.Type, forKey key: String) -> CacheEntry<T>? {
        let fileURL = fileURL(forKey: key)
        guard let data = try? Data(contentsOf: fileURL),
              let entry = try? decoder.decode(CacheEntry<T>.self, from: data) else {
            return nil
        }
        return entry
    }

    func write<T: Codable & Sendable>(_ value: T, forKey key: String) {
        let entry = CacheEntry(data: value, timestamp: now())
        let fileURL = fileURL(forKey: key)
        guard let data = try? encoder.encode(entry) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func remove(forKey key: String) {
        let fileURL = fileURL(forKey: key)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func removeAll() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    func isExpired<T: Codable & Sendable>(_ entry: CacheEntry<T>) -> Bool {
        entry.isExpired(now: now())
    }

    private func fileURL(forKey key: String) -> URL {
        let hash = SHA256.hash(data: Data(key.utf8))
        let filename = hash.compactMap { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent("\(filename).json")
    }
}
