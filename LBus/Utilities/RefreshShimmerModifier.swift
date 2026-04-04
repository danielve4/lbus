import SwiftUI

struct RefreshShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isActive {
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .offset(x: phase * 300)
                    }
                }
            )
            .clipped()
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    phase = -1
                    withAnimation(.linear(duration: 1.0)) {
                        phase = 1
                    }
                }
            }
    }
}
