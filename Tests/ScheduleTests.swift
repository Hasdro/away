import Foundation

@main
struct ScheduleTests {
    static var failures = 0
    static var now = Date(timeIntervalSince1970: 1_700_000_000)
    static var idle: TimeInterval = 0
    static var rules = Rules(
        shortInterval: 20 * 60,
        shortDuration: 20,
        longDuration: 300,
        breaksPerLong: 3,
        strict: false
    )

    static func main() {
        schedule()
        idleRule()
        strictMode()
        pause()
        wake()
        skip()
        finish()
    }

    static func makeSchedule() -> BreakSchedule {
        BreakSchedule(rules: { rules }, now: { now }, idle: { idle })
    }

    static func advance(_ seconds: TimeInterval, _ schedule: BreakSchedule) {
        now = now.addingTimeInterval(seconds)
        schedule.tick()
    }

    static func check(_ condition: Bool, _ name: String) {
        if condition {
            print("  ok    \(name)")
        } else {
            print("  FAIL  \(name)")
            failures += 1
        }
    }

    static func schedule() {
        print("schedule")
        let schedule = makeSchedule()
        check(schedule.phase == .working, "starts working")
        advance(20 * 60 - 1, schedule)
        check(schedule.phase == .working, "does not break one second early")
        advance(2, schedule)
        check(schedule.phase == .shortBreak, "short break due at the interval")
        check(abs(schedule.remaining - 20) < 0.01, "short break lasts its duration")
        advance(20, schedule)
        check(schedule.phase == .working && schedule.shortCount == 1, "completion counts and resumes work")

        advance(20 * 60, schedule)
        advance(20, schedule)
        check(schedule.shortCount == 2, "second short break counts")

        advance(20 * 60, schedule)
        check(schedule.phase == .shortBreak, "third break is still short")
        advance(20, schedule)
        advance(20 * 60, schedule)
        check(schedule.phase == .longBreak, "fourth break is long")
        check(abs(schedule.remaining - 300) < 0.01, "long break lasts five minutes")
        advance(300, schedule)
        check(schedule.phase == .working && schedule.shortCount == 0, "long break resets the counter")
    }

    static func idleRule() {
        print("idle")
        idle = 25
        let pausedTyping = makeSchedule()
        advance(20 * 60, pausedTyping)
        check(pausedTyping.phase == .shortBreak, "a short pause in typing does not bank the break")
        advance(20, pausedTyping)

        idle = 120
        let away = makeSchedule()
        advance(20 * 60, away)
        check(away.phase == .working, "two minutes away banks the break")
        check(away.shortCount == 1, "banked break still counts toward the long one")
        idle = 0
    }

    static func strictMode() {
        print("strict")
        rules.strict = true
        let schedule = makeSchedule()
        schedule.breakNow(.short)
        check(schedule.phase == .shortBreak, "break starts")
        check(schedule.skip() == false, "strict refuses to skip")
        check(schedule.phase == .shortBreak, "still on the break after Esc")
        advance(20, schedule)
        check(schedule.phase == .working, "strict break ends on its own")
        rules.strict = false
    }

    static func pause() {
        print("pause")
        let schedule = makeSchedule()
        advance(5 * 60, schedule)
        schedule.pause(for: 30 * 60)
        check(schedule.phase == .paused, "pause takes effect")
        check(abs(schedule.remaining - 30 * 60) < 0.01, "pause runs for its length")
        now = now.addingTimeInterval(31 * 60)
        schedule.tick()
        check(schedule.phase == .working, "resumes after the pause")
        check(abs(schedule.remaining - 15 * 60) < 2, "remaining work time survives the pause")
    }

    static func wake() {
        print("wake")
        let schedule = makeSchedule()
        now = now.addingTimeInterval(40 * 60)
        schedule.handleWake()
        check(schedule.phase == .working, "waking long after a deadline does not fire a stale break")
        check(abs(schedule.remaining - 20 * 60) < 2, "wake starts a fresh interval")
    }

    static func skip() {
        print("skip")
        let schedule = makeSchedule()
        schedule.breakNow(.long)
        check(schedule.skip(), "non-strict skip succeeds")
        check(schedule.phase == .working, "skip returns to work")
        check(schedule.shortCount == 0, "skipping the long break resets the counter")
    }

    static func finish() {
        if failures > 0 {
            print("\n\(failures) failed")
            exit(1)
        }
        print("\nall passed")
    }
}
