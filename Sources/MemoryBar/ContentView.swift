import SwiftUI
import AppKit
import MemoryCore

struct ContentView: View {
    @ObservedObject var store: MemoryStore

    var body: some View {
        let processes = store.visibleProcesses
        return VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                // Lazy so the popup builds only the rows on screen; the list
                // holds about 1,240 processes on the test Mac.
                LazyVStack(alignment: .leading, spacing: 2) {
                    totalsSection
                        .padding(.bottom, 10)
                    Divider()
                    pressureSection
                        .padding(.vertical, 10)
                    Divider()
                    processHeader
                        .padding(.top, 10)
                        .padding(.bottom, 4)
                    if processes.isEmpty {
                        emptyProcesses
                    } else {
                        ForEach(processes) { process in
                            processRow(process)
                        }
                    }
                }
                .padding(12)
            }
            .frame(width: 380)
            .frame(maxHeight: 640)
            .fixedSize(horizontal: false, vertical: true)
            Divider()
            footer
        }
    }

    private var totalsSection: some View {
        let totals = store.snapshot.totals
        return VStack(alignment: .leading, spacing: 4) {
            totalsRow("Memory Used", MemoryFormat.bytes(totals.memoryUsed), emphasized: true)
            totalsRow("Physical Memory", MemoryFormat.bytes(totals.physicalMemory))
            totalsRow("Cached Files", MemoryFormat.bytes(totals.cachedFiles))
            totalsRow("Swap Used", MemoryFormat.bytes(totals.swapUsed))
            totalsRow("App Memory", MemoryFormat.bytes(totals.appMemory))
            totalsRow("Wired Memory", MemoryFormat.bytes(totals.wiredMemory))
            totalsRow("Compressed", MemoryFormat.bytes(totals.compressed))
            totalsRow("Total CPU Used", MemoryFormat.percent(store.snapshot.totalCPUUsed))
        }
    }

    private func totalsRow(_ label: String, _ value: String, emphasized: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(emphasized ? .headline : .callout)
            Spacer()
            Text(value)
                .font(emphasized ? .headline : .callout)
                .monospacedDigit()
        }
    }

    /// Activity Monitor's Memory Pressure graph: a green, yellow and red band
    /// with a marker in the zone of the current pressure.
    private var pressureSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Memory Pressure").font(.headline)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.green.opacity(0.7))
                        Rectangle().fill(Color.yellow.opacity(0.7))
                        Rectangle().fill(Color.red.opacity(0.7))
                    }
                    .clipShape(Capsule())
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 8, height: 8)
                        .offset(x: geo.size.width * pressurePosition - 4)
                }
            }
            .frame(height: 8)
        }
    }

    private var pressurePosition: CGFloat {
        switch store.snapshot.totals.memoryPressure {
        case .normal: return 0.18
        case .warning: return 0.5
        case .critical: return 0.85
        }
    }

    private var processHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Processes").font(.headline)
            TextField("Search", text: $store.searchText)
                .textFieldStyle(.roundedBorder)
            HStack {
                Text("Process Name")
                Spacer()
                Text("Memory footprint")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var emptyProcesses: some View {
        Text(store.hasReadProcesses ? "No matching processes" : "Reading processes\u{2026}")
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private func processRow(_ process: MemoryProcess) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(process.name)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 8)
            Text(MemoryFormat.footprint(process.footprintBytes))
                .font(.callout)
                .monospacedDigit()
                .foregroundColor(process.footprintBytes == nil ? .secondary : .primary)
        }
        .padding(.vertical, 1)
    }

    private var footer: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Live processes \u{00B7} Updated \(store.lastUpdated.formatted(date: .omitted, time: .standard))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                Text(footerNote)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Refresh") { store.refresh(forceTopSample: true) }
            Button("Quit") { NSApp.terminate(nil) }
        }
        .padding(8)
    }

    private var footerNote: String {
        store.sizesAreApproximate
            ? "Totals are sample data \u{00B7} Sizes approximate"
            : "Totals are sample data"
    }
}
