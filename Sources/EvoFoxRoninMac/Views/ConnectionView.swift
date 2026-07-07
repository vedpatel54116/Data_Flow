/**
 ConnectionView.swift

 Device connection status panel with liquid glassmorphism styling.
 Shows connection state, discovered HID devices, and diagnostics.
 */

import SwiftUI
import ApplicationServices
import AppKit

struct ConnectionView: View {
    @Environment(HIDManager.self) private var hidManager

    @State private var showDetails = false
    @State private var showDiscoveredDevices = false
    @State private var showDiagnostics = false
    @State private var showPermissionAlert = false

    var body: some View {
        VStack(spacing: 24) {
            // Status card
            LiquidGlassCard {
                VStack(spacing: 20) {
                    HStack {
                        statusIcon

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connection Status")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .vibrantText()

                            Text(statusDescription)
                                .font(.system(size: 14, weight: .regular))
                                .vibrantText(isSecondary: true)
                        }

                        Spacer()

                        connectionActionButton
                    }

                    if showDetails, let details = deviceDetails {
                        Divider()
                            .background(Color.white.opacity(0.1))

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(details, id: \.self) { detail in
                                HStack {
                                    Text(detail)
                                        .font(.system(size: 13, weight: .regular))
                                        .vibrantText(isSecondary: true)
                                    Spacer()
                                }
                                .contentAnimation(value: showDetails)
                            }
                        }
                        .padding(.top, 8)
                    }

                    Button(showDetails ? "Hide Details" : "Show Details") {
                        withAnimation(.spring(Physics.morph)) {
                            showDetails.toggle()
                        }
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Permission warning banner
                    if case .error(.permissionDenied) = hidManager.connectionState {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.orange)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Input Monitoring permission not granted")
                                    .font(.system(size: 13, weight: .semibold))
                                    .vibrantText()

                                Text("Go to System Settings > Privacy & Security > Input Monitoring and enable EvoFoxRoninMac")
                                    .font(.system(size: 11, weight: .regular))
                                    .vibrantText(isSecondary: true)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Button("Open Settings") {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(LiquidGlassButtonStyle(isProminent: true, tint: .orange))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.orange.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                }
            }

            // Discovered Devices (only visible after scanning)
            if !hidManager.discoveredDevices.isEmpty {
                LiquidGlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Discovered HID Devices (\(hidManager.discoveredDevices.count))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .vibrantText()

                            Spacer()

                            Button(showDiscoveredDevices ? "Hide" : "Show") {
                                withAnimation(.spring(Physics.morph)) {
                                    showDiscoveredDevices.toggle()
                                }
                            }
                            .buttonStyle(LiquidGlassButtonStyle())
                        }

                        if showDiscoveredDevices {
                            VStack(spacing: 8) {
                                ForEach(hidManager.discoveredDevices) { device in
                                    DeviceInfoRow(device: device)
                                        .contentAnimation(value: hidManager.discoveredDevices.count)
                                }
                            }
                        }

                        Text("Look for a device with ★ — that's a candidate match. If your keyboard isn't listed, it may need a different USB cable or port.")
                            .font(.system(size: 11, weight: .regular))
                            .vibrantText(isSecondary: true)
                            .padding(.top, 8)
                    }
                }
            }

            // Quick Actions
            HStack(spacing: 16) {
                QuickActionCard(
                    icon: "arrow.clockwise",
                    title: "Reconnect",
                    description: "Force keyboard reconnection"
                ) {
                    hidManager.disconnect()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        hidManager.connect()
                    }
                }

                QuickActionCard(
                    icon: "eye.fill",
                    title: "Mock Mode",
                    description: "Test without hardware"
                ) {
                    hidManager.enableMockMode()
                }
            }

            // Diagnostics Report
            LiquidGlassCard(material: .floating) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Diagnostics")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .vibrantText()

                        Spacer()

                        Button(showDiagnostics ? "Hide" : "Show Full Report") {
                            withAnimation(.spring(Physics.morph)) {
                                showDiagnostics.toggle()
                            }
                        }
                        .buttonStyle(LiquidGlassButtonStyle())
                    }

                    if showDiagnostics {
                        ScrollView(.vertical, showsIndicators: true) {
                            Text(hidManager.diagnosticsReport())
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .vibrantText(isSecondary: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 300)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.black.opacity(0.3))
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        TroubleshootingRow(
                            step: "1",
                            text: "Ensure keyboard is connected via USB-C cable (not wireless)"
                        )
                        TroubleshootingRow(
                            step: "2",
                            text: "Grant 'Input Monitoring' permission in System Settings > Privacy & Security"
                        )
                        TroubleshootingRow(
                            step: "3",
                            text: "Check 'Discovered HID Devices' above — look for your keyboard's name, VID, and PID"
                        )
                        TroubleshootingRow(
                            step: "4",
                            text: "If your keyboard shows up but isn't connected, note its VID/PID and report it"
                        )
                        TroubleshootingRow(
                            step: "5",
                            text: "Enable Mock Mode to test all app features without a physical keyboard"
                        )
                    }
                }
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: 720)
        .alert("Input Monitoring Permission Required", isPresented: $showPermissionAlert) {
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("EvoFox Ronin needs Input Monitoring permission to communicate with your keyboard.\n\nGo to System Settings > Privacy & Security > Input Monitoring, then enable EvoFoxRoninMac.\n\nYou may need to restart the app after granting permission.")
        }
        .onChange(of: hidManager.connectionState) { _, newState in
            if case .error(.permissionDenied) = newState {
                showPermissionAlert = true
            }
        }
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            // Glow layer behind the icon
            Circle()
                .fill(statusColor.opacity(0.3))
                .frame(width: 56, height: 56)
                .blur(radius: 12)
                .opacity(statusColor == .green ? 0.8 : 0.5)

            Circle()
                .fill(statusColor.opacity(0.2))
                .frame(width: 56, height: 56)

            Circle()
                .stroke(statusColor.opacity(0.4), lineWidth: 1)
                .frame(width: 56, height: 56)

            Image(systemName: statusIconName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(statusColor)
                .shadow(color: statusColor.opacity(0.6), radius: 6, x: 0, y: 0)
        }
    }

    // MARK: - Connection Action Button

    @ViewBuilder
    private var connectionActionButton: some View {
        switch hidManager.connectionState {
        case .disconnected, .error:
            Button("Connect") {
                hidManager.connect()
            }
            .buttonStyle(LiquidGlassButtonStyle(isProminent: true, tint: .green))

        case .scanning, .connecting:
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))

        case .connected:
            Button("Disconnect") {
                hidManager.disconnect()
            }
            .buttonStyle(LiquidGlassButtonStyle(tint: .red))
        }
    }

    // MARK: - Status Helpers

    private var statusColor: Color {
        switch hidManager.connectionState {
        case .connected: return .green
        case .connecting, .scanning: return .yellow
        case .disconnected: return .red
        case .error: return .orange
        }
    }

    private var statusIconName: String {
        switch hidManager.connectionState {
        case .connected: return "checkmark.circle.fill"
        case .connecting, .scanning: return "ellipsis.circle.fill"
        case .disconnected: return "xmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var statusDescription: String {
        switch hidManager.connectionState {
        case .connected(let name):
            return "Connected to \(name)"
        case .connecting:
            return "Establishing connection..."
        case .scanning:
            return "Scanning for keyboard..."
        case .disconnected:
            return "Keyboard not connected"
        case .error(let error):
            return error.description
        }
    }

    private var deviceDetails: [String]? {
        switch hidManager.connectionState {
        case .connected(let name):
            return [
                "Device: \(name)",
                "Model: EvoFox Ronin TKL",
                "Layout: 79-Key Tenkeyless",
                "Switches: Outemu Red Silent",
                "Connection: USB-C Wired",
                "Polling Rate: 1000Hz"
            ]
        default:
            return nil
        }
    }
}

