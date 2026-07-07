import SwiftUI

struct CapabilityBadge: View {
    let capability: KeyboardCapabilities

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .semibold))
            Text(label)
                .font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(tint.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.25), lineWidth: 0.5)
        )
        .foregroundStyle(tint)
        .help(description)
        .accessibilityLabel("\(label) supported")
    }

    private var iconName: String {
        switch capability {
        case .rgbLighting:      return "lightbulb.fill"
        case .perKeyRGB:        return "square.grid.3x3.fill"
        case .macroProgramming: return "record.circle"
        case .keyRemapping:     return "arrow.left.arrow.right"
        case .mediaKnob:        return "knob"
        case .pollingRateConfig:return "gauge.with.dots.needle.33percent"
        case .onboardMemory:    return "internaldrive"
        case .nKeyRollover:     return "arrow.up.to.line.compact"
        case .wireless:         return "wifi"
        default:                return "questionmark.circle"
        }
    }

    private var label: String {
        switch capability {
        case .rgbLighting:      return String(localized: "capability.rgb")
        case .perKeyRGB:        return String(localized: "capability.perKeyRgb")
        case .macroProgramming: return String(localized: "capability.macros")
        case .keyRemapping:     return String(localized: "capability.remap")
        case .mediaKnob:        return String(localized: "capability.knob")
        case .pollingRateConfig:return String(localized: "capability.polling")
        case .onboardMemory:    return String(localized: "capability.memory")
        case .nKeyRollover:     return String(localized: "capability.nkro")
        case .wireless:         return String(localized: "capability.wireless")
        default:                return String(localized: "capability.unknown")
        }
    }

    private var tint: Color {
        switch capability {
        case .rgbLighting:      return .purple
        case .perKeyRGB:        return .indigo
        case .macroProgramming: return .orange
        case .keyRemapping:     return .cyan
        case .mediaKnob:        return .pink
        case .pollingRateConfig:return .yellow
        case .onboardMemory:    return .green
        case .nKeyRollover:     return .teal
        case .wireless:         return .blue
        default:                return .gray
        }
    }

    private var description: String {
        switch capability {
        case .rgbLighting:      return String(localized: "capability.rgb.description")
        case .perKeyRGB:        return String(localized: "capability.perKeyRgb.description")
        case .macroProgramming: return String(localized: "capability.macros.description")
        case .keyRemapping:     return String(localized: "capability.remap.description")
        case .mediaKnob:        return String(localized: "capability.knob.description")
        case .pollingRateConfig:return String(localized: "capability.polling.description")
        case .onboardMemory:    return String(localized: "capability.memory.description")
        case .nKeyRollover:     return String(localized: "capability.nkro.description")
        case .wireless:         return String(localized: "capability.wireless.description")
        default:                return String(localized: "capability.unknown.description")
        }
    }
}
