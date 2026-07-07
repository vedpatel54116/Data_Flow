/**
 MacroEditorView.swift

 Macro programming interface for the EvoFox Ronin keyboard.

 Allows users to record, edit, and assign macros to keys. Macros are stored
 in the keyboard's on-board memory and can be triggered by any key.

 Features:
 - Record from keyboard input
 - Manual macro event editing
 - Delay and timing control
 - Repeat settings
 - Assign to key

 Uses LiquidGlassCard for panels, spring physics for list animations.
 */

import SwiftUI

struct MacroEditorView: View {
    @Environment(HIDManager.self) private var hidManager
    @Environment(ProfileManager.self) private var profileManager

    @State private var macros: [KeyboardMacro] = []
    @State private var selectedMacro: KeyboardMacro?
    @State private var showEditor = false
    @State private var isRecording = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Macro Programming")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .vibrantText()

                    Text("Record and assign macros to any key")
                        .font(.system(size: 14, weight: .regular))
                        .vibrantText(isSecondary: true)
                }

                Spacer()

                Button("New Macro") {
                    createNewMacro()
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: true, tint: .green))
            }

            // Macro list
            if macros.isEmpty {
                LiquidGlassCard {
                    VStack(spacing: 16) {
                        Image(systemName: "record.circle")
                            .font(.system(size: 48))
                            .vibrantText(isSecondary: true)

                        Text("No macros yet")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .vibrantText()

                        Text("Create a new macro to get started with automation")
                            .font(.system(size: 14, weight: .regular))
                            .vibrantText(isSecondary: true)
                            .multilineTextAlignment(.center)

                        Button("Create First Macro") {
                            createNewMacro()
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .padding(.top, 8)
                    }
                    .padding(40)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(macros) { macro in
                        MacroCard(
                            macro: macro,
                            isSelected: selectedMacro?.id == macro.id
                        ) {
                            withAnimation(.spring(Physics.interactive)) {
                                selectedMacro = macro
                                showEditor = true
                            }
                        }
                        .contentAnimation(value: macros.count)
                    }
                }
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: 800)
        .sheet(isPresented: $showEditor) {
            if let macro = selectedMacro {
                MacroDetailSheet(macro: macro) { updatedMacro in
                    updateMacro(updatedMacro)
                }
            }
        }
        .onAppear {
            if let profile = profileManager.activeProfile {
                macros = profile.macros
            }
        }
    }

    private func createNewMacro() {
        let macro = KeyboardMacro(
            name: "Macro \(macros.count + 1)",
            events: []
        )
        macros.append(macro)
        selectedMacro = macro
        showEditor = true
    }

    private func updateMacro(_ macro: KeyboardMacro) {
        if let index = macros.firstIndex(where: { $0.id == macro.id }) {
            macros[index] = macro
        }
        if var profile = profileManager.activeProfile {
            profile.macros = macros
            profileManager.updateProfile(profile)
        }
    }
}

// MARK: - Macro Card

