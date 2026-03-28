import SwiftUI

struct HomePlaceholderView: View {
    var body: some View {
        ContentUnavailableView("Home", systemImage: "house", description: Text("Coming soon"))
            .navigationTitle("Home")
    }
}

#Preview {
    NavigationStack {
        HomePlaceholderView()
    }
}
