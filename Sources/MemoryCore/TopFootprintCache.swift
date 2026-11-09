import Foundation

/// Keeps the last `top` sample because the subprocess costs about half a
/// second while the popup refreshes every three seconds. Refresh passes
/// `force` to sample the process table again.
public struct TopFootprintCache: Sendable {
    /// Long enough that `top` runs about once a minute, short enough that the
    /// roughly 280 protected rows do not drift far from Activity Monitor.
    public static let maximumAge: TimeInterval = 45

    private var sampled: (value: TopMemorySample, at: Date)?

    public init() {}

    /// The sample to use now, reading a new one only when the cache is empty or
    /// older than `maximumAge`, or when `force` is set.
    public mutating func sample(
        at now: Date,
        force: Bool = false,
        read: () -> TopMemorySample
    ) -> TopMemorySample {
        if !force, let sampled, now.timeIntervalSince(sampled.at) < Self.maximumAge {
            return sampled.value
        }
        let value = read()
        sampled = (value, now)
        return value
    }
}
