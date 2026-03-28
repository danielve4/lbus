import SwiftUI

struct SettingsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("Settings", systemImage: "gear", description: Text("Coming soon"))
            .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsPlaceholderView()
    }
}
