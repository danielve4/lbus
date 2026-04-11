import SwiftUI

struct TrainStationsSkeletonView: View {
    var body: some View {
        List {
            ForEach(0..<6, id: \.self) { _ in
                HStack {
                    Text("Placeholder station name")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.tertiary)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
        .searchable(text: .constant(""), placement: .navigationBarDrawer(displayMode: .always), prompt: "Search stations")
    }
}

#Preview {
    NavigationStack {
        TrainStationsSkeletonView()
            .navigationTitle("Red Line")
    }
}
