/// Fixed sample readings for the parts of the popup whose live sources have
/// not landed yet: the Activity Monitor totals on the 64GB Mac, 47GB Memory
/// Used (30 App + 8 Wired + 9 Compressed) and 46 percent Total CPU Used. The
/// process rows are live, so this sample has none.
public enum SampleData {
    public static func snapshot() -> MemorySnapshot {
        MemorySnapshot(
            totals: MemoryTotals(
                memoryUsed: 47 * MemoryBytes.gigabyte,
                physicalMemory: 64 * MemoryBytes.gigabyte,
                cachedFiles: 10 * MemoryBytes.gigabyte,
                swapUsed: 0,
                appMemory: 30 * MemoryBytes.gigabyte,
                wiredMemory: 8 * MemoryBytes.gigabyte,
                compressed: 9 * MemoryBytes.gigabyte,
                memoryPressure: .warning
            ),
            totalCPUUsed: 0.46,
            processes: []
        )
    }
}
