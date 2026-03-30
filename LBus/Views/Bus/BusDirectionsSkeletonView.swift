import SwiftUI

struct BusDirectionsSkeletonView: View {
    var body: some View {
        List {
            ForEach(0..<2, id: \.self) { _ in
                Label("Placeholder direction", systemImage: "arrow.right")
                    .redacted(reason: .placeholder)
                    .modifier(ShimmerModifier())
            }
        }
    }
}

#Preview {
    NavigationStack {
        BusDirectionsSkeletonView()
            .navigationTitle("Route 20")
    }
}
