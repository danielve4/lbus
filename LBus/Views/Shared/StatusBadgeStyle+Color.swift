import SwiftUI

extension StatusBadge.Style {
    var backgroundColor: Color {
        switch self {
        case .approaching: .blue
        case .scheduled: .yellow
        case .delayed: .red
        case .alert: .orange
        }
    }

    var textColor: Color {
        switch self {
        case .approaching: .white
        case .scheduled: .black
        case .delayed: .white
        case .alert: .white
        }
    }
}
