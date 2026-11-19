import Foundation

/// The quick times on the Add reminder sheet (story 8.10). Pure, unit tested.
enum ReminderTime: String, CaseIterable, Identifiable {
    case in15, in30, in60, pick

    var id: String { rawValue }

    /// What the chip says.
    var label: String {
        switch self {
        case .in15: "In 15 min"
        case .in30: "30 min"
        case .in60: "1 hour"
        case .pick: "Pick a time"
        }
    }

    /// The reminder's time for a quick chip, from `now`. `nil` for "Pick a time", which uses the picker.
    func date(from now: Date) -> Date? {
        switch self {
        case .in15: now.addingTimeInterval(15 * 60)
        case .in30: now.addingTimeInterval(30 * 60)
        case .in60: now.addingTimeInterval(60 * 60)
        case .pick: nil
        }
    }

    /// Add is allowed only once the reminder has words.
    static func canAdd(title: String) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
