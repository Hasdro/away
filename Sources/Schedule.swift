import Foundation

struct Rules {
    var shortInterval: TimeInterval
    var shortDuration: TimeInterval
    var longDuration: TimeInterval
    var breaksPerLong: Int
    var strict: Bool
}

enum BreakKind {
    case short
    case long

    var isLong: Bool { self == .long }
}

enum Phase {
    case working
    case shortBreak
    case longBreak
    case paused

    var isBreak: Bool { self == .shortBreak || self == .longBreak }
}

/// Pure break logic. No timers, no AppKit, no UI: the app pumps `tick()` and the
/// tests pump it with a fake clock.
final class BreakSchedule {
    private(set) var phase: Phase = .working
    private(set) var deadline: Date
    private(set) var shortCount = 0

    var onChange: (() -> Void)?

    private let rules: () -> Rules
    private let now: () -> Date
    private let idle: () -> TimeInterval
    private var resumeRemaining: TimeInterval?
    private var scheduledInterval: TimeInterval

    init(
        rules: @escaping () -> Rules,
        now: @escaping () -> Date = Date.init,
        idle: @escaping () -> TimeInterval = { 0 }
    ) {
        self.rules = rules
        self.now = now
        self.idle = idle
        self.scheduledInterval = rules().shortInterval
        self.deadline = now().addingTimeInterval(scheduledInterval)
    }

    var remaining: TimeInterval {
        max(0, deadline.timeIntervalSince(now()))
    }

    var nextKind: BreakKind {
        shortCount >= rules().breaksPerLong ? .long : .short
    }

    func tick() {
        guard now() >= deadline else { return }
        switch phase {
        case .working:
            beginDueBreak()
        case .shortBreak, .longBreak:
            finishBreak()
        case .paused:
            resume()
        }
    }

    /// Esc. Returns false when strict mode forbids it.
    @discardableResult
    func skip() -> Bool {
        guard phase.isBreak, !rules().strict else { return false }
        finishBreak()
        return true
    }

    func breakNow(_ kind: BreakKind) {
        guard phase == .working else { return }
        let duration = kind.isLong ? rules().longDuration : rules().shortDuration
        phase = kind.isLong ? .longBreak : .shortBreak
        deadline = now().addingTimeInterval(duration)
        onChange?()
    }

    func pause(for seconds: TimeInterval) {
        guard phase == .working else { return }
        resumeRemaining = remaining
        phase = .paused
        deadline = now().addingTimeInterval(seconds)
        onChange?()
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .working
        deadline = now().addingTimeInterval(resumeRemaining ?? rules().shortInterval)
        scheduledInterval = rules().shortInterval
        resumeRemaining = nil
        onChange?()
    }

    /// Sleep is rest. Coming back to a deadline that passed long ago should not
    /// fire a stale break.
    func handleWake() {
        guard phase == .working else {
            tick()
            return
        }
        if now().timeIntervalSince(deadline) > 60 {
            startWorking(interval: rules().shortInterval)
        } else {
            tick()
        }
    }

    /// Restart the work interval only when the interval itself changed.
    func rulesChanged() {
        guard phase == .working else { return }
        let interval = rules().shortInterval
        guard interval != scheduledInterval else { return }
        scheduledInterval = interval
        deadline = now().addingTimeInterval(interval)
        onChange?()
    }

    private func beginDueBreak() {
        let current = rules()
        let kind = nextKind
        let duration = kind.isLong ? current.longDuration : current.shortDuration

        // Away long enough that the eyes already rested: bank the break. A pause
        // in typing is not a rest, so short breaks still need a real absence.
        if idle() >= max(duration, 90) {
            count(kind)
            startWorking(interval: current.shortInterval)
            return
        }

        phase = kind.isLong ? .longBreak : .shortBreak
        deadline = now().addingTimeInterval(duration)
        onChange?()
    }

    private func finishBreak() {
        if phase == .shortBreak {
            count(.short)
        } else if phase == .longBreak {
            count(.long)
        }
        startWorking(interval: rules().shortInterval)
    }

    private func startWorking(interval: TimeInterval) {
        phase = .working
        scheduledInterval = interval
        deadline = now().addingTimeInterval(interval)
        onChange?()
    }

    private func count(_ kind: BreakKind) {
        shortCount = kind.isLong ? 0 : shortCount + 1
    }
}
