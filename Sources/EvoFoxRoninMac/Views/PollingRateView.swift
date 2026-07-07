import SwiftUI

struct PollingRateView: View {
    @Binding var pollingRate: KeyboardProfile.PollingRate
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("polling.title")
                .font(.headline)

            Picker("polling.rate", selection: $pollingRate) {
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

extension KeyboardProfile.PollingRate {
    var pollingDescription: String {
        switch self {
        case .hz125: return String(localized: "polling.hz125")
        case .hz250: return String(localized: "polling.hz250")
        case .hz500: return String(localized: "polling.hz500")
        case .hz1000: return String(localized: "polling.hz1000")
        }
    }
}
