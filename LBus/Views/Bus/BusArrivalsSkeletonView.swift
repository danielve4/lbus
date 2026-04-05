import SwiftUI

struct BusArrivalsSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Eastbound")
                            .font(.headline)
                            .foregroundStyle(.pink)
                        Text("Last refreshed at 12:00:00 PM")
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .modifier(ShimmerModifier())

                LazyVStack(spacing: 0) {
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .modifier(ShimmerModifier())

                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
    }
}

#Preview {
    NavigationStack {
        BusArrivalsSkeletonView()
            .navigationTitle("Madison & Jefferson")
    }
}
