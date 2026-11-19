import SwiftUI

/// A quick reminder made in Pop In: a few words and a time. It rings like a meeting, with the bubble.
/// Story 8.10: quick time chips, Add only once there's a title, an Edit button to delete, and "this device".
struct AddReminderSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
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
                            EditButton().font(.subheadline.weight(.semibold)).textCase(nil)
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

    /// In 15 min · 30 min · 1 hour · Pick a time. Side by side, or one per row at accessibility sizes.
    @ViewBuilder
    private var chips: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        layout {
            ForEach(ReminderTime.allCases) { option in
                let on = option == choice
                Button { choice = option } label: {
                    Text(option.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(on ? .white : Brand.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
                        .background(Capsule().fill(on ? Brand.ink : Brand.ink.opacity(0.06)))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}
