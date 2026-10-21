import AppKit
import SwiftUI

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// One borderless window per display, above every space including full-screen
/// apps. Windows are built once and reused: closing them at the end of a break
/// while the app hands focus back trips an AppKit teardown crash.
final class BreakOverlay {
    private let model = BreakModel()
    private var windows: [OverlayWindow] = []
    // Retained on purpose. Closing an overlay window at the moment the app hands
    // focus back can crash AppKit's window-animation cleanup. This only grows
    // when the display layout changes during a break.
    private var retired: [OverlayWindow] = []
    private var monitor: Any?
    private var ticker: Timer?
    private var previousApp: NSRunningApplication?
    private var onSkip: (() -> Void)?
    private(set) var isVisible = false

    func show(
        kind: BreakKind,
        total: TimeInterval,
        strict: Bool,
        deadline: Date,
        onSkip: @escaping () -> Void
    ) {
        previousApp = NSWorkspace.shared.frontmostApplication
        self.onSkip = onSkip
        model.kind = kind
        model.total = total
        model.strict = strict
        model.deadline = deadline
        model.now = Date()

        buildWindowsIfNeeded()
        for window in windows {
            window.orderFrontRegardless()
        }
        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKey()
        installMonitor()
        startTicker()
        isVisible = true
    }

    func hide(returnFocus: Bool = true) {
        ticker?.invalidate()
        ticker = nil
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        for window in windows {
            window.orderOut(nil)
        }
        onSkip = nil
        isVisible = false

        if returnFocus, let previousApp,
           previousApp.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            previousApp.activate(options: [])
        }
        previousApp = nil
    }

    private func buildWindowsIfNeeded() {
        let screens = NSScreen.screens
        let matches = windows.count == screens.count
            && zip(windows, screens).allSatisfy { $0.frame == $1.frame }
        guard !matches else { return }

        for window in windows {
            window.orderOut(nil)
        }
        retired.append(contentsOf: windows)
        windows.removeAll()

        for screen in screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.backgroundColor = .black
            window.isOpaque = true
            window.hasShadow = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.contentView = NSHostingView(rootView: BreakView(model: model))
            window.setFrame(screen.frame, display: false)
            windows.append(window)
        }
    }

    /// The break window sits above every app, and SwiftUI's TimelineView does
    /// not tick there. A run-loop timer does.
    private func startTicker() {
        ticker?.invalidate()
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.model.now = Date()
        }
        timer.tolerance = 0.05
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func installMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.modifierFlags.contains(.command) {
                if event.charactersIgnoringModifiers?.lowercased() == "q" {
                    NSApp.terminate(nil)
                }
                return nil
            }
            if event.keyCode == 53 {
                self.onSkip?()
            }
            return nil
        }
    }
}
