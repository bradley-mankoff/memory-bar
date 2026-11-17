import Foundation
import SwiftUI
import MemoryCore

@MainActor
final class MemoryStore: ObservableObject {
    @Published private(set) var snapshot = MemorySnapshot(
        totals: LiveTotals.read(),
        totalCPUUsed: 0,
        processes: []
    )
    @Published var searchText = ""
    @Published private(set) var lastUpdated = Date()
    /// True once the first live reading has replaced the empty sample rows.
    @Published private(set) var hasReadProcesses = false
    @Published private(set) var sizesAreApproximate = false

    private var timer: Timer?
    private let refreshInterval: TimeInterval = 3
    private var cpuSampler = CPUUsageSampler()
    private var topCache = TopFootprintCache()
    private var isRefreshInFlight = false
    /// The rolling day of memory use, loaded so the window outlives a restart.
    private var memoryUseRecord = MemoryUseRecordFile.load(from: MemoryUseRecordFile.defaultURL)

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    var barLabel: String {
        BarLabel.text(used: snapshot.totals.memoryUsed, totalCPUUsed: snapshot.totalCPUUsed)
    }

    var barColor: MemoryColor {
        MemoryColor(
            forUsedMemory: snapshot.totals.memoryUsed,
            physicalMemory: snapshot.totals.physicalMemory
        )
    }

    /// The ranked rows narrowed by the Search field. The rows arrive already
    /// largest first, so a keystroke only filters them and never re-sorts.
    var visibleProcesses: [MemoryProcess] {
        ProcessList.filtered(snapshot.processes, search: searchText)
    }

    /// Replaces the process rows with a live reading and the totals and Total
    /// CPU Used with the counters read now. The process read runs off the main
    /// thread because a fresh `top` sample costs about half a second, while the
    /// popup refreshes every three seconds; the totals and CPU ticks are cheap
    /// enough to read on the spot. Refresh calls this directly, so the button
    /// refetches without waiting for the timer.
    func refresh(forceTopSample: Bool = false) {
        snapshot.totals = LiveTotals.read()
        if let ticks = LiveCPU.read() {
            snapshot.totalCPUUsed = cpuSampler.sample(ticks)
        }
        guard !isRefreshInFlight else { return }
        isRefreshInFlight = true
        let now = Date()
        let cached = topCache
        let force = forceTopSample
        Task { @MainActor in
            let reading = await Self.read(cache: cached, at: now, force: force)
            self.topCache = reading.cache
            self.snapshot.processes = reading.rows
            self.sizesAreApproximate = reading.top.isApproximate
            self.hasReadProcesses = true
            self.lastUpdated = Date()
            self.isRefreshInFlight = false
            self.recordMemoryUse(at: now)
        }
    }

    /// Stores one sample of the totals and the top processes when the record is
    /// due, which its one-a-minute interval decides. The sample reuses the rows
    /// this refresh already read, so recording adds no subprocess and no second
    /// process-table read; only the once-a-minute whole-file write leaves the
    /// main thread.
    private func recordMemoryUse(at time: Date) {
        guard memoryUseRecord.record(
            at: time,
            totals: snapshot.totals,
            processes: snapshot.processes
        ) else { return }
        let record = memoryUseRecord
        let url = MemoryUseRecordFile.defaultURL
        Task.detached(priority: .utility) {
            try? MemoryUseRecordFile.save(record, to: url)
        }
    }

    /// Reads the process table on a background thread. Only Sendable values
    /// cross the boundary, so no view state is touched off the main actor.
    nonisolated private static func read(
        cache: TopFootprintCache,
        at now: Date,
        force: Bool
    ) async -> (cache: TopFootprintCache, top: TopMemorySample, rows: [MemoryProcess]) {
        await Task.detached(priority: .utility) {
            var cache = cache
            let top = cache.sample(at: now, force: force) { LiveProcesses.topSample() }
            let rows = ProcessList.rows(from: LiveProcesses.readings(topSample: top))
            return (cache, top, rows)
        }.value
    }
}
