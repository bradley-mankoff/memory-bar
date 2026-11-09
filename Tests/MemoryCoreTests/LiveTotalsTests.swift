import XCTest
import MemoryCore

/// The totals the popup shows, checked against one coordinated sample taken on
/// the test Mac on 2026-11-09 with Activity Monitor open to the Memory tab. The
/// page counts and swap come from `vm_stat` and `sysctl vm.swapusage` in the
/// same second as the window; the expected numbers are what Activity Monitor
/// printed. `vm_stat` prints "Pages free" without the speculative pages, so the
/// fixture adds them back to the kernel's free count the app reads.
final class LiveTotalsTests: XCTestCase {
    func testTotalsMatchActivityMonitorMemoryTabWithinRounding() {
        let totals = LiveTotals.totals(from: activityMonitorSample)

        assertGigabytes(totals.memoryUsed, near: 43.26)
        assertGigabytes(totals.physicalMemory, near: 64.00)
        assertGigabytes(totals.cachedFiles, near: 17.78)
        assertGigabytes(totals.swapUsed, near: 6.32)
        assertGigabytes(totals.appMemory, near: 34.07)
        assertGigabytes(totals.wiredMemory, near: 5.45)
        assertGigabytes(totals.compressed, near: 1.74)
    }

    func testMemoryPressureZoneFollowsTheKernelPressureLevel() {
        XCTAssertEqual(totals(pressureLevel: 1).memoryPressure, .normal)
        XCTAssertEqual(totals(pressureLevel: 2).memoryPressure, .warning)
        XCTAssertEqual(totals(pressureLevel: 4).memoryPressure, .critical)
    }

    func testLiveTotalsFitInTheMacsPhysicalMemory() {
        let totals = LiveTotals.read()

        XCTAssertGreaterThan(totals.physicalMemory, 0)
        XCTAssertGreaterThan(totals.memoryUsed, 0)
        XCTAssertLessThanOrEqual(totals.memoryUsed, totals.physicalMemory)
        XCTAssertGreaterThan(totals.appMemory, 0)
        XCTAssertGreaterThan(totals.wiredMemory, 0)
    }

    /// One coordinated sample: Activity Monitor showed Memory Used 43.26 GB,
    /// Physical Memory 64.00 GB, App Memory 34.07 GB, Wired 5.45 GB, Cached
    /// Files 17.78 GB, Compressed 1.74 GB, Swap Used 6.32 GB.
    private var activityMonitorSample: VMMemoryReading {
        VMMemoryReading(
            pageSize: 16_384,
            // vm_stat printed 266,807 free plus 57,505 speculative pages.
            freePages: 324_312,
            speculativePages: 57_505,
            purgeablePages: 73_781,
            fileBackedPages: 1_091_915,
            anonymousPages: 2_307_164,
            wiredPages: 357_424,
            compressorPages: 114_232,
            physicalMemory: 64 * MemoryBytes.gigabyte,
            swapUsed: 6_780_742_533,
            pressureLevel: 1
        )
    }

    private func totals(pressureLevel: Int32) -> MemoryTotals {
        var reading = activityMonitorSample
        reading.pressureLevel = pressureLevel
        return LiveTotals.totals(from: reading)
    }

    /// Activity Monitor prints whole hundredths of a GB, so a figure within two
    /// hundredths of the window is the same figure at the window's precision.
    private func assertGigabytes(
        _ bytes: UInt64,
        near expected: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let count = Double(bytes) / Double(MemoryBytes.gigabyte)
        XCTAssertEqual(
            count,
            expected,
            accuracy: 0.02,
            "Activity Monitor showed \(expected) GB, the totals give \(MemoryFormat.bytes(bytes))",
            file: file,
            line: line
        )
    }
}
