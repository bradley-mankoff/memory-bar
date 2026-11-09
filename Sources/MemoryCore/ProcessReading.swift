/// The raw answer about one process, before naming and ranking turn it into a
/// row. Each field is a separate system reading, so a missing value means that
/// reading was refused rather than that the process lacks the property.
public struct ProcessReading: Equatable, Sendable {
    public var pid: Int32
    public var displayName: String?
    public var executablePath: String?
    public var registeredName: String?
    /// nil when no source could measure this process.
    public var footprintBytes: UInt64?

    public init(
        pid: Int32,
        displayName: String? = nil,
        executablePath: String? = nil,
        registeredName: String? = nil,
        footprintBytes: UInt64? = nil
    ) {
        self.pid = pid
        self.displayName = displayName
        self.executablePath = executablePath
        self.registeredName = registeredName
        self.footprintBytes = footprintBytes
    }
}
