import AppKit

enum BarsRenderer {
    static let barWidth: CGFloat = 4
    static let gap: CGFloat = 3
    static let height: CGFloat = 16

    static func image(colors: [NSColor]) -> NSImage {
        let count = max(colors.count, 1)
        let width = CGFloat(count) * barWidth + CGFloat(count - 1) * gap + 2
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { _ in
            for (index, color) in colors.enumerated() {
                let x = 1 + CGFloat(index) * (barWidth + gap)
                let rect = NSRect(x: x, y: 1, width: barWidth, height: height - 2)
                color.setFill()
                NSBezierPath(roundedRect: rect, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
            }
            return true
        }
        image.isTemplate = false
        return image
    }
}
