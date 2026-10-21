import SwiftUI
import AppKit

enum Theme {
    static let ink = Color(hex: 0x08090B)
    static let paper = Color(hex: 0xF2EDE3)
    static let amber = Color(hex: 0xE7A45C)

    static let paperPrimary = paper.opacity(0.95)
    static let paperBody = paper.opacity(0.72)
    static let paperHint = paper.opacity(0.52)

    static let nsInk = NSColor(srgbRed: 0x08 / 255.0, green: 0x09 / 255.0, blue: 0x0B / 255.0, alpha: 1)
    static let nsAmber = NSColor(srgbRed: 0xE7 / 255.0, green: 0xA4 / 255.0, blue: 0x5C / 255.0, alpha: 1)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
