import XCTest
import MemoryCore

/// `top` is the only non-root source for the processes whose footprint the
/// kernel refuses to hand out, kernel_task included. These tests pin the
/// parsing of its MEM column to the sizes the machine actually prints.
final class TopMemorySampleTests: XCTestCase {
    func testWholeMebibyteAndKilobyteCellsBecomeExactBytes() {
        // Real `top -l 1 -c d -stats pid,mem` output: whole MiB for the largest
        // rows and whole KB for the small ones.
        let sample = TopMemorySample.parse(
            """
            PID    MEM
            0      21354M
            99765  11569K
            """
        )
        XCTAssertEqual(sample.footprints[0], 21_354 * MemoryBytes.megabyte)
        XCTAssertEqual(sample.footprints[99765], 11_569 * MemoryBytes.kilobyte)
        XCTAssertFalse(sample.isApproximate)
    }

    func testMebibyteKilobyteAndByteCellsFromOneSample() {
        let sample = TopMemorySample.parse(
            """
            12  21354M
            13  962M
            14  29136K
            15  0B
            """
        )
        XCTAssertEqual(sample.footprints[12], 21_354 * MemoryBytes.megabyte)
        XCTAssertEqual(sample.footprints[13], 962 * MemoryBytes.megabyte)
        XCTAssertEqual(sample.footprints[14], 29_136 * MemoryBytes.kilobyte)
        XCTAssertEqual(sample.footprints[15], 0)
    }

    func testZeroCellsAreNotAFootprint() {
        let sample = TopMemorySample.parse("15  0B")
        XCTAssertNil(sample.footprint(of: 15))
        XCTAssertTrue(sample.isApproximate)
    }

    func testWholeGigabyteCellsMarkTheSampleApproximate() {
        // Plain `top` folds 21354M down to 21G, which cannot show the 20.85 GB
        // Activity Monitor prints, so the popup calls those sizes approximate.
        let sample = TopMemorySample.parse("0  21G")
        XCTAssertEqual(sample.footprints[0], 21 * MemoryBytes.gigabyte)
        XCTAssertTrue(sample.isApproximate)
    }

    func testGlobalStatisticsLinesAreNotProcesses() {
        let sample = TopMemorySample.parse(
            """
            Processes: 1263 total, 3 running, 1260 sleeping, 5412 threads
            2026/11/09 16:26:46
            Load Avg: 6.25, 5.33, 4.63
            CPU usage: 14.15% user, 17.16% sys, 68.67% idle
            PhysMem: 60G used (5069M wired, 1764M compressor), 3366M unused.
            PID    MEM
            0      21354M
            """
        )
        XCTAssertEqual(sample.footprints.count, 1)
        XCTAssertEqual(sample.footprints[0], 21_354 * MemoryBytes.megabyte)
    }

    func testKernelTaskSampleIsAboveTwentyGigabytesAndNotAWholeGigabyte() throws {
        // The guard the review asked for: a value of exactly 21.00 GB would
        // mean `top` rounded, so the two-decimal row in the popup would differ
        // from Activity Monitor's 20.85 GB.
        let sample = TopMemorySample.parse("0  21354M")
        let bytes = try XCTUnwrap(sample.footprint(of: 0))
        XCTAssertGreaterThan(bytes, 20 * MemoryBytes.gigabyte)
        XCTAssertNotEqual(bytes, 21 * MemoryBytes.gigabyte)
        XCTAssertNotEqual(bytes % MemoryBytes.gigabyte, 0)
    }
}
