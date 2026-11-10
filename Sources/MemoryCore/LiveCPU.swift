import Darwin

/// One reading of the kernel's CPU tick counters from
/// `host_statistics(HOST_CPU_LOAD_INFO)`: the ticks each CPU state has
/// accumulated since boot, summed over every core. Tests build one from a
/// worked sample; `LiveCPU.read()` fills it from the Mac.
public struct CPUTicks: Equatable, Sendable {
    public var user: UInt64
    public var system: UInt64
    public var idle: UInt64
    public var nice: UInt64

    public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    /// Ticks the CPUs spent doing work. Activity Monitor's CPU tab shows only
    /// System, User and Idle, so Nice time counts as used there too; on the test
    /// Mac Nice stays at zero and this is System plus User.
    public var used: UInt64 { user + system + nice }

    /// Every tick in the reading: used plus idle.
    public var total: UInt64 { used + idle }

    /// Total CPU Used between this reading and an earlier one, as a fraction of
    /// every tick that elapsed. nil when no tick has elapsed, so a second
    /// Refresh inside one tick keeps the last figure instead of reporting 0
    /// percent.
    public func totalUsed(since earlier: CPUTicks) -> Double? {
        share(
            of: Self.clampedSubtract(used, earlier.used),
            outOf: Self.clampedSubtract(total, earlier.total)
        )
    }

    /// Total CPU Used over every tick since boot, the figure for the first
    /// reading before a second sample exists.
    public var totalUsedSinceBoot: Double? {
        share(of: used, outOf: total)
    }

    /// `usedTicks` of `totalTicks` as a fraction, nil when no tick has elapsed.
    private func share(of usedTicks: UInt64, outOf totalTicks: UInt64) -> Double? {
        guard totalTicks > 0 else { return nil }
        return Double(usedTicks) / Double(totalTicks)
    }

    /// `current - previous`, or zero when the counter did not advance, so the
    /// kernel's 32-bit tick counters wrapping after weeks of uptime cannot
    /// underflow a `UInt64` and trap.
    private static func clampedSubtract(_ current: UInt64, _ previous: UInt64) -> UInt64 {
        current > previous ? current - previous : 0
    }
}

/// Reads the host's CPU tick counters for the Bar label and the popup's Total
/// CPU Used. CPU load is a rate, so the figure comes from comparing two
/// readings; the first reading has no earlier sample and uses the average since
/// boot instead, the same first number `top` prints.
public enum LiveCPU {
    /// The host's tick counters now, nil when the kernel refuses them.
    public static func read() -> CPUTicks? {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return nil }
        // cpu_ticks is indexed by CPU_STATE_USER, CPU_STATE_SYSTEM,
        // CPU_STATE_IDLE and CPU_STATE_NICE.
        return CPUTicks(
            user: UInt64(info.cpu_ticks.0),
            system: UInt64(info.cpu_ticks.1),
            idle: UInt64(info.cpu_ticks.2),
            nice: UInt64(info.cpu_ticks.3)
        )
    }
}

/// Turns successive tick readings into Total CPU Used for the store: the first
/// reading reports the average since boot, and every later reading reports the
/// window since the previous one, which is the three-second polling interval.
public struct CPUUsageSampler: Equatable, Sendable {
    private var previous: CPUTicks?
    public private(set) var totalCPUUsed: Double = 0

    public init() {}

    /// Records one reading and returns Total CPU Used. A reading whose counters
    /// have not moved keeps the last figure, so a quick second Refresh does not
    /// flash 0 percent.
    public mutating func sample(_ ticks: CPUTicks) -> Double {
        defer { previous = ticks }
        if let previous {
            if let used = ticks.totalUsed(since: previous) {
                totalCPUUsed = used
            }
        } else if let used = ticks.totalUsedSinceBoot {
            totalCPUUsed = used
        }
        return totalCPUUsed
    }
}
