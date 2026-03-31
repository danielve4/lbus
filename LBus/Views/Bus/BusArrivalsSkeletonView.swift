import SwiftUI

struct BusArrivalsSkeletonView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Placeholder Stop Name")
                        .font(.headline)
                    Text("Stop #00000")
                        .font(.subheadline)
                }
                .redacted(reason: .placeholder)
                .modifier(ShimmerModifier())
            }

            Section {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("20")
                                    .font(.caption.bold())
                                Text("Westbound")
                                    .font(.caption)
                            }
                            Text("Destination Name")
                                .font(.subheadline)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("5 min")
                                .font(.headline)
                            Text("4:06 PM Today")
                                .font(.caption)
                        }
                    }
                    .redacted(reason: .placeholder)
                    .modifier(ShimmerModifier())
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BusArrivalsSkeletonView()
            .navigationTitle("Madison & Jefferson")
    }
}
