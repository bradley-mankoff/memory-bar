import Foundation

/// One stored sample of memory use: the Memory Used totals, and the largest
/// processes by Memory footprint at that moment. A sample is taken about once a
/// minute, so a drop between two samples names the processes that were in the
/// earlier top list and are smaller or gone in the later one.
public struct MemoryUseSample: Codable, Equatable, Sendable {
    public var time: Date
    public var memoryUsed: UInt64
    public var appMemory: UInt64
    public var wiredMemory: UInt64
    public var compressed: UInt64
    public var topProcesses: [MemoryUseProcess]

    /// A sample of the live totals and the process rows the popup shows. The
    /// rows are ranked largest Memory footprint first and cut to the ten
    /// largest, because the record answers a drop question by what was in the
    /// top list, not by every process. Rows no source could measure are left
    /// out: they have no footprint to compare and would waste a place.
    ///
    /// nil when the totals could not be read, which `LiveTotals` reports as
    /// zero Physical Memory. Storing that reading would look like a full-memory
    /// drop to every later reader.
    init?(at time: Date, totals: MemoryTotals, processes: [MemoryProcess]) {
        guard totals.physicalMemory > 0 else { return nil }
        self.time = time
        self.memoryUsed = totals.memoryUsed
        self.appMemory = totals.appMemory
        self.wiredMemory = totals.wiredMemory
        self.compressed = totals.compressed
        self.topProcesses = Array(
            ProcessList.ranked(processes)
                .compactMap { row in
                    row.footprintBytes.map {
                        MemoryUseProcess(pid: row.pid, name: row.name, footprintBytes: $0)
                    }
                }
                .prefix(MemoryUseRecord.topProcessCount)
        )
    }

    /// This sample as the one JSON object a record line holds, without its
    /// newline. The encoder writes sorted keys so the file diffs by line, and
    /// ISO 8601 times so a line reads without a date decoder.
    var jsonLine: Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        // JSONEncoder throws only for a value it cannot represent; this sample
        // holds integers, strings and one date, so there is nothing to fail.
        return (try? encoder.encode(self)) ?? Data()
    }

    /// The bytes this sample takes on a record line, including its newline.
    var jsonLineByteCount: Int { jsonLine.count + 1 }

    /// The sample one record line holds, or nil when the line is not a sample.
    /// The decoder's date setting sits beside `jsonLine`'s so the line format
    /// is stated once and the reading and the writing cannot drift apart.
    init?(jsonLine: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let sample = try? decoder.decode(MemoryUseSample.self, from: jsonLine) else { return nil }
        self = sample
    }
}

/// One process as the record stores it: the Process Name, pid and Memory
/// footprint. The pid is the row identity, so a process that exits and a new
/// one with the same name stay apart.
public struct MemoryUseProcess: Codable, Equatable, Sendable {
    public var pid: Int32
    public var name: String
    public var footprintBytes: UInt64

    public init(pid: Int32, name: String, footprintBytes: UInt64) {
        self.pid = pid
        self.name = name
        self.footprintBytes = footprintBytes
    }
}
