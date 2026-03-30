import SwiftUI

struct RoutesSkeletonView: View {
    var body: some View {
        List {
            Section("Train Lines") {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Circle()
                            .frame(width: 12, height: 12)
                        Text("Placeholder line name")
                    }
                    .redacted(reason: .placeholder)
                    .modifier(ShimmerModifier())
                }
            }
            Section("Bus Routes") {
                ForEach(0..<8, id: \.self) { _ in
                    HStack(spacing: 12) {
                        Text("00")
                            .font(.caption.bold())
                            .frame(width: 36)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(.tertiary))
                        Text("Placeholder route name")
                    }
                    .redacted(reason: .placeholder)
                    .modifier(ShimmerModifier())
                }
            }
        }
        .searchable(text: .constant(""), prompt: "Search routes")
    }
}

#Preview {
    NavigationStack {
        RoutesSkeletonView()
            .navigationTitle("Routes")
    }
}
