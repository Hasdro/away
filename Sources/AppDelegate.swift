import AppKit
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let prefs = Prefs.shared
    private var schedule: BreakSchedule!
    private let overlay = BreakOverlay()
    private var statusItem: NSStatusItem!
    private var transitionTimer: Timer?
    private var titleTimer: Timer?
    private var settingsWindow: NSWindow?
    private var chime: NSSound?
    private var previewing = false
    private var previewWork: DispatchWorkItem?
    private var lastTitle: String? = ""
    private var quitAfterPreview = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A menu-bar app has no windows most of the time; without this macOS may
        // reap it as soon as a break hands focus back to another app.
        ProcessInfo.processInfo.disableAutomaticTermination("Away lives in the menu bar")

        let prefs = self.prefs
        // --no-idle is a test hook: it keeps breaks firing while the machine is
        // otherwise untouched.
        let idle: () -> TimeInterval = CommandLine.arguments.contains("--no-idle")
            ? { 0 }
            : systemIdleSeconds
        schedule = BreakSchedule(rules: { prefs.rules }, idle: idle)
        schedule.onChange = { [weak self] in self?.sync() }

        setUpStatusItem()
        NotificationCenter.default.addObserver(
            self, selector: #selector(prefsChanged), name: .prefsChanged, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(woke), name: NSWorkspace.didWakeNotification, object: nil
        )
        sync()

        if CommandLine.arguments.contains("--preview-short") {
            quitAfterPreview = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.previewBreak(.short)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        transitionTimer?.invalidate()
        titleTimer?.invalidate()
    }

    // MARK: - Status item

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = StatusIcon.eye()
            button.imagePosition = .imageLeading
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
            button.toolTip = "Away"
        }
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
    }

    private func updateStatus() {
        guard let button = statusItem.button, let schedule else { return }
        button.appearsDisabled = schedule.phase == .paused

        let title = countdownTitle()
        if title != lastTitle {
            lastTitle = title
            button.title = title ?? ""
            button.imagePosition = title == nil ? .imageOnly : .imageLeading
        }
        button.toolTip = tooltip()
    }

    private func countdownTitle() -> String? {
        guard prefs.showCountdown, schedule.phase == .working else { return nil }
        let remaining = schedule.remaining
        if remaining >= 60 { return "\(Int(ceil(remaining / 60)))m" }
        return "\(Int(ceil(remaining)))s"
    }

    private func tooltip() -> String {
        switch schedule.phase {
        case .working:
            return "Away — next break in \(Int(ceil(schedule.remaining / 60))) min"
        case .shortBreak:
            return "Away — short break, \(clockText(schedule.remaining)) left"
        case .longBreak:
            return "Away — long break, \(clockText(schedule.remaining)) left"
        case .paused:
            return "Away — paused"
        }
    }

    private func updateTitleTimer() {
        let needed = prefs.showCountdown && schedule.phase == .working
        if needed, titleTimer == nil {
            let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                self?.updateStatus()
            }
            timer.tolerance = 0.2
            RunLoop.main.add(timer, forMode: .common)
            titleTimer = timer
        } else if !needed, let titleTimer {
            titleTimer.invalidate()
            self.titleTimer = nil
        }
    }

    // MARK: - Scheduling

    private func sync() {
        guard schedule != nil else { return }
        updateStatus()
        armTransitionTimer()
        updateTitleTimer()

        guard !previewing else { return }
        if schedule.phase.isBreak, !overlay.isVisible {
            presentBreak()
        } else if !schedule.phase.isBreak, overlay.isVisible {
            overlay.hide()
        }
    }

    private func armTransitionTimer() {
        transitionTimer?.invalidate()
        let delta = max(0.1, schedule.deadline.timeIntervalSinceNow)
        let timer = Timer(timeInterval: delta, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.schedule.tick()
            self.sync()
        }
        timer.tolerance = min(1.5, max(0.05, delta * 0.02))
        RunLoop.main.add(timer, forMode: .common)
        transitionTimer = timer
    }

    private func presentBreak() {
        guard let schedule else { return }
        let kind: BreakKind = schedule.phase == .longBreak ? .long : .short
        let total = kind.isLong ? prefs.rules.longDuration : prefs.rules.shortDuration
        if prefs.sound { playChime() }
        overlay.show(
            kind: kind,
            total: total,
            strict: prefs.strict,
            deadline: schedule.deadline,
            onSkip: { [weak self] in
                guard let self, self.schedule.skip() else { return }
                self.sync()
            }
        )
    }

    private func previewBreak(_ kind: BreakKind) {
        previewing = true
        previewWork?.cancel()
        let total: TimeInterval = 8
        if prefs.sound { playChime() }
        overlay.show(
            kind: kind,
            total: total,
            strict: false,
            deadline: Date().addingTimeInterval(total),
            onSkip: { [weak self] in self?.endPreview() }
        )
        let work = DispatchWorkItem { [weak self] in self?.endPreview() }
        previewWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + total, execute: work)
    }

    private func endPreview() {
        previewWork?.cancel()
        previewWork = nil
        previewing = false
        overlay.hide()
        sync()
        if quitAfterPreview {
            NSApp.terminate(nil)
        }
    }

    private func playChime() {
        if chime == nil {
            chime = NSSound(named: NSSound.Name("Tink"))
            chime?.volume = 0.35
        }
        chime?.stop()
        chime?.play()
    }

    // MARK: - Notifications

    @objc private func prefsChanged() {
        schedule.rulesChanged()
        sync()
    }

    @objc private func woke() {
        schedule.handleWake()
        sync()
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let header = NSMenuItem(title: headerText(), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        if schedule.phase == .paused {
            menu.addItem(item("Resume", #selector(resumeSchedule), ""))
        } else {
            let breakNow = NSMenuItem(title: "Break now", action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            submenu.addItem(item("Short break", #selector(shortBreakNow), ""))
            submenu.addItem(item("Long break", #selector(longBreakNow), ""))
            breakNow.submenu = submenu
            menu.addItem(breakNow)

            let pause = NSMenuItem(title: "Pause", action: nil, keyEquivalent: "")
            let pauseMenu = NSMenu()
            for (title, minutes) in [("15 minutes", 15), ("30 minutes", 30), ("1 hour", 60), ("2 hours", 120)] {
                let pauseItem = NSMenuItem(title: title, action: #selector(pauseFor(_:)), keyEquivalent: "")
                pauseItem.target = self
                pauseItem.tag = minutes
                pauseMenu.addItem(pauseItem)
            }
            pause.submenu = pauseMenu
            menu.addItem(pause)
        }

        menu.addItem(.separator())
        let strict = item("Strict mode", #selector(toggleStrict), "")
        strict.state = prefs.strict ? .on : .off
        menu.addItem(strict)

        menu.addItem(.separator())
        menu.addItem(item("Settings…", #selector(openSettings), ","))
        menu.addItem(item("Quit Away", #selector(quit), "q"))
    }

    private func item(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func headerText() -> String {
        switch schedule.phase {
        case .working:
            let minutes = max(1, Int(ceil(schedule.remaining / 60)))
            let kind = schedule.nextKind.isLong ? "Long break" : "Short break"
            return "\(kind) in \(minutes) min"
        case .shortBreak:
            return "Short break · \(clockText(schedule.remaining))"
        case .longBreak:
            return "Long break · \(clockText(schedule.remaining))"
        case .paused:
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return "Paused until \(formatter.string(from: schedule.deadline))"
        }
    }

    // MARK: - Actions

    @objc private func shortBreakNow() { schedule.breakNow(.short) }
    @objc private func longBreakNow() { schedule.breakNow(.long) }
    @objc private func pauseFor(_ sender: NSMenuItem) { schedule.pause(for: TimeInterval(sender.tag * 60)) }
    @objc private func resumeSchedule() { schedule.resume() }
    @objc private func toggleStrict() { prefs.strict.toggle() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let actions = SettingsActions(
                preview: { [weak self] kind in self?.previewBreak(kind) },
                loginItemEnabled: { SMAppService.mainApp.status == .enabled },
                setLoginItem: { enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                        return nil
                    } catch {
                        return error.localizedDescription
                    }
                }
            )
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 706),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Away"
            window.contentView = NSHostingView(rootView: SettingsView(prefs: prefs, actions: actions))
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
