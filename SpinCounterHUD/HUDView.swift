import SwiftUI

struct HUDView: View {
    @ObservedObject var state: TrackerState
    @State private var offset: CGSize = .zero
    @State private var dragStartOffset: CGSize = .zero
    @State private var showTargetEditor: Bool = false
    @State private var targetInput: String = ""

    private let rowColors: [Color] = [
        .white,
        Color(red: 0.25, green: 0.90, blue: 0.95),
        Color(red: 0.95, green: 0.35, blue: 0.35),
        Color(red: 0.98, green: 0.85, blue: 0.20)
    ]

    var body: some View {
        VStack(spacing: 8) {
            if !state.isCollapsed {
                topPanel
            }
            bottomBar
        }
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(
                        width: dragStartOffset.width + value.translation.width,
                        height: dragStartOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    dragStartOffset = offset
                }
        )
        .alert("Target Spin", isPresented: $showTargetEditor) {
            TextField("Target", text: $targetInput)
                .keyboardType(.numberPad)
            Button("OK") {
                if let val = Int(targetInput) {
                    state.targetSpin = val
                    state.save()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var topPanel: some View {
        VStack(spacing: 8) {
            // Top bar: Trash, ON/OFF, Close/Collapse
            HStack {
                Button {
                    state.clearHistory()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 30)
                }

                Spacer()

                Button {
                    state.isEnabled.toggle()
                } label: {
                    Text(state.isEnabled ? "ON" : "OFF")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 6)
                        .background(state.isEnabled ? Color.green.opacity(0.65) : Color.red.opacity(0.55))
                        .clipShape(Capsule())
                }

                Spacer()

                Button {
                    state.isCollapsed = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 36, height: 30)
                }
            }

            // 6 symbol columns + yellow counters (tap column to record hit)
            HStack(spacing: 6) {
                ForEach(state.slots) { slot in
                    Button {
                        state.recordHit(columnIndex: slot.id)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: slot.systemIcon)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                            Text("\(slot.currentCount)")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundColor(.yellow)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            Divider().background(Color.white.opacity(0.25))

            // Recent interval rows
            VStack(spacing: 6) {
                ForEach(state.history.prefix(3)) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<6, id: \.self) { col in
                            if col < row.values.count {
                                Text("\(row.values[col])")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(rowColors[col])
                                    .frame(maxWidth: .infinity)
                            } else {
                                Color.clear.frame(maxWidth: .infinity, maxHeight: 16)
                            }
                        }
                    }
                    if row.id != state.history.prefix(3).last?.id {
                        Divider().background(Color.white.opacity(0.15))
                    }
                }
            }
        }
        .padding(10)
        .frame(width: 290)
        .background(Color.black.opacity(0.65))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            Button {
                state.skipStep()
            } label: {
                Text("SKIP")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 58, height: 38)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Current spin counter (tap to +1)
            Button {
                state.stepSpin()
            } label: {
                Text("\(state.currentSpin)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 38)
                    .background(Color.blue.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Target spin (tap to edit)
            Button {
                targetInput = "\(state.targetSpin)"
                showTargetEditor = true
            } label: {
                Text("\(state.targetSpin)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 38)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Network marker / expand toggle
            Button {
                state.isNetworkMarked.toggle()
                if state.isCollapsed {
                    state.isCollapsed = false
                }
            } label: {
                Image(systemName: state.isNetworkMarked ? "wifi.slash" : "wifi")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(state.isNetworkMarked ? .orange : .cyan)
                    .frame(width: 52, height: 38)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Pause / Resume
            Button {
                state.isPaused.toggle()
            } label: {
                Image(systemName: state.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(state.isPaused ? .yellow : .cyan)
                    .frame(width: 52, height: 38)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(red: 0.16, green: 0.17, blue: 0.30).opacity(0.92))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}
