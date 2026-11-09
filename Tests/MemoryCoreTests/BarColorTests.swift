import XCTest
import MemoryCore

final class BarColorTests: XCTestCase {
    func testBarColorIsGreenBelowThirtyTwoGigabytes() {
        XCTAssertEqual(MemoryColor(forUsedMemory: 31 * MemoryBytes.gigabyte), .green)
        XCTAssertEqual(MemoryColor(forUsedMemory: 32 * MemoryBytes.gigabyte - 1), .green)
    }

    func testBarColorIsYellowFromThirtyTwoThroughFiftySixGigabytes() {
        XCTAssertEqual(MemoryColor(forUsedMemory: 32 * MemoryBytes.gigabyte), .yellow)
        XCTAssertEqual(MemoryColor(forUsedMemory: 47 * MemoryBytes.gigabyte), .yellow)
        XCTAssertEqual(MemoryColor(forUsedMemory: 56 * MemoryBytes.gigabyte), .yellow)
    }

    func testBarColorIsRedAboveFiftySixGigabytes() {
        XCTAssertEqual(MemoryColor(forUsedMemory: 56 * MemoryBytes.gigabyte + 1), .red)
    }
}
