import Darwin
import Foundation

/// One reading of the host's virtual memory counters: the page counts from
/// `host_statistics64`, the page size they are counted in, Physical Memory,
/// Swap Used, and the kernel's memory pressure level. `LiveTotals.read()` fills
/// it from the Mac; tests build one from a recorded sample.
public struct VMMemoryReading: Equatable, Sendable {
    public var pageSize: UInt64
    /// The kernel's free count, which includes speculative pages. Activity
    /// Monitor's free is this count minus `speculativePages`, the number
    /// `vm_stat` prints as "Pages free".
    public var freePages: UInt64
    public var speculativePages: UInt64
    public var purgeablePages: UInt64
    public var fileBackedPages: UInt64
    public var anonymousPages: UInt64
    public var wiredPages: UInt64
    public var compressorPages: UInt64
    public var physicalMemory: UInt64
    public var swapUsed: UInt64
    public var pressureLevel: Int32

    public init(
        pageSize: UInt64,
        freePages: UInt64,
        speculativePages: UInt64,
        purgeablePages: UInt64,
        fileBackedPages: UInt64,
        anonymousPages: UInt64,
        wiredPages: UInt64,
        compressorPages: UInt64,
        physicalMemory: UInt64,
        swapUsed: UInt64,
        pressureLevel: Int32
    ) {
        self.pageSize = pageSize
        self.freePages = freePages
        self.speculativePages = speculativePages
        self.purgeablePages = purgeablePages
        self.fileBackedPages = fileBackedPages
        self.anonymousPages = anonymousPages
        self.wiredPages = wiredPages
        self.compressorPages = compressorPages
        self.physicalMemory = physicalMemory
        self.swapUsed = swapUsed
        self.pressureLevel = pressureLevel
    }
}

/// The live Activity Monitor Memory tab totals. On macOS 26, Memory Used is
/// Physical Memory minus free pages, without the speculative pages Activity
/// Monitor counts as free, minus file-backed pages. It is not the sum of App
/// Memory, Wired Memory and Compressed: on the test Mac that sum reads 6 to 7
/// GB short of the window (research run 8e3f5d1ee9b44f289cdb6a5992e12e12),
/// while this formula matches it to a hundredth of a GB.
public enum LiveTotals {
    public static func totals(from reading: VMMemoryReading) -> MemoryTotals {
        // Every MemoryTotals figure is bytes, so the page counts become bytes
        // once here rather than a multiplication at each use.
        let bytes: (UInt64) -> UInt64 = { $0 * reading.pageSize }
        let free = bytes(subtractClampingAtZero(reading.freePages, reading.speculativePages))
        let fileBacked = bytes(reading.fileBackedPages)
        let purgeable = bytes(reading.purgeablePages)
        let anonymous = bytes(reading.anonymousPages)

        return MemoryTotals(
            memoryUsed: subtractClampingAtZero(reading.physicalMemory, free + fileBacked),
            physicalMemory: reading.physicalMemory,
            cachedFiles: fileBacked + purgeable,
            swapUsed: reading.swapUsed,
            appMemory: subtractClampingAtZero(anonymous, purgeable),
            wiredMemory: bytes(reading.wiredPages),
            compressed: bytes(reading.compressorPages),
            memoryPressure: memoryPressure(for: reading.pressureLevel)
        )
    }

    /// The Mac's counters now. A refused page read gives every figure zero,
    /// which the popup shows as 0 bytes rather than crashing the menu bar app.
    public static func read() -> MemoryTotals {
        guard let reading = currentReading() else { return unreadable }
        return totals(from: reading)
    }

    /// Every figure zero, the value the popup shows when the kernel refuses the
    /// page counters or the page size.
    private static let unreadable = MemoryTotals(
        memoryUsed: 0,
        physicalMemory: 0,
        cachedFiles: 0,
        swapUsed: 0,
        appMemory: 0,
        wiredMemory: 0,
        compressed: 0,
        memoryPressure: .normal
    )

    private static func currentReading() -> VMMemoryReading? {
        guard let pages = pageCounts(), let pageSize = pageSize() else { return nil }
        return VMMemoryReading(
            pageSize: pageSize,
            freePages: pages.free,
            speculativePages: pages.speculative,
            purgeablePages: pages.purgeable,
            fileBackedPages: pages.fileBacked,
            anonymousPages: pages.anonymous,
            wiredPages: pages.wired,
            compressorPages: pages.compressor,
            physicalMemory: ProcessInfo.processInfo.physicalMemory,
            swapUsed: swapUsed(),
            pressureLevel: pressureLevel()
        )
    }

    private static func pageCounts() -> (
        free: UInt64,
        speculative: UInt64,
        purgeable: UInt64,
        fileBacked: UInt64,
        anonymous: UInt64,
        wired: UInt64,
        compressor: UInt64
    )? {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        let status = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard status == KERN_SUCCESS else {
            return nil
        }
        return (
            free: UInt64(stats.free_count),
            speculative: UInt64(stats.speculative_count),
            purgeable: UInt64(stats.purgeable_count),
            fileBacked: UInt64(stats.external_page_count),
            anonymous: UInt64(stats.internal_page_count),
            wired: UInt64(stats.wire_count),
            compressor: UInt64(stats.compressor_page_count)
        )
    }

    private static func pageSize() -> UInt64? {
        var size: vm_size_t = 0
        guard host_page_size(mach_host_self(), &size) == KERN_SUCCESS else {
            return nil
        }
        return UInt64(size)
    }

    private static func swapUsed() -> UInt64 {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &usage, &size, nil, 0) == 0 else {
            return 0
        }
        return usage.xsu_used
    }

    private static func pressureLevel() -> Int32 {
        var level: Int32 = 1
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else {
            return 1
        }
        return level
    }

    /// `value - amount`, or zero when `amount` is larger, so a counter that
    /// moved between reads cannot underflow a `UInt64`.
    private static func subtractClampingAtZero(_ value: UInt64, _ amount: UInt64) -> UInt64 {
        value > amount ? value - amount : 0
    }

    /// The zones Activity Monitor's Memory Pressure graph draws: the kernel
    /// reports 1 for normal, 2 for warning and 4 for critical. The popup no
    /// longer draws the graph per the amended Spec, so these zones decide
    /// nothing visible; the reading keeps them truthful for the model.
    private static func memoryPressure(for level: Int32) -> MemoryPressure {
        switch level {
        case 2: return .warning
        case 4...: return .critical
        default: return .normal
        }
    }
}
