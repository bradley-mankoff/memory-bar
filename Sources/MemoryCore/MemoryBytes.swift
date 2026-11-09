/// Size units for memory counts. Activity Monitor prints "GB", "MB" and "KB"
/// for these 1024-based steps, so the UI wording stays as it is while the
/// arithmetic has one set of constants instead of a literal in every file.
public enum MemoryBytes {
    public static let kilobyte: UInt64 = 1_024
    public static let megabyte: UInt64 = 1_048_576
    public static let gigabyte: UInt64 = 1_073_741_824
}
