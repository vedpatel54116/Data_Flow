import SwiftUI

struct KnobSettingsView: View {
    @Binding var knobBehavior: KeyboardProfile.KnobBehavior
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("knob.title")
                .font(.headline)

            Picker("knob.behavior", selection: $knobBehavior) {
                ForEach(KeyboardProfile.KnobBehavior.allCases, id: \.self) { behavior in
                    HStack {
                        Image(systemName: behavior.iconName)
                        Text(behavior.displayName)
                    }
                    .tag(behavior)
                }
            }
            .pickerStyle(.radioGroup)

            Text(knobBehavior.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button("general.cancel") { dismiss() }
                Button("general.save") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 320)
    }
}

extension KeyboardProfile.KnobBehavior {
    var iconName: String {
        switch self {
        case .volumeControl: return "speaker.wave.2"
        case .brightnessControl: return "sun.max"
        case .scrollControl: return "arrow.up.arrow.down"
        case .zoomControl: return "magnifyingglass"
        case .custom: return "gearshape"
        }
    }

    var displayName: String {
        switch self {
        case .volumeControl: return String(localized: "knob.volume")
        case .brightnessControl: return String(localized: "knob.brightness")
        case .scrollControl: return String(localized: "knob.scroll")
        case .zoomControl: return String(localized: "knob.zoom")
        case .custom: return String(localized: "knob.custom")
        }
    }

    var description: String {
        switch self {
        case .volumeControl: return String(localized: "knob.volume.description")
        case .brightnessControl: return String(localized: "knob.brightness.description")
        case .scrollControl: return String(localized: "knob.scroll.description")
        case .zoomControl: return String(localized: "knob.zoom.description")
        case .custom: return String(localized: "knob.custom.description")
        }
    }
}
