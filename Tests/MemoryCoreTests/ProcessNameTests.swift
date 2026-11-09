import XCTest
import MemoryCore

/// Process Name is the name Activity Monitor shows. Activity Monitor reads the
/// LaunchServices display name, so the popup has to read the same string
/// rather than the executable's name.
final class ProcessNameTests: XCTestCase {
    func testLaunchServicesDisplayNameWins() {
        XCTAssertEqual(
            ProcessName.resolved(
                for: ProcessReading(
                    pid: 1125,
                    displayName: "Control Center",
                    executablePath: "/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter",
                    registeredName: "ControlCenter"
                )
            ),
            "Control Center"
        )
    }

    func testExecutableBasenameIsUsedWhenThereIsNoDisplayName() {
        // This pid has no LaunchServices record, so Activity Monitor shows the
        // bundle's executable name on that row.
        XCTAssertEqual(
            ProcessName.resolved(
                for: ProcessReading(
                    pid: 55015,
                    executablePath: "/System/Library/Frameworks/WebKit.framework/XPCServices/com.apple.WebKit.WebContent.xpc/Contents/MacOS/com.apple.WebKit.WebContent",
                    registeredName: "com.apple.WebKit.WebContent"
                )
            ),
            "com.apple.WebKit.WebContent"
        )
    }

    func testRegisteredNameIsTheLastChoice() {
        XCTAssertEqual(
            ProcessName.resolved(for: ProcessReading(pid: 42, registeredName: "launchd")),
            "launchd"
        )
    }

    func testKernelProcessIsNamedKernelTask() {
        // The kernel reports no name for pid 0 through proc_name or
        // proc_pidpath, and Activity Monitor's first row is kernel_task.
        XCTAssertEqual(ProcessName.resolved(for: ProcessReading(pid: 0)), "kernel_task")
    }

    func testBlankDisplayNameFallsThroughToTheExecutable() {
        XCTAssertEqual(
            ProcessName.resolved(
                for: ProcessReading(pid: 1, displayName: "  ", executablePath: "/sbin/launchd")
            ),
            "launchd"
        )
    }
}
