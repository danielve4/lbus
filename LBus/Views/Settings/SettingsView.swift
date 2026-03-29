import SwiftUI

struct SettingsView: View {
    let favoritesRepository: FavoritesRepositoryProtocol

    @AppStorage(SettingsKeys.theme) private var theme: AppTheme = .system
    @AppStorage(SettingsKeys.autoRefreshEnabled) private var autoRefreshEnabled = true
    @AppStorage(SettingsKeys.refreshIntervalSeconds) private var refreshIntervalSeconds = 30
    @State private var showingClearAlert = false

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }

            Section("Refresh") {
                Toggle("Auto-Refresh", isOn: $autoRefreshEnabled)
                LabeledContent("Refresh Interval", value: "\(refreshIntervalSeconds)s")
            }

            Section("Data") {
                Button("Clear All Favorites", role: .destructive) {
                    showingClearAlert = true
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Clear All Favorites?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                try? favoritesRepository.removeAll()
            }
        } message: {
            Text("This will remove all saved favorites. This action cannot be undone.")
        }
    }
}
