import SwiftUI

struct KnobSettingsView: View {
    @Binding var knobBehavior: KeyboardProfile.KnobBehavior
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Volume Knob Behavior")
                .font(.headline)

            Picker("Behavior", selection: $knobBehavior) {
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
                Button("Cancel") { dismiss() }
                Button("Save") { dismiss() }
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
        case .volumeControl: return "Volume Control"
        case .brightnessControl: return "Brightness"
        case .scrollControl: return "Scroll"
        case .zoomControl: return "Zoom"
        case .custom: return "Custom Action"
        }
    }

    var description: String {
        switch self {
        case .volumeControl: return "Rotate to adjust system volume"
        case .brightnessControl: return "Rotate to adjust display brightness"
        case .scrollControl: return "Rotate to scroll up/down"
        case .zoomControl: return "Rotate to zoom in/out"
        case .custom: return "Assign a custom action via macro editor"
        }
    }
}
