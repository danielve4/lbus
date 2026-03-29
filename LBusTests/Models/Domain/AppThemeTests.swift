import SwiftUI
import Testing
@testable import LBus

@Suite struct AppThemeTests {

    @Test func systemColorSchemeIsNil() {
        #expect(AppTheme.system.colorScheme == nil)
    }

    @Test func lightColorSchemeIsLight() {
        #expect(AppTheme.light.colorScheme == .light)
    }

    @Test func darkColorSchemeIsDark() {
        #expect(AppTheme.dark.colorScheme == .dark)
    }

    @Test func rawValueRoundTrip() {
        for theme in AppTheme.allCases {
            #expect(AppTheme(rawValue: theme.rawValue) == theme)
        }
    }

    @Test func allCasesContainsThreeCases() {
        #expect(AppTheme.allCases.count == 3)
    }

    @Test func displayNames() {
        #expect(AppTheme.system.displayName == "System")
        #expect(AppTheme.light.displayName == "Light")
        #expect(AppTheme.dark.displayName == "Dark")
    }
}
