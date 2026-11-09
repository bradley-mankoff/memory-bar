import XCTest
import MemoryCore

final class ProcessListTests: XCTestCase {
    private var sample: [MemoryProcess] {
        [
            MemoryProcess(pid: 3, name: "Safari", footprintBytes: 512 * MemoryBytes.megabyte),
            MemoryProcess(pid: 1, name: "Xcode", footprintBytes: 4 * MemoryBytes.gigabyte),
            MemoryProcess(pid: 2, name: "Terminal", footprintBytes: 1 * MemoryBytes.gigabyte),
        ]
    }

    func testProcessesSortLargestMemoryFootprintFirst() {
        XCTAssertEqual(ProcessList.ranked(sample).map(\.name), ["Xcode", "Terminal", "Safari"])
    }

    func testSearchFiltersProcessNameCaseInsensitivelyAndKeepsLargestFirstOrder() {
        let processes = [
            MemoryProcess(pid: 4, name: "Terminal", footprintBytes: 512 * MemoryBytes.megabyte),
            MemoryProcess(pid: 3, name: "iTerm", footprintBytes: 2 * MemoryBytes.gigabyte),
            MemoryProcess(pid: 1, name: "Xcode", footprintBytes: 4 * MemoryBytes.gigabyte),
            MemoryProcess(pid: 2, name: "Finder", footprintBytes: 1 * MemoryBytes.gigabyte),
        ]
        XCTAssertEqual(ProcessList.ranked(processes, search: "TER").map(\.name), ["iTerm", "Terminal"])
    }

    func testEmptySearchKeepsEveryProcessLargestFirst() {
        XCTAssertEqual(ProcessList.ranked(sample, search: "").map(\.name), ["Xcode", "Terminal", "Safari"])
    }

    func testSearchWithNoMatchReturnsNoProcesses() {
        XCTAssertEqual(ProcessList.ranked(sample, search: "chrome").map(\.name), [])
    }

    func testRowsFromLiveReadingsAreRankedLargestFootprintFirst() {
        let readings = [
            ProcessReading(pid: 30, displayName: "Safari", footprintBytes: 512 * MemoryBytes.megabyte),
            ProcessReading(pid: 10, displayName: "Xcode", footprintBytes: 4 * MemoryBytes.gigabyte),
            ProcessReading(pid: 20, displayName: "Terminal", footprintBytes: 1 * MemoryBytes.gigabyte),
        ]
        XCTAssertEqual(ProcessList.rows(from: readings).map(\.name), ["Xcode", "Terminal", "Safari"])
    }

    func testRowsWithoutAFootprintSortAfterMeasuredRows() {
        let readings = [
            ProcessReading(pid: 600, displayName: "WindowServer", footprintBytes: nil),
            ProcessReading(pid: 500, displayName: "Finder", footprintBytes: 40 * MemoryBytes.megabyte),
        ]
        let rows = ProcessList.rows(from: readings)
        XCTAssertEqual(rows.map(\.name), ["Finder", "WindowServer"])
        XCTAssertNil(rows.last?.footprintBytes)
    }

    func testSearchFromLiveReadingsFiltersCaseInsensitivelyAndKeepsTheLargestFirstOrder() {
        let readings = [
            ProcessReading(pid: 10, displayName: "Xcode", footprintBytes: 4 * MemoryBytes.gigabyte),
            ProcessReading(pid: 20, displayName: "iTerm", footprintBytes: 2 * MemoryBytes.gigabyte),
            ProcessReading(pid: 30, displayName: "Terminal", footprintBytes: 1 * MemoryBytes.gigabyte),
            ProcessReading(pid: 40, displayName: "Finder", footprintBytes: 512 * MemoryBytes.megabyte),
        ]
        XCTAssertEqual(ProcessList.rows(from: readings, search: "ter").map(\.name), ["iTerm", "Terminal"])
    }

    func testRowsWithTheSameNameStayApartByPid() {
        let readings = [
            ProcessReading(pid: 100, displayName: "Safari Web Content", footprintBytes: 2 * MemoryBytes.gigabyte),
            ProcessReading(pid: 101, displayName: "Safari Web Content", footprintBytes: 1 * MemoryBytes.gigabyte),
        ]
        XCTAssertEqual(ProcessList.rows(from: readings).map(\.id), [100, 101])
    }

    func testFilteringForTheSearchFieldKeepsTheRankedOrder() {
        let ranked = [
            MemoryProcess(pid: 10, name: "Xcode", footprintBytes: 4 * MemoryBytes.gigabyte),
            MemoryProcess(pid: 20, name: "iTerm", footprintBytes: 2 * MemoryBytes.gigabyte),
            MemoryProcess(pid: 30, name: "Terminal", footprintBytes: 1 * MemoryBytes.gigabyte),
        ]
        XCTAssertEqual(ProcessList.filtered(ranked, search: "TER").map(\.name), ["iTerm", "Terminal"])
    }
}
