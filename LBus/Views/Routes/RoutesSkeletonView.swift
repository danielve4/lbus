import SwiftUI

// TODO: Extract ShimmerModifier to shared utility when next screen needs shimmer (TODO 4.2+)
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 300)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

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
                            .padding(.horizontal, 6)
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
