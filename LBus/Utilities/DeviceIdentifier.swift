import Foundation

protocol DeviceIdentifierProtocol: Sendable {
    var id: String { get }
}

final class DeviceIdentifier: DeviceIdentifierProtocol, Sendable {
    private static let key = "lbus_device_identifier"

    let id: String

    init(userDefaults: UserDefaults = .standard) {
        if let existing = userDefaults.string(forKey: DeviceIdentifier.key) {
            self.id = existing
        } else {
            let newId = UUID().uuidString
            userDefaults.set(newId, forKey: DeviceIdentifier.key)
            self.id = newId
        }
    }
}
