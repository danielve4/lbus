import SwiftUI

struct StatusBadgeView: View {
    let label: String
    let style: StatusBadge.Style

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(style.textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(style.backgroundColor))
    }
}
