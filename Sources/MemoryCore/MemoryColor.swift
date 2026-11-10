/// The Bar label colour, chosen from Memory Used as a share of the Mac's
/// Physical Memory: green below 50 percent used, yellow from 50 percent to
/// 87.5 percent, red above. On a 64GB Mac those shares land on the approved
/// limits of 32GB and 56GB, and on a 24GB Mac they land on 12GB and 21GB, so
/// the same stress shows the same colour on any Mac.
public enum MemoryColor: Equatable, Sendable {
    case green
    case yellow
    case red

    /// Boundaries belong to the lower band at 50 percent and to yellow at 87.5
    /// percent; only memory above 87.5 percent of Physical Memory turns red.
    /// The comparisons cross-multiply a half and seven eighths rather than
    /// dividing, so no rounding moves the edges.
    /// A zero Physical Memory means the page counters could not be read, which
    /// the old fixed bands showed as green; the share cannot be computed there,
    /// so the answer stays green rather than turning a blank reading yellow or
    /// red.
    public init(forUsedMemory bytes: UInt64, physicalMemory: UInt64) {
        guard physicalMemory > 0 else {
            self = .green
            return
        }
        if bytes * 2 < physicalMemory {
            self = .green
        } else if bytes * 8 <= physicalMemory * 7 {
            self = .yellow
        } else {
            self = .red
        }
    }
}
