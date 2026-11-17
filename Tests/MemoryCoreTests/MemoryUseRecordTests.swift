import XCTest
import MemoryCore

/// The rolling record of Memory Used and the top processes by Memory
/// footprint. The drop used in these tests is the one measured: on
/// 2026-11-16 Memory Used fell from 45 GB to 15 GB, and the Factory process,
/// 20 GB, was in the top list before the drop and gone after it.
final class MemoryUseRecordTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_794_868_200)

    func testSampleKeepsTheMemoryUsedTotals() throws {
        var record = MemoryUseRecord()
        record.record(
            at: start,
            totals: totals(memoryUsed: gb(45), appMemory: gb(30), wiredMemory: gb(5), compressed: gb(2)),
            processes: []
        )

        let sample = try XCTUnwrap(record.samples.first)
        XCTAssertEqual(sample.memoryUsed, gb(45))
        XCTAssertEqual(sample.appMemory, gb(30))
        XCTAssertEqual(sample.wiredMemory, gb(5))
        XCTAssertEqual(sample.compressed, gb(2))
    }

    func testSampleKeepsTheTenLargestProcessesLargestFirst() throws {
        let processes = [
            process(pid: 3, name: "Three", gigabytes: 3),
            process(pid: 12, name: "Twelve", gigabytes: 12),
            process(pid: 1, name: "One", gigabytes: 1),
            process(pid: 9, name: "Nine", gigabytes: 9),
            process(pid: 5, name: "Five", gigabytes: 5),
            process(pid: 11, name: "Eleven", gigabytes: 11),
            process(pid: 2, name: "Two", gigabytes: 2),
            process(pid: 10, name: "Ten", gigabytes: 10),
            process(pid: 7, name: "Seven", gigabytes: 7),
            process(pid: 4, name: "Four", gigabytes: 4),
            process(pid: 8, name: "Eight", gigabytes: 8),
            process(pid: 6, name: "Six", gigabytes: 6),
        ]
        var record = MemoryUseRecord()
        record.record(at: start, totals: totals(memoryUsed: gb(45)), processes: processes)

        let sample = try XCTUnwrap(record.samples.first)
        XCTAssertEqual(
            sample.topProcesses.map(\.name),
            ["Twelve", "Eleven", "Ten", "Nine", "Eight", "Seven", "Six", "Five", "Four", "Three"]
        )
        XCTAssertEqual(
            sample.topProcesses.map(\.footprintBytes),
            (3...12).reversed().map(gb)
        )
    }

    func testSampleLeavesOutProcessesWithoutAMemoryFootprint() throws {
        let processes = [
            process(pid: 1, name: "Xcode", gigabytes: 4),
            MemoryProcess(pid: 2, name: "WindowServer", footprintBytes: nil),
            process(pid: 3, name: "Safari", gigabytes: 1),
        ]
        var record = MemoryUseRecord()
        record.record(at: start, totals: totals(memoryUsed: gb(45)), processes: processes)

        let sample = try XCTUnwrap(record.samples.first)
        XCTAssertEqual(sample.topProcesses.map(\.name), ["Xcode", "Safari"])
    }

    func testNoSampleIsMadeWhenTheTotalsCouldNotBeRead() {
        let unreadable = MemoryTotals(
            memoryUsed: 0,
            physicalMemory: 0,
            cachedFiles: 0,
            swapUsed: 0,
            appMemory: 0,
            wiredMemory: 0,
            compressed: 0,
            memoryPressure: .normal
        )
        var record = MemoryUseRecord()

        XCTAssertFalse(record.record(at: start, totals: unreadable, processes: []))
        XCTAssertEqual(record.samples, [])
    }

    func testRecordingWithinASampleIntervalKeepsTheFirstReading() {
        var record = MemoryUseRecord()

        XCTAssertTrue(record.record(at: start, totals: totals(memoryUsed: gb(45)), processes: []))
        XCTAssertFalse(
            record.record(
                at: start.addingTimeInterval(59),
                totals: totals(memoryUsed: gb(44)),
                processes: []
            )
        )

        XCTAssertEqual(record.samples.map(\.memoryUsed), [gb(45)])
    }

    func testRecordingASampleAMinuteLaterAddsIt() {
        var record = MemoryUseRecord()

        XCTAssertTrue(record.record(at: start, totals: totals(memoryUsed: gb(45)), processes: []))
        XCTAssertTrue(
            record.record(
                at: start.addingTimeInterval(60),
                totals: totals(memoryUsed: gb(44)),
                processes: []
            )
        )

        XCTAssertEqual(record.samples.map(\.memoryUsed), [gb(45), gb(44)])
    }

    func testSamplesOlderThanTheWindowAreDropped() {
        var record = MemoryUseRecord()

        record.record(at: start, totals: totals(memoryUsed: gb(45)), processes: [])
        record.record(
            at: start.addingTimeInterval(12 * 60 * 60),
            totals: totals(memoryUsed: gb(40)),
            processes: []
        )
        record.record(
            at: start.addingTimeInterval(25 * 60 * 60),
            totals: totals(memoryUsed: gb(35)),
            processes: []
        )

        XCTAssertEqual(record.samples.map(\.memoryUsed), [gb(40), gb(35)])
    }

    func testDropShowsWhenMemoryUsedFellAndByHowMuch() throws {
        var record = MemoryUseRecord()
        record.record(
            at: start,
            totals: totals(memoryUsed: gb(45)),
            processes: [process(pid: 700, name: "Factory", gigabytes: 20)]
        )
        record.record(
            at: start.addingTimeInterval(60),
            totals: totals(memoryUsed: gb(15)),
            processes: []
        )

        let drop = try XCTUnwrap(record.drops().first)

        XCTAssertEqual(drop.before.time, start)
        XCTAssertEqual(drop.after.time, start.addingTimeInterval(60))
        XCTAssertEqual(drop.bytesFallen, gb(30))
    }

    func testDropNamesTheProcessThatLeftTheTopList() throws {
        var record = MemoryUseRecord()
        record.record(
            at: start,
            totals: totals(memoryUsed: gb(45)),
            processes: [
                process(pid: 700, name: "Factory", gigabytes: 20),
                process(pid: 800, name: "Xcode", gigabytes: 6),
                process(pid: 900, name: "Safari", gigabytes: 3),
            ]
        )
        record.record(
            at: start.addingTimeInterval(60),
            totals: totals(memoryUsed: gb(15)),
            processes: [
                process(pid: 800, name: "Xcode", gigabytes: 6),
                process(pid: 900, name: "Safari", gigabytes: 3),
            ]
        )

        let release = try XCTUnwrap(record.drops().first?.releases.first)

        XCTAssertEqual(release.pid, 700)
        XCTAssertEqual(release.name, "Factory")
        XCTAssertEqual(release.beforeBytes, gb(20))
        XCTAssertNil(release.afterBytes)
        XCTAssertEqual(release.bytesReleased, gb(20))
    }

    func testDropNamesTheProcessThatShrankInTheTopList() throws {
        var record = MemoryUseRecord()
        record.record(
            at: start,
            totals: totals(memoryUsed: gb(45)),
            processes: [process(pid: 500, name: "Reader", gigabytes: 12)]
        )
        record.record(
            at: start.addingTimeInterval(60),
            totals: totals(memoryUsed: gb(35)),
            processes: [process(pid: 500, name: "Reader", gigabytes: 4)]
        )

        let release = try XCTUnwrap(record.drops().first?.releases.first)

        XCTAssertEqual(release.name, "Reader")
        XCTAssertEqual(release.beforeBytes, gb(12))
        XCTAssertEqual(release.afterBytes, gb(4))
        XCTAssertEqual(release.bytesReleased, gb(8))
    }

    func testDropLeavesOutAProcessThatGrew() {
        var record = MemoryUseRecord()
        record.record(
            at: start,
            totals: totals(memoryUsed: gb(45)),
            processes: [process(pid: 800, name: "Xcode", gigabytes: 6)]
        )
        record.record(
            at: start.addingTimeInterval(60),
            totals: totals(memoryUsed: gb(15)),
            processes: [process(pid: 800, name: "Xcode", gigabytes: 7)]
        )

        XCTAssertEqual(record.drops().first?.releases, [])
    }

    func testDropsBelowTheMinimumReleaseAreNotReported() {
        var record = MemoryUseRecord()
        record.record(
            at: start,
            totals: totals(memoryUsed: gb(44) + MemoryBytes.gigabyte / 2),
            processes: []
        )
        record.record(
            at: start.addingTimeInterval(60),
            totals: totals(memoryUsed: gb(44)),
            processes: []
        )

        XCTAssertEqual(record.drops(), [])
        XCTAssertEqual(record.drops(fallingAtLeast: 512 * MemoryBytes.megabyte).count, 1)
    }

    func testReleasesAreOrderedByHowMuchTheyReleased() {
        var record = MemoryUseRecord()
        record.record(
            at: start,
            totals: totals(memoryUsed: gb(45)),
            processes: [
                process(pid: 700, name: "Factory", gigabytes: 20),
                process(pid: 500, name: "Reader", gigabytes: 12),
            ]
        )
        record.record(
            at: start.addingTimeInterval(60),
            totals: totals(memoryUsed: gb(15)),
            processes: [process(pid: 500, name: "Reader", gigabytes: 4)]
        )

        XCTAssertEqual(record.drops().first?.releases.map(\.name), ["Factory", "Reader"])
    }

    private func gb(_ count: UInt64) -> UInt64 {
        count * MemoryBytes.gigabyte
    }

    private func totals(
        memoryUsed: UInt64,
        appMemory: UInt64 = 0,
        wiredMemory: UInt64 = 0,
        compressed: UInt64 = 0
    ) -> MemoryTotals {
        MemoryTotals(
            memoryUsed: memoryUsed,
            physicalMemory: gb(64),
            cachedFiles: 0,
            swapUsed: 0,
            appMemory: appMemory,
            wiredMemory: wiredMemory,
            compressed: compressed,
            memoryPressure: .normal
        )
    }

    private func process(pid: Int32, name: String, gigabytes: UInt64) -> MemoryProcess {
        MemoryProcess(pid: pid, name: name, footprintBytes: gb(gigabytes))
    }
}
