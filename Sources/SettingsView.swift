import SwiftUI

struct SettingsActions {
    var preview: (BreakKind) -> Void
    var loginItemEnabled: () -> Bool
    /// Returns an error message, or nil on success.
    var setLoginItem: (Bool) -> String?
}

struct SettingsView: View {
    @ObservedObject var prefs: Prefs
    let actions: SettingsActions

    @State private var loginOn: Bool
    @State private var loginError: String?

    init(prefs: Prefs, actions: SettingsActions) {
        self.prefs = prefs
        self.actions = actions
        _loginOn = State(initialValue: actions.loginItemEnabled())
    }

    var body: some View {
        Form {
            Section {
                stepperRow("Every", value: $prefs.shortMinutes, range: 1...120, suffix: "min")
                stepperRow("Lasts", value: $prefs.shortSeconds, range: 5...180, suffix: "sec")
            } header: {
                Text("Short breaks")
            }

            Section {
                LabeledContent("Every") {
                    HStack(spacing: 8) {
                        Text("\(prefs.longEvery) short breaks")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Stepper("", value: $prefs.longEvery, in: 2...10)
                            .labelsHidden()
                    }
                }
                stepperRow("Lasts", value: $prefs.longMinutes, range: 1...30, suffix: "min")
            } header: {
                Text("Long breaks")
            }

            Section {
                Toggle(isOn: $prefs.strict) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Strict mode")
                        Text("Skips are off. Every break runs to the end.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle("Show time in the menu bar", isOn: $prefs.showCountdown)
                Toggle("Play a sound when a break starts", isOn: $prefs.sound)
            } header: {
                Text("Behaviour")
            }

            Section {
                Toggle("Open at login", isOn: Binding(
                    get: { loginOn },
                    set: { wanted in
                        if let message = actions.setLoginItem(wanted) {
                            loginError = message
                        } else {
                            loginError = nil
                        }
                        loginOn = actions.loginItemEnabled()
                    }
                ))
                if let loginError {
                    Text(loginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("General")
            } footer: {
                Text("Login items work best when Away lives in Applications.")
            }

            Section {
                HStack(spacing: 10) {
                    Button("Preview short break") { actions.preview(.short) }
                    Button("Preview long break") { actions.preview(.long) }
                }
            } footer: {
                Text("No permissions. No network. \(version)")
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
    }

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(short)"
    }

    private func stepperRow(
        _ label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        suffix: String
    ) -> some View {
        LabeledContent(label) {
            HStack(spacing: 8) {
                Text("\(value.wrappedValue) \(suffix)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Stepper("", value: value, in: range)
                    .labelsHidden()
            }
        }
    }
}
