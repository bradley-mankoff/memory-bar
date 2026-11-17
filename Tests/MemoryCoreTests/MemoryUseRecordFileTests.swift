import XCTest
import MemoryCore

/// The record on disk. The drop is the one measured: on 2026-11-16
/// Memory Used fell from 45 GB to 15 GB, and the Factory process, 20 GB, was in
/// the top list at 22:30 and gone at 23:13. The tests read the drop back from a
/// file with the process already exited and the app restarted.
final class MemoryUseRecordFileTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_794_868_200)
    private var fileURL: URL!

    override func setUpWithError() throws {
        // A directory that does not exist yet, so saving also proves it creates
        // the folder on the first run.
        fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("memory-use.jsonl")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }

    func testADropIsStillTraceableAfterTheProcessExitedAndTheAppRestarted() throws {
        var recorded = MemoryUseRecord()
        recorded.record(
            at: start,
            totals: totals(memoryUsed: 45 * MemoryBytes.gigabyte),
            processes: [
                MemoryProcess(pid: 700, name: "Factory", footprintBytes: 20 * MemoryBytes.gigabyte),
                MemoryProcess(pid: 800, name: "Xcode", footprintBytes: 6 * MemoryBytes.gigabyte),
                MemoryProcess(pid: 900, name: "Safari", footprintBytes: 3 * MemoryBytes.gigabyte),
            ]
        )
        recorded.record(
            at: start.addingTimeInterval(43 * 60),
            totals: totals(memoryUsed: 15 * MemoryBytes.gigabyte),
            processes: [
                MemoryProcess(pid: 800, name: "Xcode", footprintBytes: 6 * MemoryBytes.gigabyte),
                MemoryProcess(pid: 900, name: "Safari", footprintBytes: 3 * MemoryBytes.gigabyte),
            ]
        )
        try MemoryUseRecordFile.save(recorded, to: fileURL)

        let restarted = MemoryUseRecordFile.load(from: fileURL)
        let drop = try XCTUnwrap(restarted.drops().first)
        let release = try XCTUnwrap(drop.releases.first)

        XCTAssertEqual(release.name, "Factory")
        XCTAssertEqual(release.beforeBytes, 20 * MemoryBytes.gigabyte)
        XCTAssertNil(release.afterBytes)
    }

    func testAnEmptyRecordLoadsWhenNoFileExists() {
        let record = MemoryUseRecordFile.load(from: fileURL)

        XCTAssertEqual(record.samples, [])
    }

    func testLoadKeepsTheReadableSamplesWhenOneLineCannotBeDecoded() throws {
        let line = #"{"appMemory":0,"compressed":0,"memoryUsed":48318382080,"time":"2026-11-16T22:30:00Z","topProcesses":[],"wiredMemory":0}"#
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("\(line)\nnot a sample\n".utf8).write(to: fileURL)

        let record = MemoryUseRecordFile.load(from: fileURL)

        XCTAssertEqual(record.samples.map(\.time), [start])
    }

    func testTheStoredRecordStaysWithinItsFixedSizeLimit() throws {
        // Ten processes with 200-character names per sample is longer than any
        // real Process Name, so 1,000 samples of one day are far past the limit
        // and the record has to drop old samples to stay inside it.
        let longName = String(repeating: "a", count: 200)
        let processes = (1...10).map { index in
            MemoryProcess(pid: Int32(index), name: longName, footprintBytes: 2 * MemoryBytes.gigabyte)
        }
        var record = MemoryUseRecord()
        let totals = totals(memoryUsed: 45 * MemoryBytes.gigabyte)
        var time = start
        for _ in 0..<1_000 {
            record.record(at: time, totals: totals, processes: processes)
            time = time.addingTimeInterval(MemoryUseRecord.sampleInterval)
        }

        try MemoryUseRecordFile.save(record, to: fileURL)
        let size = try XCTUnwrap(
            FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64
        )

        XCTAssertLessThanOrEqual(size, UInt64(MemoryUseRecord.maximumBytes))
        XCTAssertEqual(record.samples.last?.time, time.addingTimeInterval(-MemoryUseRecord.sampleInterval))
    }

    /// A plausible 64 GB reading whose App Memory fills it, the shape a reading
    /// of this Mac has. The record test file has its own `totals`, which leaves
    /// App Memory, Wired Memory and Compressed free for the case it pins.
    private func totals(memoryUsed: UInt64) -> MemoryTotals {
        MemoryTotals(
            memoryUsed: memoryUsed,
            physicalMemory: 64 * MemoryBytes.gigabyte,
            cachedFiles: 0,
            swapUsed: 0,
            appMemory: memoryUsed,
            wiredMemory: 0,
            compressed: 0,
            memoryPressure: .normal
        )
    }
}
