import CoreGraphics
import Foundation

/// Seconds since the last keyboard, mouse, or trackpad event, system-wide.
/// `kCGAnyInputEventType` needs no Accessibility permission — it is a query, not
/// an event tap.
func systemIdleSeconds() -> TimeInterval {
    guard let anyInput = CGEventType(rawValue: ~0) else { return 0 }
    return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
}
