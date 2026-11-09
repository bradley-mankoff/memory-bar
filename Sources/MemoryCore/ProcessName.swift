import Foundation

/// Process Name as Activity Monitor shows it.
public enum ProcessName {
    /// The LaunchServices display name when the process registered one, then
    /// the executable's file name, then the kernel's registered name. Activity
    /// Monitor shows the display name, which is why reading the executable
    /// alone would print "ControlCenter" where it prints "Control Center".
    public static func resolved(for reading: ProcessReading) -> String {
        // pid 0 is the kernel, which publishes no name of its own.
        if reading.pid == 0 {
            return "kernel_task"
        }
        if let displayName = trimmed(reading.displayName) {
            return displayName
        }
        if let executablePath = reading.executablePath,
           let basename = executablePath.split(separator: "/").last,
           !basename.isEmpty {
            return String(basename)
        }
        if let registeredName = trimmed(reading.registeredName) {
            return registeredName
        }
        return "Unknown"
    }

    private static func trimmed(_ text: String?) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }
}
