import Foundation
import SwiftUI

struct SymbolSlot: Identifiable, Codable {
    let id: Int
    let systemIcon: String
    let label: String
    let iconColorHex: String
    var currentCount: Int
}

struct IntervalRow: Identifiable, Codable {
    let id: UUID
    var values: [Int] // Up to 4 tracked columns (white, cyan, red, yellow)

    init(values: [Int]) {
        self.id = UUID()
        self.values = values
    }
}

@MainActor
final class TrackerState: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var isPaused: Bool = false
    @Published var isCollapsed: Bool = false
    @Published var isNetworkMarked: Bool = false

    @Published var currentSpin: Int = 7
    @Published var targetSpin: Int = 79

    @Published var slots: [SymbolSlot] = [
        SymbolSlot(id: 0, systemIcon: "star.circle.fill", label: "Event", iconColorHex: "F5C542", currentCount: 88),
        SymbolSlot(id: 1, systemIcon: "hammer.fill", label: "Attack", iconColorHex: "FF5252", currentCount: 13),
        SymbolSlot(id: 2, systemIcon: "theatermasks.fill", label: "Raid", iconColorHex: "FF7EB6", currentCount: 0),
        SymbolSlot(id: 3, systemIcon: "capsule.fill", label: "Energy", iconColorHex: "4FD1FF", currentCount: 6),
        SymbolSlot(id: 4, systemIcon: "flask.fill", label: "Potion", iconColorHex: "9D6BFF", currentCount: 260),
        SymbolSlot(id: 5, systemIcon: "bolt.circle.fill", label: "Spin", iconColorHex: "FFD43B", currentCount: 260)
    ]

    @Published var history: [IntervalRow] = [
        IntervalRow(values: [86, 6, 14, 124]),
        IntervalRow(values: [80, 24, 12, 80]),
        IntervalRow(values: [6, 27, 99, 7])
    ]

    private let storageKey = "spin_counter_hud_state_v1"

    init() {
        load()
    }

    func stepSpin() {
        guard isEnabled, !isPaused else { return }
        currentSpin += 1
        for i in slots.indices {
            if slots[i].currentCount > 0 {
                slots[i].currentCount -= 1
            }
        }
        save()
    }

    func skipStep() {
        guard isEnabled else { return }
        currentSpin += 1
        save()
    }

    func recordHit(columnIndex: Int) {
        guard isEnabled, columnIndex >= 0, columnIndex < slots.count else { return }
        if columnIndex < 4 {
            var latest = history.first?.values ?? [0, 0, 0, 0]
            while latest.count < 4 { latest.append(0) }
            latest[columnIndex] = currentSpin
            history.insert(IntervalRow(values: latest), at: 0)
            if history.count > 20 {
                history.removeLast(history.count - 20)
            }
        }
        slots[columnIndex].currentCount = currentSpin
        currentSpin = 0
        save()
    }

    func clearHistory() {
        history.removeAll()
        currentSpin = 0
        for i in slots.indices {
            slots[i].currentCount = 0
        }
        save()
    }

    func save() {
        let snapshot = PersistedSnapshot(
            currentSpin: currentSpin,
            targetSpin: targetSpin,
            slots: slots,
            history: history
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(PersistedSnapshot.self, from: data) else {
            return
        }
        currentSpin = snapshot.currentSpin
        targetSpin = snapshot.targetSpin
        slots = snapshot.slots
        history = snapshot.history
    }
}

private struct PersistedSnapshot: Codable {
    let currentSpin: Int
    let targetSpin: Int
    let slots: [SymbolSlot]
    let history: [IntervalRow]
}
