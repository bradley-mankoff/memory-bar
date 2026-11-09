import SwiftUI
import AppKit
import MemoryCore

struct ContentView: View {
    @ObservedObject var store: MemoryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    totalsSection
                    Divider()
                    pressureSection
                    Divider()
                    processSection
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

    private var processSection: some View {
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
            if store.visibleProcesses.isEmpty {
                Text("No matching processes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ForEach(store.visibleProcesses) { process in
                HStack {
                    Text(process.name)
                        .font(.callout)
                        .lineLimit(1)
                    Spacer()
                    Text(MemoryFormat.bytes(process.footprintBytes))
                        .font(.callout)
                        .monospacedDigit()
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Sample data \u{00B7} Updated \(store.lastUpdated.formatted(date: .omitted, time: .standard))")
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
            Spacer()
            Button("Refresh") { store.refresh() }
            Button("Quit") { NSApp.terminate(nil) }
        }
        .padding(8)
    }
}
