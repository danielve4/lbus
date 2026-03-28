import Foundation
import Testing
@testable import LBus

@Suite struct DeviceIdentifierTests {

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "DeviceIdentifierTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    @Test func generatesUUIDWhenKeyAbsent() {
        let defaults = makeUserDefaults()
        let identifier = DeviceIdentifier(userDefaults: defaults)

        #expect(!identifier.id.isEmpty)
        #expect(UUID(uuidString: identifier.id) != nil)
    }

    @Test func returnsSameIdOnSubsequentCreation() {
        let defaults = makeUserDefaults()
        let first = DeviceIdentifier(userDefaults: defaults)
        let second = DeviceIdentifier(userDefaults: defaults)

        #expect(first.id == second.id)
    }

    @Test func storedValueIsValidUUID() {
        let defaults = makeUserDefaults()
        let identifier = DeviceIdentifier(userDefaults: defaults)

        let stored = defaults.string(forKey: "lbus_device_identifier")
        #expect(stored == identifier.id)
        #expect(UUID(uuidString: stored!) != nil)
    }
}
