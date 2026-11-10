import XCTest
import MemoryCore

/// Total CPU Used is the share of CPU ticks that were not idle, the figure
/// Activity Monitor's CPU tab splits into System plus User. The worked examples
/// use 1,000 elapsed ticks so the expected fractions read directly off the
/// counts.
final class LiveCPUTests: XCTestCase {
    func testTotalCPUUsedIsSystemPlusUserOfTheElapsedTicks() throws {
        // 230 User plus 120 System of 1,000 ticks is 350 ticks, or 35 percent.
        let used = try XCTUnwrap(later.totalUsed(since: earlier))
        XCTAssertEqual(used, 0.35, accuracy: 0.000_001)
    }

    func testTotalCPUUsedIsOneHundredPercentMinusIdle() throws {
        // Nice time is CPU time in use, so 100 minus the 800 Idle ticks is 20
        // percent even though System plus User alone is only 15.
        let used = try XCTUnwrap(
            CPUTicks(user: 1_100, system: 550, idle: 8_800, nice: 50)
                .totalUsed(since: CPUTicks(user: 1_000, system: 500, idle: 8_000, nice: 0))
        )
        XCTAssertEqual(used, 0.20, accuracy: 0.000_001)
    }

    func testTotalCPUUsedSinceBootUsesEveryTickSinceStartup() throws {
        let used = try XCTUnwrap(
            CPUTicks(user: 400, system: 100, idle: 500, nice: 0).totalUsedSinceBoot
        )
        XCTAssertEqual(used, 0.50, accuracy: 0.000_001)
    }

    func testSamplerUsesTheBootAverageFirstThenTheElapsedWindow() {
        var sampler = CPUUsageSampler()
        XCTAssertEqual(
            sampler.sample(CPUTicks(user: 400, system: 100, idle: 500, nice: 0)),
            0.50,
            accuracy: 0.000_001
        )
        // 150 of the next 600 ticks were used: User 100 plus System 50.
        XCTAssertEqual(
            sampler.sample(CPUTicks(user: 500, system: 150, idle: 950, nice: 0)),
            0.25,
            accuracy: 0.000_001
        )
    }

    func testSamplerKeepsTheLastReadingWhenNoTicksHaveElapsed() {
        var sampler = CPUUsageSampler()
        let ticks = CPUTicks(user: 400, system: 100, idle: 500, nice: 0)
        _ = sampler.sample(ticks)
        XCTAssertEqual(sampler.sample(ticks), 0.50, accuracy: 0.000_001)
    }

    func testLiveCPUTicksAdvanceWithTheHost() throws {
        let first = try XCTUnwrap(LiveCPU.read(), "the kernel refused the CPU tick counters")
        Thread.sleep(forTimeInterval: 0.2)
        let second = try XCTUnwrap(LiveCPU.read())
        XCTAssertGreaterThan(second.total, first.total)
        let used = try XCTUnwrap(second.totalUsed(since: first))
        XCTAssertGreaterThanOrEqual(used, 0)
        XCTAssertLessThanOrEqual(used, 1)
    }

    private let earlier = CPUTicks(user: 1_000, system: 500, idle: 8_000, nice: 0)
    private let later = CPUTicks(user: 1_230, system: 620, idle: 8_650, nice: 0)
}
