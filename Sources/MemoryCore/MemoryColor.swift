/// The Bar label colour, chosen from Memory Used with the Spec's fixed
/// limits for this Mac: green below 32GB, yellow from 32GB to 56GB, red
/// above 56GB.
public enum MemoryColor: Equatable, Sendable {
    case green
    case yellow
    case red

    /// Boundaries belong to the lower band at 32GB and to yellow at 56GB;
    /// only memory above 56GB turns red.
    public init(forUsedMemory bytes: UInt64) {
        if bytes < 32 * MemoryBytes.gigabyte {
            self = .green
        } else if bytes <= 56 * MemoryBytes.gigabyte {
            self = .yellow
        } else {
            self = .red
        }
    }
}
