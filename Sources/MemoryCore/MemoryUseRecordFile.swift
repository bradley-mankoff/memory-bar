import Foundation

/// The record's file on disk: one JSON object per sample, oldest first. The
/// app rewrites the whole file after each new sample, which costs under a
/// megabyte a minute and leaves the file always complete for a reader.
public enum MemoryUseRecordFile {
    /// `~/Library/Application Support/MemoryBar/memory-use.jsonl`. Application
    /// Support is the folder for data the app owns, and a day of samples is
    /// small enough to live there next to the app's other state.
    public static var defaultURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support")
        return support
            .appendingPathComponent("MemoryBar", isDirectory: true)
            .appendingPathComponent("memory-use.jsonl")
    }

    /// The record stored at `url`, or an empty record on the first run or when
    /// the file cannot be read. A line that does not decode is skipped so one
    /// bad line does not throw away the rest of the window.
    public static func load(from url: URL) -> MemoryUseRecord {
        guard let data = try? Data(contentsOf: url) else { return MemoryUseRecord() }
        let samples = data.split(separator: 0x0A).compactMap { line in
            MemoryUseSample(jsonLine: Data(line))
        }
        return MemoryUseRecord(samples: samples)
    }

    /// Writes `record` to `url`, creating the folder on the first run. The
    /// write is atomic, so a crash while saving cannot leave half a line for
    /// the next launch to decode.
    public static func save(_ record: MemoryUseRecord, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try record.data().write(to: url, options: .atomic)
    }
}
