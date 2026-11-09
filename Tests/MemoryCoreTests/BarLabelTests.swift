import XCTest
import MemoryCore

final class BarLabelTests: XCTestCase {
    func testBarLabelShowsWholeGigabytesThenMiddleDotThenWholePercent() {
        XCTAssertEqual(
            BarLabel.text(used: 47 * MemoryBytes.gigabyte, totalCPUUsed: 0.46),
            "47G \u{00B7} 46%"
        )
    }

    func testBarLabelRoundsMemoryUpToTheNearestWholeGigabyte() {
        // 46.6 GiB rounds to 47G and 46.2 percent rounds to 46%.
        XCTAssertEqual(
            BarLabel.text(used: 46 * MemoryBytes.gigabyte + MemoryBytes.gigabyte * 6 / 10, totalCPUUsed: 0.462),
            "47G \u{00B7} 46%"
        )
    }

    func testBarLabelRoundsTotalCPUUsedToTheNearestWholePercent() {
        XCTAssertEqual(
            BarLabel.text(used: 47 * MemoryBytes.gigabyte, totalCPUUsed: 0.466),
            "47G \u{00B7} 47%"
        )
    }
}
