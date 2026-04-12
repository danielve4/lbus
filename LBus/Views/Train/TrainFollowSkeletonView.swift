import SwiftUI

struct TrainFollowSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Red Line")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("To Howard")
                        .font(.subheadline)
                        .foregroundStyle(.pink)
                    Text("Last refreshed at 4:06:10 PM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 12)

                LazyVStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(index == 0 ? Color.pink : Color.clear)
                                .frame(width: 4)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Station Name Here")
                                        .font(.subheadline)
                                        .fontWeight(index == 0 ? .semibold : .regular)
                                    Text("Service toward Howard")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("5 min")
                                        .font(.headline)
                                    Text("4:06 PM Today")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .background(index == 0 ? Color.pink.opacity(0.08) : Color.clear)

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
        TrainFollowSkeletonView()
            .navigationTitle("Run #123")
            .navigationBarTitleDisplayMode(.inline)
    }
}
