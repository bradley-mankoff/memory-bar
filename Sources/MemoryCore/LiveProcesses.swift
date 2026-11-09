import AppKit
import Darwin
import Foundation

/// Reads the live process table: the name of every process, and the Memory
/// footprint of every process the kernel will hand out. The kernel allows a
/// process to read its own user's footprints with `proc_pid_rusage` and refuses
/// every other process, so the refused pids, kernel_task included, are filled
/// from one `top` sample that the caller passes in.
public enum LiveProcesses {
    /// The pids the kernel lists, about 1,250 on the test Mac, including pid 0
    /// for kernel_task.
    public static func pids() -> [Int32] {
        let estimate = proc_listallpids(nil, 0)
        guard estimate > 0 else { return [] }
        // The table can grow between the count and the fill, so ask for room.
        var pids = [Int32](repeating: 0, count: Int(estimate) * 2)
        let count = pids.withUnsafeMutableBytes { buffer in
            proc_listallpids(buffer.baseAddress, Int32(buffer.count))
        }
        guard count > 0 else { return [] }
        return Array(pids.prefix(Int(count)))
    }

    /// One reading per pid. The footprint is the kernel's exact
    /// `ri_phys_footprint` when the process belongs to this user, and the
    /// cached top sample's value otherwise; when neither source measured the
    /// pid the footprint is nil and the popup shows "Unavailable".
    public static func readings(topSample: TopMemorySample) -> [ProcessReading] {
        pids().map { pid in
            ProcessReading(
                pid: pid,
                displayName: displayName(of: pid),
                executablePath: executablePath(of: pid),
                registeredName: registeredName(of: pid),
                footprintBytes: footprint(of: pid) ?? topSample.footprint(of: pid)
            )
        }
    }

    /// The Memory footprint in bytes, nil when the kernel refuses this pid
    /// because it belongs to another user, which is the case for about 280 of
    /// the processes on the test Mac.
    public static func footprint(of pid: Int32) -> UInt64? {
        var info = rusage_info_v4()
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
            }
        }
        guard status == 0 else { return nil }
        return info.ri_phys_footprint
    }

    /// The LaunchServices display name, which is the string Activity Monitor
    /// shows, such as "Control Center" for ControlCenter.
    public static func displayName(of pid: Int32) -> String? {
        NSRunningApplication(processIdentifier: pid)?.localizedName
    }

    /// The executable's full path, readable for every pid because the kernel
    /// skips the ownership check for PROC_PIDPATHINFO.
    public static func executablePath(of pid: Int32) -> String? {
        var buffer = [CChar](repeating: 0, count: 4096)
        let length = buffer.withUnsafeMutableBufferPointer {
            proc_pidpath(pid, $0.baseAddress, UInt32($0.count))
        }
        guard length > 0 else { return nil }
        return String(cString: buffer)
    }

    /// The kernel's registered name, the last choice because it differs from
    /// what Activity Monitor shows for about 70 processes on the test Mac.
    public static func registeredName(of pid: Int32) -> String? {
        var buffer = [CChar](repeating: 0, count: 256)
        let length = buffer.withUnsafeMutableBufferPointer {
            proc_name(pid, $0.baseAddress, UInt32($0.count))
        }
        guard length > 0 else { return nil }
        return String(cString: buffer)
    }

    /// One `top -l 1 -c d -stats pid,mem` sample. `-c d` is what makes top
    /// print 21354M for kernel_task instead of folding it to 21G, and `-l 1`
    /// keeps the first sample, because every later sample is a delta that
    /// reads 0B for an idle process.
    public static func topSample() -> TopMemorySample {
        let top = Process()
        top.executableURL = URL(fileURLWithPath: "/usr/bin/top")
        top.arguments = ["-l", "1", "-c", "d", "-stats", "pid,mem"]
        let output = Pipe()
        top.standardOutput = output
        top.standardError = FileHandle.nullDevice
        do {
            try top.run()
        } catch {
            return .unmeasured
        }
        // Read before waiting so a full pipe cannot block top.
        let data = output.fileHandleForReading.readDataToEndOfFile()
        top.waitUntilExit()
        guard top.terminationStatus == 0 else {
            return .unmeasured
        }
        return TopMemorySample.parse(String(decoding: data, as: UTF8.self))
    }
}
