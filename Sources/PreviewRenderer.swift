import AppKit
import SwiftUI

/// Dev-only renders of the break surface, reviewed from the command line
/// without screen-recording permission.
@MainActor
enum PreviewRenderer {
    static func render(to directory: String) {
        let dir = URL(fileURLWithPath: directory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let screen = CGSize(width: 1440, height: 900)

        let short = BreakModel()
        short.kind = .short
        short.total = 20
        short.deadline = Date().addingTimeInterval(13)
        write(BreakView(model: short), size: screen, to: dir.appendingPathComponent("break-short.png"))

        let long = BreakModel()
        long.kind = .long
        long.total = 300
        long.strict = true
        long.deadline = Date().addingTimeInterval(217)
        write(BreakView(model: long), size: screen, to: dir.appendingPathComponent("break-long.png"))
    }

    private static func write<V: View>(_ view: V, size: CGSize, to url: URL) {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2
        guard
            let image = renderer.nsImage,
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let png = bitmap.representation(using: .png, properties: [:])
        else {
            print("render failed: \(url.lastPathComponent)")
            return
        }
        try? png.write(to: url)
        print("wrote \(url.path)")
    }
}
