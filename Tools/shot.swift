import AppKit
import SwiftUI

/// Dev only: renders the real settings window, native controls included.
@main
struct SettingsShot {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        if CommandLine.arguments.contains("--dark") {
            app.appearance = NSAppearance(named: .darkAqua)
        }

        let output = CommandLine.arguments.dropFirst().first(where: { !$0.hasPrefix("--") }) ?? "settings-window.png"
        let actions = SettingsActions(
            preview: { _ in },
            loginItemEnabled: { false },
            setLoginItem: { _ in nil }
        )
        Prefs.shared.strict = true
        let hosting = NSHostingView(
            rootView: SettingsView(prefs: .shared, actions: actions)
        )
        hosting.frame = NSRect(x: 0, y: 0, width: 440, height: 706)

        let window = NSWindow(
            contentRect: hosting.frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Away"
        window.contentView = hosting
        window.setFrameOrigin(NSPoint(x: 240, y: 240))
        window.orderFront(nil)
        hosting.layoutSubtreeIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let bounds = hosting.bounds
            guard let rep = hosting.bitmapImageRepForCachingDisplay(in: bounds) else {
                print("no bitmap")
                exit(1)
            }
            hosting.cacheDisplay(in: bounds, to: rep)
            guard let png = rep.representation(using: .png, properties: [:]) else {
                print("no png")
                exit(1)
            }
            try? png.write(to: URL(fileURLWithPath: output))
            print("wrote \(output)")
            exit(0)
        }

        app.run()
    }
}
