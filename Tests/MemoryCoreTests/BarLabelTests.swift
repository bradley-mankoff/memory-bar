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

    func testBarLabelShowsLiveTotalCPUUsedAsAWholePercent() throws {
        // The worked example from LiveCPUTests: 350 of 1,000 elapsed ticks
        // were used, so the Bar label reads 35 percent.
        let totalUsed = try XCTUnwrap(
            CPUTicks(user: 1_230, system: 620, idle: 8_650, nice: 0)
                .totalUsed(since: CPUTicks(user: 1_000, system: 500, idle: 8_000, nice: 0))
        )
        XCTAssertEqual(
            BarLabel.text(used: 47 * MemoryBytes.gigabyte, totalCPUUsed: totalUsed),
            "47G \u{00B7} 35%"
        )
    }
}
