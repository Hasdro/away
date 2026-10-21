import SwiftUI

func clockText(_ time: TimeInterval) -> String {
    let seconds = Int(ceil(max(0, time)))
    return String(format: "%d:%02d", seconds / 60, seconds % 60)
}

final class BreakModel: ObservableObject {
    @Published var kind: BreakKind = .short
    @Published var total: TimeInterval = 20
    @Published var strict = false
    @Published var deadline = Date()
    @Published var now = Date()

    func remaining() -> TimeInterval {
        max(0, deadline.timeIntervalSince(now))
    }
}

/// The break surface. The amber hairline is both the horizon and the progress:
/// it recedes to the centre as the break runs out.
struct BreakView: View {
    @ObservedObject var model: BreakModel

    var body: some View {
        GeometryReader { geo in
            content(size: geo.size, left: model.remaining())
        }
        .background(Theme.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func content(size: CGSize, left: TimeInterval) -> some View {
        let horizon = size.height * 0.64
        let progress = model.total > 0 ? min(1, max(0, left / model.total)) : 0
        let timerSize: CGFloat = min(120, max(76, size.height * 0.115))

        return ZStack(alignment: .topLeading) {
            Theme.ink

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Theme.amber.opacity(0.07), location: 0.6),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: size.width, height: 280)
            .position(x: size.width / 2, y: horizon - 40)

            Rectangle()
                .fill(Theme.amber.opacity(0.85))
                .frame(width: max(0, size.width * progress), height: 1)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.06),
                            .init(color: .black, location: 0.94),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .position(x: size.width / 2, y: horizon)

            Text(clockText(left))
                .font(.system(size: timerSize, weight: .ultraLight, design: .default))
                .monospacedDigit()
                .tracking(-timerSize * 0.012)
                .foregroundStyle(Theme.paperPrimary)
                .position(x: size.width / 2, y: horizon - timerSize * 0.62)

            Text(instruction)
                .font(.system(size: 19, weight: .regular))
                .tracking(0.2)
                .foregroundStyle(Theme.paperBody)
                .position(x: size.width / 2, y: horizon + 42)

            Text(hint)
                .font(.system(size: 12, weight: .medium))
                .tracking(0.4)
                .foregroundStyle(model.strict ? Theme.amber.opacity(0.8) : Theme.paperHint)
                .position(x: size.width / 2, y: horizon + 78)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    private var instruction: String {
        model.kind.isLong ? "Stand up. Look out a window." : "Look at something far away."
    }

    private var hint: String {
        model.strict ? "Strict mode. This break runs to the end." : "Esc to skip"
    }

    private var accessibilityLabel: String {
        "Break. \(clockText(model.remaining())) remaining. \(instruction)"
    }
}
