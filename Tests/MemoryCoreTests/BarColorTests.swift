import XCTest
import MemoryCore

final class BarColorTests: XCTestCase {
    func testBarColorOnSixtyFourGigabyteMacKeepsThirtyTwoAndFiftySixGigabyteLimits() {
        let sixtyFourGigabytes = 64 * MemoryBytes.gigabyte
        XCTAssertEqual(MemoryColor(forUsedMemory: 31 * MemoryBytes.gigabyte, physicalMemory: sixtyFourGigabytes), .green)
        XCTAssertEqual(MemoryColor(forUsedMemory: 32 * MemoryBytes.gigabyte - 1, physicalMemory: sixtyFourGigabytes), .green)
        XCTAssertEqual(MemoryColor(forUsedMemory: 32 * MemoryBytes.gigabyte, physicalMemory: sixtyFourGigabytes), .yellow)
        XCTAssertEqual(MemoryColor(forUsedMemory: 47 * MemoryBytes.gigabyte, physicalMemory: sixtyFourGigabytes), .yellow)
        XCTAssertEqual(MemoryColor(forUsedMemory: 56 * MemoryBytes.gigabyte, physicalMemory: sixtyFourGigabytes), .yellow)
        XCTAssertEqual(MemoryColor(forUsedMemory: 56 * MemoryBytes.gigabyte + 1, physicalMemory: sixtyFourGigabytes), .red)
    }

    func testBarColorOnTwentyFourGigabyteMacUsesTwelveAndTwentyOneGigabyteLimits() {
        let twentyFourGigabytes = 24 * MemoryBytes.gigabyte
        XCTAssertEqual(MemoryColor(forUsedMemory: 11 * MemoryBytes.gigabyte, physicalMemory: twentyFourGigabytes), .green)
        XCTAssertEqual(MemoryColor(forUsedMemory: 12 * MemoryBytes.gigabyte - 1, physicalMemory: twentyFourGigabytes), .green)
        XCTAssertEqual(MemoryColor(forUsedMemory: 12 * MemoryBytes.gigabyte, physicalMemory: twentyFourGigabytes), .yellow)
        XCTAssertEqual(MemoryColor(forUsedMemory: 21 * MemoryBytes.gigabyte, physicalMemory: twentyFourGigabytes), .yellow)
        XCTAssertEqual(MemoryColor(forUsedMemory: 21 * MemoryBytes.gigabyte + 1, physicalMemory: twentyFourGigabytes), .red)
    }

    func testBarColorIsGreenWhenPhysicalMemoryCannotBeRead() {
        XCTAssertEqual(MemoryColor(forUsedMemory: 0, physicalMemory: 0), .green)
    }
}
