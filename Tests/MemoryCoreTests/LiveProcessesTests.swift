import XCTest
import MemoryCore

/// These tests read the live process table of the Mac they run on, which is
/// what the popup does. They expect a desktop session where `top` sees
/// kernel_task and the kernel refuses another user's footprint, as on the
/// test Mac.
final class LiveProcessesTests: XCTestCase {
    func testKernelTaskIsAListedRowWithAFootprintFromTheTopSample() throws {
        let top = LiveProcesses.topSample()
        let rows = ProcessList.rows(from: LiveProcesses.readings(topSample: top))
        let kernel = try XCTUnwrap(rows.first { $0.pid == 0 }, "kernel_task is missing from the live list")
        XCTAssertEqual(kernel.name, "kernel_task")
        let bytes = try XCTUnwrap(kernel.footprintBytes, "kernel_task has no footprint")
        XCTAssertGreaterThan(bytes, 20 * MemoryBytes.gigabyte)
        // A plain `top` prints kernel_task as 21G and would flag the sample as
        // approximate, so this is what proves the whole-MiB cell was read.
        XCTAssertFalse(top.isApproximate)
    }

    func testProtectedProcessGetsItsFootprintFromTheTopSample() throws {
        // WindowServer belongs to _windowserver, so the kernel refuses its
        // footprint and the row can only come from the top sample.
        let top = LiveProcesses.topSample()
        let readings = LiveProcesses.readings(topSample: top)
        let windowServer = try XCTUnwrap(
            readings.first { $0.executablePath?.hasSuffix("/WindowServer") == true },
            "WindowServer is missing from the live list"
        )
        guard LiveProcesses.footprint(of: windowServer.pid) == nil else {
            throw XCTSkip("WindowServer's footprint is readable here, so there is no top fallback to test")
        }
        XCTAssertEqual(windowServer.footprintBytes, top.footprint(of: windowServer.pid))
        XCTAssertGreaterThan(try XCTUnwrap(windowServer.footprintBytes), 0)
    }

    func testLiveRowsAreRankedLargestFootprintFirst() {
        let rows = ProcessList.rows(from: LiveProcesses.readings(topSample: LiveProcesses.topSample()))
        let sizes = rows.compactMap(\.footprintBytes)
        XCTAssertFalse(sizes.isEmpty)
        XCTAssertEqual(sizes, sizes.sorted(by: >), "live rows are not largest first")
    }
}
