import SwiftUI

struct BusFollowSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("To Austin")
                            .font(.subheadline)
                            .foregroundStyle(.pink)
                        Text("Last refreshed at 4:06:10 PM")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .modifier(ShimmerModifier())

                LazyVStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(index == 0 ? Color.pink : Color.clear)
                                .frame(width: 4)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Stop Name Here")
                                        .font(.subheadline)
                                    Text("Stop 12345")
                                        .font(.caption)
                                    Text("0.3 mi away")
                                        .font(.caption2)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("5 min")
                                        .font(.headline)
                                    Text("4:06 PM Today")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .background(index == 0 ? Color.pink.opacity(0.08) : Color.clear)
                        .modifier(ShimmerModifier())

                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
    }
}

#Preview {
    NavigationStack {
        BusFollowSkeletonView()
            .navigationTitle("RT 20")
            .navigationBarTitleDisplayMode(.inline)
    }
}
