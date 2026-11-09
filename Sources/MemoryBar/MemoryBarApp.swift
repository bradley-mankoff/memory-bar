import SwiftUI

@main
struct MemoryBarApp: App {
    @StateObject private var store = MemoryStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView(store: store)
        } label: {
            Image(nsImage: BarLabelImage.make(text: store.barLabel, color: store.barColor))
        }
        .menuBarExtraStyle(.window)
    }
}
