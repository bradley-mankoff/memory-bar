import Foundation

/// The rolling record of memory use. A sample is stored about once a minute
/// and the record keeps the last day, so a drop that happened overnight can
/// still be traced after the process that released the memory has exited.
public struct MemoryUseRecord: Sendable {
    /// Samples closer together than this are the same reading for a record
    /// that answers minute-scale questions; the app refreshes every three
    /// seconds and this keeps the write to one a minute.
    public static let sampleInterval: TimeInterval = 60

    /// How far back the record answers: the last day.
    public static let window: TimeInterval = 24 * 60 * 60

    /// The hard size limit for the file on disk. Two mebibytes hold the whole
    /// day at the sizes these samples take, and the limit still bounds the
    /// file when Process Names are unusually long.
    public static let maximumBytes = 2 * 1024 * 1024

    /// How many processes each sample keeps: the largest ten by Memory
    /// footprint. A drop of several GB always has its releaser in that list.
    public static let topProcessCount = 10

    /// The smallest fall in Memory Used that the reader reports as a drop.
    /// One sample a minute moves by tens of MB on an idle Mac, so a gigabyte
    /// keeps the list of drops short while every several-GB drop survives.
    public static let significantDrop: UInt64 = MemoryBytes.gigabyte

    /// A sample and the bytes its line takes in the file, kept together so
    /// trimming to `maximumBytes` costs one subtraction per dropped sample
    /// instead of re-encoding the whole record.
    private struct Entry: Sendable {
        var sample: MemoryUseSample
        var lineBytes: Int
    }

    private var stored: [Entry] = []

    public init() {}

    /// A record of samples read from a file, already in time order. The file
    /// and the record share the same size limit, so a file from an older or
    /// edited version is trimmed here rather than trusted.
    init(samples: [MemoryUseSample]) {
        stored = samples.map { Entry(sample: $0, lineBytes: $0.jsonLineByteCount) }
        trimToMaximumBytes()
    }

    /// The retained samples, oldest first.
    public var samples: [MemoryUseSample] { stored.map(\.sample) }

    /// Adds a sample of this reading when it is at least `sampleInterval`
    /// after the newest one, then drops samples older than `window` and trims
    /// the oldest samples until the record fits `maximumBytes`. Returns whether
    /// the reading became a sample, so the caller knows when there is a new
    /// version to write.
    ///
    /// Ordering matters and is checked before the rows are ranked, so a refresh
    /// every few seconds costs one comparison until the next minute is due. A
    /// reading older than the newest one (the clock moved back) is refused:
    /// out-of-order samples would turn a rise into a drop. A reading whose
    /// totals could not be read is refused for the same reason.
    @discardableResult
    public mutating func record(
        at time: Date,
        totals: MemoryTotals,
        processes: [MemoryProcess]
    ) -> Bool {
        if let newest = stored.last?.sample,
           time.timeIntervalSince(newest.time) < Self.sampleInterval {
            return false
        }
        guard let sample = MemoryUseSample(at: time, totals: totals, processes: processes) else {
            return false
        }
        stored.append(Entry(sample: sample, lineBytes: sample.jsonLineByteCount))
        let cutoff = time.addingTimeInterval(-Self.window)
        stored.removeAll { $0.sample.time <= cutoff }
        trimToMaximumBytes()
        return true
    }

    /// The falls in Memory Used of at least `minimum` between consecutive
    /// retained samples, oldest first. Each drop names the processes in the
    /// earlier sample's top list whose Memory footprint is smaller in the later
    /// one or absent from it. Those releases are what the top list can prove; a
    /// process that left the list because others grew is still named, so treat
    /// the list as the suspects to check, one sample apart in time.
    public func drops(fallingAtLeast minimum: UInt64 = MemoryUseRecord.significantDrop) -> [MemoryUseDrop] {
        guard stored.count > 1 else { return [] }
        var drops: [MemoryUseDrop] = []
        for index in 1..<stored.count {
            let before = stored[index - 1].sample
            let after = stored[index].sample
            guard before.memoryUsed > after.memoryUsed,
                  before.memoryUsed - after.memoryUsed >= minimum else { continue }
            drops.append(MemoryUseDrop(before: before, after: after))
        }
        return drops
    }

    /// The file contents: one JSON object per line, oldest first, so a person
    /// or an agent can read the newest lines with `tail` without a decoder.
    func data() -> Data {
        var data = Data()
        for entry in stored {
            data.append(entry.sample.jsonLine)
            data.append(0x0A)
        }
        return data
    }

    private mutating func trimToMaximumBytes() {
        var total = stored.reduce(0) { $0 + $1.lineBytes }
        // The newest sample is never dropped: it is the sample being recorded,
        // and its own line is far under the limit.
        while total > Self.maximumBytes, stored.count > 1 {
            total -= stored.removeFirst().lineBytes
        }
    }
}

/// One fall in Memory Used between two stored samples, with the processes from
/// the earlier top list that released memory by the later sample.
public struct MemoryUseDrop: Equatable, Sendable {
    public var before: MemoryUseSample
    public var after: MemoryUseSample

    /// The Memory Used that fell between the two samples.
    public var bytesFallen: UInt64 { before.memoryUsed - after.memoryUsed }

    /// The processes that shrank or left the top list between the samples,
    /// largest release first. A process still in the later top list with the
    /// same footprint or a larger one is not listed: the record can prove it
    /// released nothing. A process missing from the later list is listed even
    /// when its footprint did not move, because leaving the list proves only
    /// that other processes passed it.
    public var releases: [MemoryUseRelease] {
        var afterFootprints: [Int32: UInt64] = [:]
        for process in after.topProcesses {
            afterFootprints[process.pid] = process.footprintBytes
        }
        return before.topProcesses.compactMap { process in
            let afterBytes = afterFootprints[process.pid]
            guard afterBytes.map({ $0 < process.footprintBytes }) ?? true else { return nil }
            return MemoryUseRelease(
                pid: process.pid,
                name: process.name,
                beforeBytes: process.footprintBytes,
                afterBytes: afterBytes
            )
        }
        .sorted(by: precedes)
    }

    private func precedes(_ left: MemoryUseRelease, _ right: MemoryUseRelease) -> Bool {
        if left.bytesReleased != right.bytesReleased {
            return left.bytesReleased > right.bytesReleased
        }
        if left.name != right.name {
            return left.name < right.name
        }
        return left.pid < right.pid
    }
}

/// One process's part of a drop: its Memory footprint in the earlier sample's
/// top list, and in the later one, nil when it was no longer in that list.
public struct MemoryUseRelease: Equatable, Sendable {
    public var pid: Int32
    public var name: String
    public var beforeBytes: UInt64
    public var afterBytes: UInt64?

    /// The Memory footprint the process gave back.
    public var bytesReleased: UInt64 { beforeBytes - (afterBytes ?? 0) }
}
