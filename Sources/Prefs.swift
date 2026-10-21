import Foundation
import Combine

extension Notification.Name {
    static let prefsChanged = Notification.Name("AwayPrefsChanged")
}

/// UserDefaults-backed settings. Every write persists and posts a change.
final class Prefs: ObservableObject {
    static let shared = Prefs()

    private enum Key {
        static let shortMinutes = "shortMinutes"
        static let shortSeconds = "shortSeconds"
        static let longEvery = "longEvery"
        static let longMinutes = "longMinutes"
        static let strict = "strict"
        static let showCountdown = "showCountdown"
        static let sound = "sound"
    }

    @Published var shortMinutes: Int = 20 { didSet { store() } }
    @Published var shortSeconds: Int = 20 { didSet { store() } }
    @Published var longEvery: Int = 3 { didSet { store() } }
    @Published var longMinutes: Int = 5 { didSet { store() } }
    @Published var strict: Bool = false { didSet { store() } }
    @Published var showCountdown: Bool = false { didSet { store() } }
    @Published var sound: Bool = false { didSet { store() } }

    var rules: Rules {
        Rules(
            shortInterval: TimeInterval(shortMinutes * 60),
            shortDuration: TimeInterval(shortSeconds),
            longDuration: TimeInterval(longMinutes * 60),
            breaksPerLong: longEvery,
            strict: strict
        )
    }

    private let defaults = UserDefaults.standard

    private init() {
        defaults.register(defaults: [
            Key.shortMinutes: 20,
            Key.shortSeconds: 20,
            Key.longEvery: 3,
            Key.longMinutes: 5,
            Key.strict: false,
            Key.showCountdown: false,
            Key.sound: false,
        ])
        shortMinutes = defaults.integer(forKey: Key.shortMinutes)
        shortSeconds = defaults.integer(forKey: Key.shortSeconds)
        longEvery = defaults.integer(forKey: Key.longEvery)
        longMinutes = defaults.integer(forKey: Key.longMinutes)
        strict = defaults.bool(forKey: Key.strict)
        showCountdown = defaults.bool(forKey: Key.showCountdown)
        sound = defaults.bool(forKey: Key.sound)
    }

    private func store() {
        defaults.set(shortMinutes, forKey: Key.shortMinutes)
        defaults.set(shortSeconds, forKey: Key.shortSeconds)
        defaults.set(longEvery, forKey: Key.longEvery)
        defaults.set(longMinutes, forKey: Key.longMinutes)
        defaults.set(strict, forKey: Key.strict)
        defaults.set(showCountdown, forKey: Key.showCountdown)
        defaults.set(sound, forKey: Key.sound)
        NotificationCenter.default.post(name: .prefsChanged, object: nil)
    }
}
