import Foundation

/// One row of the Memory tab's process list: only the Process Name and the
/// Memory footprint, as the Spec asks.
public struct MemoryProcess: Equatable, Sendable, Identifiable {
    public var name: String
    public var footprintBytes: UInt64

    public var id: String { name }

    public init(name: String, footprintBytes: UInt64) {
        self.name = name
        self.footprintBytes = footprintBytes
    }
}
