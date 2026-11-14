import SwiftUI

struct HUDView: View {
    @ObservedObject var state: TrackerState
    @State private var offset: CGSize = .zero
    @State private var dragStartOffset: CGSize = .zero
    @State private var panelWidth: CGFloat = 292
    @State private var dragStartWidth: CGFloat = 292
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
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 8) {
                // Top bar: Trash on left, ON pill + X on right
                HStack(spacing: 10) {
                    Button {
                        state.clearHistory()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 19, weight: .regular))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 30)
                    }

                    Spacer()

                    Button {
                        state.isEnabled.toggle()
                    } label: {
                        Text(state.isEnabled ? "ON" : "OFF")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 68, height: 30)
                            .background(
                                state.isEnabled
                                    ? Color(red: 0.29, green: 0.50, blue: 0.43).opacity(0.85)
                                    : Color(red: 0.60, green: 0.22, blue: 0.22).opacity(0.85)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    }

                    Button {
                        state.isCollapsed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 34, height: 30)
                    }
                }

                // 6 symbol columns + yellow counters with subtle vertical dividers
                HStack(spacing: 0) {
                    ForEach(state.slots) { slot in
                        Button {
                            state.recordHit(columnIndex: slot.id)
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: slot.systemIcon)
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: slot.iconColorHex))
                                Text("\(slot.currentCount)")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundColor(Color(red: 0.98, green: 0.88, blue: 0.22))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        if slot.id < state.slots.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 1, height: 36)
                        }
                    }
                }

                // Recent interval rows
                VStack(spacing: 7) {
                    ForEach(state.history.prefix(3)) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<6, id: \.self) { col in
                                if col < row.values.count {
                                    Text("\(row.values[col])")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(rowColors[col])
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Color.clear.frame(maxWidth: .infinity, maxHeight: 16)
                                }
                            }
                        }
                        if row.id != state.history.prefix(3).last?.id {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            .padding(10)

            // Bottom-right resize triangle
            ResizeTriangle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 12, height: 12)
                .padding(6)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            panelWidth = min(max(250, dragStartWidth + value.translation.width), 380)
                        }
                        .onEnded { _ in
                            dragStartWidth = panelWidth
                        }
                )
        }
        .frame(width: panelWidth)
        .background(Color.black.opacity(0.62))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            Button {
                state.skipStep()
            } label: {
                Text("SKIP")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(width: 58, height: 40)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.20), lineWidth: 1)
                    )
            }

            Button {
                state.stepSpin()
            } label: {
                Text("\(state.currentSpin)")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 66, height: 40)
                    .background(Color(red: 0.16, green: 0.58, blue: 1.0))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                targetInput = "\(state.targetSpin)"
                showTargetEditor = true
            } label: {
                Text("\(state.targetSpin)")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 66, height: 40)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            }

            Button {
                state.isNetworkMarked.toggle()
                if state.isCollapsed {
                    state.isCollapsed = false
                }
            } label: {
                Image(systemName: state.isNetworkMarked ? "wifi.slash" : "wifi")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(state.isNetworkMarked ? .orange : Color(red: 0.10, green: 0.90, blue: 0.98))
                    .frame(width: 54, height: 40)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            }

            Button {
                state.isPaused.toggle()
            } label: {
                Image(systemName: state.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(state.isPaused ? .yellow : Color(red: 0.10, green: 0.90, blue: 0.98))
                    .frame(width: 54, height: 40)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(red: 0.22, green: 0.24, blue: 0.42).opacity(0.92))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.white.opacity(0.45), lineWidth: 1.2)
        )
    }
}

private struct ResizeTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
