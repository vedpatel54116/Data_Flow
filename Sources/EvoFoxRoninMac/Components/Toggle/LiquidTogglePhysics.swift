import SwiftUI

/// Physics constants matching CSS transitions for liquid toggle animation.
public enum LiquidTogglePhysics {
    public static let springResponse: Double = 0.35
    public static let springDamping: Double = 0.7
    public static let fastSpringResponse: Double = 0.2
    public static let fastSpringDamping: Double = 0.75
    public static let pressDuration: Double = 0.12
    public static let releaseDelay: Double = 0.04
    public static let tapThreshold: Double = 0.15
    public static let maxDelta: CGFloat = 12
    public static let scaleFactor: CGFloat = 1.65
    public static let deltaScaleFactor: CGFloat = 0.025
}

/// Predefined sizes for the liquid toggle switch.
public enum ToggleSize {
    case small, medium, large

    public var width: CGFloat {
        switch self {
        case .small: return 52
        case .medium: return 140
        case .large: return 180
        }
    }

    public var height: CGFloat {
        switch self {
        case .small: return 28
        case .medium: return 60
        case .large: return 76
        }
    }

    public var borderWidth: CGFloat {
        switch self {
        case .small: return 2.5
        case .medium: return 5.0
        case .large: return 6.5
        }
    }

    public var gooBlur: CGFloat {
        switch self {
        case .small: return 5
        case .medium: return 13
        case .large: return 16
        }
    }

    public var wrapperBlur: CGFloat {
        switch self {
        case .small: return 3
        case .medium: return 6
        case .large: return 8
        }
    }

    public var indicatorRatio: CGFloat { 0.6 }

    public var shadowBlur: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        }
    }
}

#if DEBUG
#Preview("Toggle Sizes") {
    VStack(spacing: 12) {
        Text("Small: \(ToggleSize.small.width)x\(ToggleSize.small.height)")
        Text("Medium: \(ToggleSize.medium.width)x\(ToggleSize.medium.height)")
        Text("Large: \(ToggleSize.large.width)x\(ToggleSize.large.height)")
    }
    .padding(40)
    .background(Color.black)
}
#endif
