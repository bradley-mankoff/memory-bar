import Foundation

/// The three zones of the Memory Pressure graph.
public enum MemoryPressure: Equatable, Sendable {
    case normal
    case warning
    case critical
}

/// Activity Monitor's Memory tab totals, in bytes. `memoryUsed` is the total
/// shown at the top; `physicalMemory`, `cachedFiles`, `swapUsed`, `appMemory`,
/// `wiredMemory` and `compressed` are the size rows beneath it. On macOS 26
/// those rows do not add up to `memoryUsed`; `LiveTotals` holds the formula the
/// window uses.
public struct MemoryTotals: Equatable, Sendable {
    public var memoryUsed: UInt64
    public var physicalMemory: UInt64
    public var cachedFiles: UInt64
    public var swapUsed: UInt64
    public var appMemory: UInt64
    public var wiredMemory: UInt64
    public var compressed: UInt64
    public var memoryPressure: MemoryPressure

    public init(
        memoryUsed: UInt64,
        physicalMemory: UInt64,
        cachedFiles: UInt64,
        swapUsed: UInt64,
        appMemory: UInt64,
        wiredMemory: UInt64,
        compressed: UInt64,
        memoryPressure: MemoryPressure
    ) {
        self.memoryUsed = memoryUsed
        self.physicalMemory = physicalMemory
        self.cachedFiles = cachedFiles
        self.swapUsed = swapUsed
        self.appMemory = appMemory
        self.wiredMemory = wiredMemory
        self.compressed = compressed
        self.memoryPressure = memoryPressure
    }
}

/// One reading of the Mac: the live Memory tab totals, Total CPU Used as a
/// fraction (still the Spec's sample until memory_bar-13m.4), and the process
/// rows.
public struct MemorySnapshot: Equatable, Sendable {
    public var totals: MemoryTotals
    public var totalCPUUsed: Double
    public var processes: [MemoryProcess]

    public init(totals: MemoryTotals, totalCPUUsed: Double, processes: [MemoryProcess]) {
        self.totals = totals
        self.totalCPUUsed = totalCPUUsed
        self.processes = processes
    }
}
