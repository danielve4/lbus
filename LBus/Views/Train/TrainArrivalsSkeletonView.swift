import SwiftUI

struct TrainArrivalsSkeletonView: View {
    var body: some View {
        List {
            Section {
                Text("Station ID: 40380")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        Text("Red")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.gray))
                    }
                }
            }
            .listRowSeparator(.hidden)

            Section {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Red")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(.gray))
                                Text("Howard")
                                    .font(.subheadline)
                            }
                            Text("Run #420")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("5 min")
                                .font(.headline)
                            Text("3:45 PM Today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                }
            } header: {
                Text("Northbound to Howard")
                    .font(.headline)
                    .foregroundStyle(.pink)
                    .textCase(nil)
            }
        }
        .redacted(reason: .placeholder)
    }
}
