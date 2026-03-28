import SwiftUI

struct FavoritesPlaceholderView: View {
    var body: some View {
        ContentUnavailableView("Favorites", systemImage: "star", description: Text("Coming soon"))
            .navigationTitle("Favorites")
    }
}

#Preview {
    NavigationStack {
        FavoritesPlaceholderView()
    }
}
