/// One `top -l 1 -c d -stats pid,mem` sample: the Memory footprint of every
/// process in bytes, keyed by pid.
public struct TopMemorySample: Equatable, Sendable {
    public var footprints: [Int32: UInt64]
    /// True when the cells came back in `top`'s coarse whole-gigabyte or delta
    /// format, which happens when it cannot print whole MiB. The popup says so
    /// rather than passing the numbers off as precise.
    public var isApproximate: Bool

    public init(footprints: [Int32: UInt64], isApproximate: Bool = false) {
        self.footprints = footprints
        self.isApproximate = isApproximate
    }

    /// The sample for a `top` run that failed: no measurements, and flagged
    /// approximate because no whole-MiB cell was read.
    static let unmeasured = TopMemorySample(footprints: [:], isApproximate: true)

    /// The footprint of one pid, nil when the sample has no row for it or the
    /// row reads zero, which is what `top` prints for a delta sample rather
    /// than a measurement.
    public func footprint(of pid: Int32) -> UInt64? {
        guard let value = footprints[pid], value > 0 else { return nil }
        return value
    }

    public static func parse(_ text: String) -> TopMemorySample {
        var footprints: [Int32: UInt64] = [:]
        var isApproximate = false
        for line in text.split(separator: "\n") {
            let cells = line.split(separator: " ", omittingEmptySubsequences: true)
            guard cells.count == 2,
                  let pid = Int32(cells[0]),
                  let size = size(of: cells[1]) else { continue }
            footprints[pid] = size.bytes
            isApproximate = isApproximate || size.isCoarse
        }
        return TopMemorySample(footprints: footprints, isApproximate: isApproximate)
    }

    private struct Cell {
        var bytes: UInt64
        var isCoarse: Bool
    }

    /// `top` prints a number and a unit letter, with "B" on its own for zero,
    /// for example "21354M", "29136K" or "0B".
    private static func size(of cell: Substring) -> Cell? {
        let multipliers: [Character: (multiplier: UInt64, isCoarse: Bool)] = [
            "B": (1, true),
            "K": (MemoryBytes.kilobyte, false),
            "M": (MemoryBytes.megabyte, false),
            "G": (MemoryBytes.gigabyte, true),
            "T": (MemoryBytes.terabyte, true),
        ]
        guard let unit = cell.last,
              let (multiplier, isCoarse) = multipliers[unit],
              let number = Double(cell.dropLast()),
              number >= 0 else { return nil }
        return Cell(bytes: UInt64((number * Double(multiplier)).rounded()), isCoarse: isCoarse)
    }
}
