import AppKit
import MemoryCore

extension MemoryColor {
    var nsColor: NSColor {
        switch self {
        case .green: return .systemGreen
        case .yellow: return .systemYellow
        case .red: return .systemRed
        }
    }
}

/// MenuBarExtra draws a Text label as a template and drops its colour, so the
/// bar text is drawn into a non-template image instead. This is the only way
/// the memory colour chosen by MemoryCore reaches the menu bar.
enum BarLabelImage {
    static func make(text: String, color: MemoryColor) -> NSImage {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: color.nsColor,
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let image = NSImage(size: attributed.size(), flipped: false) { _ in
            attributed.draw(at: .zero)
            return true
        }
        image.isTemplate = false
        return image
    }
}