// MARK: - Device Info Row

struct DeviceInfoRow: View {
    let device: HIDDeviceInfo

    var isMatch: Bool {
        let lowerName = device.name.lowercased()
        let nameKeywords = ["evofox", "ronin", "amkette", "gaming", "mechanical"]
        let knownVendors = [0x258A, 0x0483, 0x0C45, 0x04D9, 0x1532, 0x2516, 0x25A7]

        if nameKeywords.contains(where: { lowerName.contains($0) }) { return true }
        if knownVendors.contains(device.vendorID) { return true }
        if device.usagePage >= 0xFF00 { return true }
        return false
    }

    var body: some View {
        HStack(spacing: 12) {
            if isMatch {
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.yellow)
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 6))
                    .vibrantText(isSecondary: true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 12, weight: isMatch ? .semibold : .medium))
                    .vibrantText(isSecondary: !isMatch)

                Text("VID 0x\(String(format: "%04X", device.vendorID)) · PID 0x\(String(format: "%04X", device.productID)) · UsagePage 0x\(String(format: "%04X", device.usagePage))")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .vibrantText(isSecondary: true)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isMatch ? Color.yellow.opacity(0.08) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isMatch ? Color.yellow.opacity(0.15) : Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .vibrantText()

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .vibrantText()

                    Text(description)
                        .font(.system(size: 12, weight: .regular))
                        .vibrantText(isSecondary: true)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(
                LiquidGlassContainer(material: .floating, cornerRadius: 16, padding: 0) {
                    Color.clear
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .glassFocus(isFocused: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(Physics.interactive)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Troubleshooting Row

struct TroubleshootingRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )

            Text(text)
                .font(.system(size: 13, weight: .regular))
                .vibrantText(isSecondary: true)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

#Preview {
    ConnectionView()
        .environment(HIDManager(mockMode: true))
        .frame(width: 700, height: 600)
        .background(Color.black)
}
