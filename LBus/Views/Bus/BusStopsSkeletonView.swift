import SwiftUI

struct BusStopsSkeletonView: View {
    var body: some View {
        List {
            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading) {
                    Text("Placeholder stop name")
                    Text("Stop #00000")
                        .font(.caption)
                }
                .redacted(reason: .placeholder)
                .modifier(ShimmerModifier())
            }
        }
    }
}

#Preview {
    NavigationStack {
        BusStopsSkeletonView()
            .navigationTitle("Route 20 Eastbound")
    }
}
