import SwiftUI

struct BusArrivalsSkeletonView: View {
    var body: some View {
        List {
            Section {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("20")
                                    .font(.caption.bold())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .frame(minWidth: 24)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(.tertiary))
                                Text("Westbound")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Destination Name")
                                .font(.subheadline)
                            Text("686 ft")
                                .font(.caption2)
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
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                }

                Text("Last refreshed at 12:00:00 PM")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Eastbound")
                    .font(.headline)
                    .foregroundStyle(.pink)
                    .textCase(nil)
            }.modifier(ShimmerModifier())
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
