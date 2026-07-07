import SwiftUI

struct PollingRateView: View {
    @Binding var pollingRate: KeyboardProfile.PollingRate
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Polling Rate")
                .font(.headline)

            Picker("Rate", selection: $pollingRate) {
                ForEach(KeyboardProfile.PollingRate.allCases, id: \.self) { rate in
                    Text(rate.displayName).tag(rate)
                }
            }
            .pickerStyle(.radioGroup)

            Text(pollingRate.pollingDescription)
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

extension KeyboardProfile.PollingRate {
    var pollingDescription: String {
        switch self {
        case .hz125: return "125 Hz (8ms) — Lower CPU usage"
        case .hz250: return "250 Hz (4ms)"
        case .hz500: return "500 Hz (2ms)"
        case .hz1000: return "1000 Hz (1ms) — Fastest, default"
        }
    }
}
