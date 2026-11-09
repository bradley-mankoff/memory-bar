/// The Memory tab's process list. Largest Memory footprint first, narrowed by
/// a case insensitive substring of Process Name in the way Activity Monitor's
/// Search field works; filtering never changes the order.
public enum ProcessList {
    public static func ranked(_ processes: [MemoryProcess], search: String = "") -> [MemoryProcess] {
        let needle = search.lowercased()
        return processes
            .filter { needle.isEmpty || $0.name.lowercased().contains(needle) }
            .sorted { $0.footprintBytes > $1.footprintBytes }
    }
}
