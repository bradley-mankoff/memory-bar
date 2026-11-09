import XCTest
import MemoryCore

final class MemoryFormatTests: XCTestCase {
    func testMemorySizesUseActivityMonitorUnitsAndPrecision() {
        XCTAssertEqual(MemoryFormat.bytes(4 * MemoryBytes.gigabyte), "4.00 GB")
        XCTAssertEqual(MemoryFormat.bytes(3_435_973_837), "3.20 GB")
        XCTAssertEqual(MemoryFormat.bytes(536_870_912), "512.0 MB")
        XCTAssertEqual(MemoryFormat.bytes(1_258_291), "1.2 MB")
        XCTAssertEqual(MemoryFormat.bytes(2048), "2 KB")
    }

    func testMemorySizesOfZeroAndSmallCountsReadAsBytes() {
        XCTAssertEqual(MemoryFormat.bytes(0), "0 bytes")
        XCTAssertEqual(MemoryFormat.bytes(512), "512 bytes")
    }

    func testMemoryFootprintShowsUnavailableWhenNoSourceCouldMeasureIt() {
        XCTAssertEqual(MemoryFormat.footprint(2_500_000_000), "2.33 GB")
        XCTAssertEqual(MemoryFormat.footprint(nil), "Unavailable")
    }
}
