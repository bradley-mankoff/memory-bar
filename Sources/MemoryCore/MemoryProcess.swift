import Foundation

/// One row of the Memory tab's process list: only the Process Name and the
/// Memory footprint, as the Spec asks. The pid is the row identity because two
/// processes can share a name, such as two Safari Web Content rows.
public struct MemoryProcess: Equatable, Sendable, Identifiable {
    public var pid: Int32
    public var name: String
    /// nil when no source could measure this process, which the popup shows as
    /// "Unavailable" rather than a misleading zero.
    public var footprintBytes: UInt64?

    public var id: Int32 { pid }

    public init(pid: Int32, name: String, footprintBytes: UInt64?) {
        self.pid = pid
        self.name = name
        self.footprintBytes = footprintBytes
    }
}
