/**
 OnboardingView.swift

 First-launch tutorial presented as a sheet from ContentView.
 Four steps: Connect USB, Grant Permission, Customize RGB, Create Macro.
 */

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HIDManager.self) private var hidManager

    @State private var currentStep = 0
    @State private var permissionStatus: PermissionStatus = .notDetermined

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 32) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("onboarding.title")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("onboarding.subtitle")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }
                Spacer()
            }

            // Step content
            LiquidGlassCard {
                VStack(spacing: 20) {
                    stepContent
                }
                .frame(maxWidth: .infinity, minHeight: 260)
            }

            // Step indicator + navigation
            HStack {
                // Skip button
                Button("onboarding.skip") {
                    completeOnboarding()
                }
                .buttonStyle(LiquidGlassButtonStyle())
                .opacity(currentStep < totalSteps - 1 ? 1 : 0)

                Spacer()

                // Step dots
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.accentColor : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(Physics.interactive), value: currentStep)
                    }
                }

                Spacer()

                // Continue / Finish button
                Button(currentStep < totalSteps - 1 ? "onboarding.continue" : "onboarding.finish") {
                    if currentStep < totalSteps - 1 {
                        withAnimation(.spring(Physics.navigation)) {
                            currentStep += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
            }
        }
        .padding(32)
        .frame(width: 560, height: 520)
        .task {
            permissionStatus = await PermissionManager.shared.checkInputMonitoring()
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: stepConnect
        case 1: stepPermission
        case 2: stepRGB
        case 3: stepMacro
        default: EmptyView()
        }
    }

    // MARK: - Step 1: Connect USB

    private var stepConnect: some View {
        VStack(spacing: 16) {
            Image(systemName: "cable.connector")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.accentColor)
                .padding(.top, 16)

            Text("onboarding.step1.title")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .vibrantText()

            Text("onboarding.step1.description")
                .font(.system(size: 14, weight: .regular))
                .vibrantText(isSecondary: true)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Step 2: Grant Permission

    private var stepPermission: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(permissionStatus == .granted ? .green : .orange)
                .padding(.top, 16)

            Text("onboarding.step2.title")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .vibrantText()

            Text("onboarding.step2.description")
                .font(.system(size: 14, weight: .regular))
                .vibrantText(isSecondary: true)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if permissionStatus != .granted {
                Button("onboarding.step2.openSettings") {
                    Task {
                        await PermissionManager.shared.openSystemPreferences()
                    }
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: true, tint: .orange))
                .padding(.top, 8)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("onboarding.step2.granted")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Step 3: RGB Lighting

    private var stepRGB: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.purple)
                .padding(.top, 16)

            Text("onboarding.step3.title")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .vibrantText()

            Text("onboarding.step3.description")
                .font(.system(size: 14, weight: .regular))
                .vibrantText(isSecondary: true)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Static preview of RGB controls
            HStack(spacing: 12) {
                PreviewBadge(color: .red, label: "R")
                PreviewBadge(color: .green, label: "G")
                PreviewBadge(color: .blue, label: "B")
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Step 4: Create Macro

    private var stepMacro: some View {
        VStack(spacing: 16) {
            Image(systemName: "record.circle.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.red)
                .padding(.top, 16)

            Text("onboarding.step4.title")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .vibrantText()

            Text("onboarding.step4.description")
                .font(.system(size: 14, weight: .regular))
                .vibrantText(isSecondary: true)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Static preview of macro steps
            HStack(spacing: 8) {
                MacroStepBadge(icon: "arrow.down.circle.fill", label: "Key Down")
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                MacroStepBadge(icon: "clock", label: "50ms")
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                MacroStepBadge(icon: "arrow.up.circle.fill", label: "Key Up")
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

// MARK: - Preview Badges

private struct PreviewBadge: View {
    let color: Color
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.8))
            )
    }
}

private struct MacroStepBadge: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .vibrantText(isSecondary: true)
        }
        .frame(width: 72, height: 52)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

#Preview {
    OnboardingView()
        .environment(HIDManager(mockMode: true))
        .background(Color.black)
}
