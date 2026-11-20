import SwiftUI

/// Item 10 (D-8): the Alarm group rebuilt as a native Form, only to compare pictures with today's Settings. Reached
/// only from the `formtrial` demo scene; no user ever sees it. Opus and Graham decide from the pictures whether
/// Settings moves to Form.
struct AlarmFormTrial: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        Task { await model.testAlarm(withCountdown: false) }
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Test the alarm").foregroundStyle(Brand.accentText)
                                Text("Rings in 20 seconds, the same way a meeting would")
                                    .font(.footnote).foregroundStyle(Brand.secondary)
                            }
                        } icon: {
                            Image(systemName: "bell.badge").foregroundStyle(Brand.accentText)
                        }
                    }
                    Picker("Sound", selection: Binding(get: { model.alarmSound }, set: { model.alarmSound = $0 })) {
                        ForEach(AlarmSoundChoice.available, id: \.self) { choice in
                            Text(choice.label).tag(choice)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    Toggle(isOn: Binding(get: { model.countdownCard }, set: { model.countdownCard = $0 })) {
                        Text("Lock Screen countdown")
                        Text("The bubble on your Lock Screen before it rings")
                    }
                    Toggle(isOn: Binding(get: { model.nudges }, set: { model.nudges = $0 })) {
                        Text("Heads-up buzzes")
                        Text("One buzz at 5 and at 2 minutes, even when locked")
                    }
                } header: {
                    Text("Alarm")
                } footer: {
                    if let message = model.testMessage { Text(message) }
                }
            }
            .tint(Brand.coralDark)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
