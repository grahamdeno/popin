import Foundation

/// Not going can be taken back until the meeting starts (roadmap item 7.2). App state only: the calendar is never
/// touched. Pure, unit tested.
enum SkipRule {
    /// Skipped meetings that can still be brought back: not started yet, soonest first. `hiding` is the meeting whose
    /// toast is still up (the quiet line takes over once the toast has gone).
    static func restorable(_ meetings: [Meeting], skipped: Set<String>, now: Date, hiding: String? = nil) -> [Meeting] {
        meetings
            .filter { skipped.contains($0.id) && $0.start > now && $0.id != hiding }
            .sorted { $0.start < $1.start }
    }

    /// True until the meeting starts.
    static func canRestore(_ meeting: Meeting, skipped: Set<String>, now: Date) -> Bool {
        skipped.contains(meeting.id) && meeting.start > now
    }

    /// True for a reminder (Pop In's own, or a timed one from Reminders) rather than a meeting.
    static func isReminder(_ meeting: Meeting) -> Bool {
        meeting.calendarID == OwnReminder.calendarID || meeting.calendarID == CalendarService.remindersCalendarID
    }

    /// The skip button's word: "Skip" for a reminder, "Not going" for a meeting (story 8.13).
    static func skipWord(reminder: Bool) -> String { reminder ? "Skip" : "Not going" }

    /// The toast's words: "Not going to Design review", "Skipped Pick up Nora" or "Popped Design review".
    static func toast(title: String, skipped: Bool, reminder: Bool = false) -> String {
        guard skipped else { return "Popped \(title)" }
        return reminder ? "Skipped \(title)" : "Not going to \(title)"
    }

    /// The quiet line once the toast has gone: "Not going: 3:00 PM Design review" or "Skipped: 3:00 PM Pick up Nora".
    static func line(title: String, time: String, reminder: Bool = false) -> String {
        "\(reminder ? "Skipped" : "Not going"): \(time) \(title)"
    }
}
