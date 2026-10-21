import AppKit

enum StatusIcon {
    /// An 18 pt template eye. Tinted by the menu bar, so no colours here.
    static func eye() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            let almond = NSBezierPath()
            almond.move(to: NSPoint(x: 1.6, y: 9))
            almond.curve(
                to: NSPoint(x: 16.4, y: 9),
                controlPoint1: NSPoint(x: 5.4, y: 14.3),
                controlPoint2: NSPoint(x: 12.6, y: 14.3)
            )
            almond.curve(
                to: NSPoint(x: 1.6, y: 9),
                controlPoint1: NSPoint(x: 12.6, y: 3.7),
                controlPoint2: NSPoint(x: 5.4, y: 3.7)
            )
            almond.lineWidth = 1.25
            almond.lineCapStyle = .round
            almond.lineJoinStyle = .round
            NSColor.black.setStroke()
            almond.stroke()

            NSColor.black.setFill()
            NSBezierPath(ovalIn: NSRect(x: 7.2, y: 6.2, width: 3.6, height: 3.6)).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
