import XCTest
import MemoryCore

final class ProcessListTests: XCTestCase {
    private var sample: [MemoryProcess] {
        [
            MemoryProcess(name: "Safari", footprintBytes: 512 * MemoryBytes.megabyte),
            MemoryProcess(name: "Xcode", footprintBytes: 4 * MemoryBytes.gigabyte),
            MemoryProcess(name: "Terminal", footprintBytes: 1 * MemoryBytes.gigabyte),
        ]
    }

    func testProcessesSortLargestMemoryFootprintFirst() {
        XCTAssertEqual(ProcessList.ranked(sample).map(\.name), ["Xcode", "Terminal", "Safari"])
    }

    func testSearchFiltersProcessNameCaseInsensitivelyAndKeepsLargestFirstOrder() {
        let processes = [
            MemoryProcess(name: "Terminal", footprintBytes: 512 * MemoryBytes.megabyte),
            MemoryProcess(name: "iTerm", footprintBytes: 2 * MemoryBytes.gigabyte),
            MemoryProcess(name: "Xcode", footprintBytes: 4 * MemoryBytes.gigabyte),
            MemoryProcess(name: "Finder", footprintBytes: 1 * MemoryBytes.gigabyte),
        ]
        XCTAssertEqual(ProcessList.ranked(processes, search: "TER").map(\.name), ["iTerm", "Terminal"])
    }

    func testEmptySearchKeepsEveryProcessLargestFirst() {
        XCTAssertEqual(ProcessList.ranked(sample, search: "").map(\.name), ["Xcode", "Terminal", "Safari"])
    }

    func testSearchWithNoMatchReturnsNoProcesses() {
        XCTAssertEqual(ProcessList.ranked(sample, search: "chrome").map(\.name), [])
    }
}
