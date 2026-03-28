import SwiftUI

struct RoutesPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("Routes", systemImage: "bus", description: Text("Coming soon"))
            .navigationTitle("Routes")
    }
}

#Preview {
    NavigationStack {
        RoutesPlaceholderView()
    }
}
