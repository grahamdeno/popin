import SwiftUI

/// A quick reminder made in Pop In: a few words and a time. It rings like a meeting, with the bubble.
/// Story 8.10: quick time chips, Add only once there's a title, an Edit button to delete, and "this device".
struct AddReminderSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var choice: ReminderTime = .in30
    @State private var picked = Date.now.addingTimeInterval(30 * 60)
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("What for? (Pick up Nora)", text: $title)
                    .focused($focused)
                    .submitLabel(.done)
                Section("When") {
                    chips
                    if choice == .pick {
                        DatePicker("Time", selection: $picked, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    }
                }
                Section {
                    ForEach(model.ownReminders) { r in
                        HStack {
                            Text(r.title)
                            Spacer()
                            Text(r.date.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(Brand.secondary)
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets { model.deleteReminder(model.ownReminders[i].id) }
                    }
                } header: {
                    if !model.ownReminders.isEmpty {
                        HStack {
                            Text("Your reminders")
                            Spacer()
                            EditButton()
                                .font(.subheadline.weight(.semibold))
                                .textCase(nil)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(.rect)
                        }
                    }
                } footer: {
                    Text(model.ownReminders.isEmpty
                         ? "Reminders stay on this device and ring like a meeting."
                         : "Reminders stay on this device and ring like a meeting. Tap Edit to delete one.")
                }
            }
            .navigationTitle("New reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        model.addReminder(title: title, at: choice.date(from: .now) ?? picked)
                        dismiss()
                    }
                    .disabled(!ReminderTime.canAdd(title: title))
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium, .large])
    }

    /// In 15 min · 30 min · 1 hour · Pick a time: one row if it fits, else two rows of two, else one per row.
    private var chips: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { ForEach(ReminderTime.allCases) { chip($0) } }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) { chip(.in15); chip(.in30) }
                HStack(spacing: 8) { chip(.in60); chip(.pick) }
            }
            VStack(alignment: .leading, spacing: 8) { ForEach(ReminderTime.allCases) { chip($0) } }
        }
    }

    private func chip(_ option: ReminderTime) -> some View {
        let on = option == choice
        return Button { choice = option } label: {
            Text(option.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(on ? .white : Brand.ink)
                .fixedSize()
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Capsule().fill(on ? Brand.ink : Brand.ink.opacity(0.06)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
