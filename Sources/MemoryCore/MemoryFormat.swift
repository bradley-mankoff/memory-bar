/// Sizes in the units and precision Activity Monitor uses on the Memory tab:
/// two decimals for gigabytes, one for megabytes, whole kilobytes, and
/// "0 bytes" when there are none.
public enum MemoryFormat {
    public static func bytes(_ bytes: UInt64) -> String {
        let count = Double(bytes)
        if count >= Double(MemoryBytes.gigabyte) {
            return String(format: "%.2f GB", count / Double(MemoryBytes.gigabyte))
        }
        if count >= Double(MemoryBytes.megabyte) {
            return String(format: "%.1f MB", count / Double(MemoryBytes.megabyte))
        }
        if count >= Double(MemoryBytes.kilobyte) {
            return String(format: "%.0f KB", count / Double(MemoryBytes.kilobyte))
        }
        return "\(bytes) bytes"
    }

    /// A fraction such as 0.46 as the whole percent "46%".
    public static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }
}
