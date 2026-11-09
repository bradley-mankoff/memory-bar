/// The Memory tab's process list. Largest Memory footprint first, narrowed by
/// a case insensitive substring of Process Name in the way Activity Monitor's
/// Search field works; filtering never changes the order.
public enum ProcessList {
    /// The rows the popup lists: live readings named the way Activity Monitor
    /// names them, ranked largest Memory footprint first. Ranking happens here
    /// once per refresh, so a Search keystroke only filters.
    public static func rows(from readings: [ProcessReading], search: String = "") -> [MemoryProcess] {
        ranked(readings.map(row(from:)), search: search)
    }

    /// One live reading as a popup row.
    public static func row(from reading: ProcessReading) -> MemoryProcess {
        MemoryProcess(
            pid: reading.pid,
            name: ProcessName.resolved(for: reading),
            footprintBytes: reading.footprintBytes
        )
    }

    public static func ranked(_ processes: [MemoryProcess], search: String = "") -> [MemoryProcess] {
        filtered(processes.sorted(by: precedes), search: search)
    }

    /// The rows that match Search, keeping the order they were ranked in.
    public static func filtered(_ processes: [MemoryProcess], search: String) -> [MemoryProcess] {
        let needle = search.lowercased()
        guard !needle.isEmpty else { return processes }
        return processes.filter { $0.name.lowercased().contains(needle) }
    }

    /// Largest first, rows no source could measure last, then by name and pid
    /// so rows of equal size keep one order between refreshes.
    private static func precedes(_ left: MemoryProcess, _ right: MemoryProcess) -> Bool {
        switch (left.footprintBytes, right.footprintBytes) {
        case let (left?, right?) where left != right:
            return left > right
        case (nil, .some):
            return false
        case (.some, nil):
            return true
        default:
            break
        }
        let leftName = left.name.lowercased()
        let rightName = right.name.lowercased()
        if leftName != rightName {
            return leftName < rightName
        }
        return left.pid < right.pid
    }
}
