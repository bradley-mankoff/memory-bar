/// Fixed sample readings for the shell, shaped like Activity Monitor on the
/// 64GB Mac: 47GB Memory Used (30 App + 8 Wired + 9 Compressed), 46 percent
/// Total CPU Used, and six processes for the list and Search field.
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
            processes: [
                MemoryProcess(name: "Xcode", footprintBytes: 6 * MemoryBytes.gigabyte + 4 * MemoryBytes.gigabyte / 10),
                MemoryProcess(name: "Safari", footprintBytes: 3 * MemoryBytes.gigabyte + 2 * MemoryBytes.gigabyte / 10),
                MemoryProcess(name: "kernel_task", footprintBytes: 2 * MemoryBytes.gigabyte + MemoryBytes.gigabyte / 2),
                MemoryProcess(name: "WindowServer", footprintBytes: 1 * MemoryBytes.gigabyte + 8 * MemoryBytes.gigabyte / 10),
                MemoryProcess(name: "Terminal", footprintBytes: 900 * MemoryBytes.megabyte),
                MemoryProcess(name: "Finder", footprintBytes: 400 * MemoryBytes.megabyte),
            ]
        )
    }
}
