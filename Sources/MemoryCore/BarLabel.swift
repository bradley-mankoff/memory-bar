/// The menu bar text: Memory Used rounded to whole gigabytes, a middle dot,
/// then Total CPU Used rounded to a whole percent (the Spec's `47G · 46%`).
public enum BarLabel {
    public static func text(used: UInt64, totalCPUUsed: Double) -> String {
        "\(wholeGigabytes(used))G \u{00B7} \(MemoryFormat.percent(totalCPUUsed))"
    }

    /// Used memory as a whole gigabyte count, the unit Activity Monitor
    /// labels GB.
    public static func wholeGigabytes(_ bytes: UInt64) -> Int {
        Int((Double(bytes) / Double(MemoryBytes.gigabyte)).rounded())
    }
}
