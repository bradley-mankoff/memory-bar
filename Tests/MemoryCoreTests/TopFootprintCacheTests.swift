import XCTest
import MemoryCore

/// A `top` sample costs about half a second, so one sample serves the three
/// second refresh until it ages out, and Refresh asks for a new one.
final class TopFootprintCacheTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000)

    func testSampleIsReusedWhileItIsFresh() {
        var cache = TopFootprintCache()
        let first = cache.sample(at: start) {
            TopMemorySample(footprints: [0: 20 * MemoryBytes.gigabyte])
        }
        let reused = cache.sample(at: start.addingTimeInterval(10)) {
            TopMemorySample(footprints: [0: 30 * MemoryBytes.gigabyte])
        }
        XCTAssertEqual(first.footprints[0], 20 * MemoryBytes.gigabyte)
        XCTAssertEqual(reused.footprints[0], 20 * MemoryBytes.gigabyte)
    }

    func testSampleIsReadAgainAfterTheMaximumAge() {
        var cache = TopFootprintCache()
        _ = cache.sample(at: start) {
            TopMemorySample(footprints: [0: 20 * MemoryBytes.gigabyte])
        }
        let refreshed = cache.sample(at: start.addingTimeInterval(TopFootprintCache.maximumAge + 1)) {
            TopMemorySample(footprints: [0: 30 * MemoryBytes.gigabyte])
        }
        XCTAssertEqual(refreshed.footprints[0], 30 * MemoryBytes.gigabyte)
    }

    func testRefreshForcesANewSample() {
        var cache = TopFootprintCache()
        _ = cache.sample(at: start) {
            TopMemorySample(footprints: [0: 20 * MemoryBytes.gigabyte])
        }
        let forced = cache.sample(at: start.addingTimeInterval(5), force: true) {
            TopMemorySample(footprints: [0: 30 * MemoryBytes.gigabyte])
        }
        XCTAssertEqual(forced.footprints[0], 30 * MemoryBytes.gigabyte)
    }
}