struct MacroCard: View {
    let macro: KeyboardMacro
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green.opacity(0.3) : Color.white.opacity(0.08))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? Color.green.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)

                    Image(systemName: "record.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .vibrantText(isSecondary: !isSelected)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(macro.name)
                        .font(.system(size: 15, weight: .semibold))
                        .vibrantText(isSecondary: !isSelected)

                    Text("\(macro.events.count) events • \(macro.totalDurationMs)ms")
                        .font(.system(size: 12, weight: .regular))
                        .vibrantText(isSecondary: true)
                }

                Spacer()

                if macro.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .shadow(color: Color.green.opacity(0.6), radius: 4, x: 0, y: 0)
                        Text("Active")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                    )
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .vibrantText(isSecondary: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
                    .shadow(color: isSelected ? Color.green.opacity(0.2) : .clear, radius: 12, x: 0, y: 6)
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

// MARK: - Macro Detail Sheet

struct MacroDetailSheet: View {
    let macro: KeyboardMacro
    let onSave: (KeyboardMacro) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var events: [KeyboardMacro.MacroEvent]
    @State private var isRecording = false
    @State private var repeatCount: Double
    @State private var isActive: Bool
    @State private var eventMonitor: Any?
    @State private var recordingStartTime: Date?

    init(macro: KeyboardMacro, onSave: @escaping (KeyboardMacro) -> Void) {
        self.macro = macro
        self.onSave = onSave
        _name = State(initialValue: macro.name)
        _events = State(initialValue: macro.events)
        _repeatCount = State(initialValue: Double(macro.repeatCount))
        _isActive = State(initialValue: macro.isActive)
    }

    var body: some View {
        LiquidGlassCard {
            VStack(spacing: 20) {
                HStack {
                    Text("Edit Macro")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .vibrantText()

                    Spacer()

                    Button("Cancel") {
                        stopRecording()
                        dismiss()
                    }
                    .buttonStyle(LiquidGlassButtonStyle())

                    Button("Save") {
                        stopRecording()
                        saveMacro()
                    }
                    .buttonStyle(LiquidGlassButtonStyle(isProminent: true, tint: .green))
                }

                HStack {
                    Text("Name:")
                        .font(.system(size: 13, weight: .medium))
                        .vibrantText(isSecondary: true)
                        .frame(width: 60, alignment: .leading)

                    TextField("Macro name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                }

                HStack {
                    Button(isRecording ? "Stop Recording" : "Record") {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                        isRecording.toggle()
                    }
                    .buttonStyle(LiquidGlassButtonStyle(isProminent: isRecording, tint: isRecording ? .red : .blue))
                    .shadow(color: isRecording ? Color.red.opacity(0.4) : .clear, radius: isRecording ? 12 : 0, x: 0, y: 4)

                    Button("Clear") {
                        events.removeAll()
                    }
                    .buttonStyle(LiquidGlassButtonStyle())

                    Spacer()

                    HStack(spacing: 8) {
                        if isRecording {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.red.opacity(0.6), radius: 4, x: 0, y: 0)
                                .opacity(isRecording ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                        }
                        Text(isRecording ? "Press keys on your keyboard..." : "Click Record to capture keystrokes")
                            .font(.system(size: 12, weight: .regular))
                            .vibrantText(isSecondary: true)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Events (\(events.count))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .vibrantText()

                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                                EventRow(index: index, event: event)
                                    .contentAnimation(value: events.count)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Repeat: \(Int(repeatCount))x")
                            .font(.system(size: 12, weight: .medium))
                            .vibrantText(isSecondary: true)

                        Slider(value: $repeatCount, in: 1...10, step: 1)
                            .tint(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 12) {
                        LiquidToggle(isOn: $isActive, tintColor: .green, size: .small)
                        Text("Active")
                            .font(.system(size: 13, weight: .medium))
                            .vibrantText(isSecondary: true)
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 560, height: 520)
        .padding(40)
    }

    private func startRecording() {
        recordingStartTime = Date()
        events.removeAll()

        let monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in

            let start = recordingStartTime ?? Date()
            let elapsed = UInt16(min(Date().timeIntervalSince(start) * 1000, 65535))
            recordingStartTime = Date()

            if let scanCode = KeyCodeMapper.scanCode(for: event.keyCode) {
                let macroEvent = KeyboardMacro.MacroEvent(
                    type: .keyDown,
                    keyCode: UInt16(scanCode),
                    delayMs: events.isEmpty ? 0 : elapsed
                )
                DispatchQueue.main.async {
                    events.append(macroEvent)
                }
            }

            return event
        }
        eventMonitor = monitor
    }

    private func stopRecording() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        eventMonitor = nil
        recordingStartTime = nil
    }

    private func saveMacro() {
        var updated = macro
        updated.name = name
        updated.events = events
        updated.repeatCount = UInt8(repeatCount)
        updated.isActive = isActive
        onSave(updated)
        dismiss()
    }
}

// MARK: - Event Row

struct EventRow: View {
    let index: Int
    let event: KeyboardMacro.MacroEvent

    var body: some View {
        HStack {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .vibrantText(isSecondary: true)
                .frame(width: 28, alignment: .leading)

            Text(event.type.rawValue)
                .font(.system(size: 12, weight: .medium))
                .vibrantText()
                .frame(width: 80, alignment: .leading)

            if let keyCode = event.keyCode {
                Text("Key: \(KeyCodeLibrary.name(for: keyCode)) (\(keyCode))")
                    .font(.system(size: 12, weight: .regular))
                    .vibrantText(isSecondary: true)
            }

            if event.delayMs > 0 {
                Text("+\(event.delayMs)ms")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .vibrantText(isSecondary: true)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    MacroEditorView()
        .environment(HIDManager(mockMode: true))
        .environment(ProfileManager())
        .frame(width: 800, height: 700)
        .background(Color.black)
}
