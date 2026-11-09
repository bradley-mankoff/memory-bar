import Foundation
import SwiftUI
import MemoryCore

@MainActor
final class MemoryStore: ObservableObject {
    @Published private(set) var snapshot = SampleData.snapshot()
    @Published var searchText = ""
    @Published private(set) var lastUpdated = Date()
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 3

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    var barLabel: String {
        BarLabel.text(used: snapshot.totals.memoryUsed, totalCPUUsed: snapshot.totalCPUUsed)
    }

    var barColor: MemoryColor {
        MemoryColor(forUsedMemory: snapshot.totals.memoryUsed)
    }

    var visibleProcesses: [MemoryProcess] {
        ProcessList.ranked(snapshot.processes, search: searchText)
    }

    /// Refetches the reading that the bar and the popup show. Until the live
    /// readers land this rereads `SampleData`.
    func refresh() {
        snapshot = SampleData.snapshot()
        lastUpdated = Date()
    }
}
