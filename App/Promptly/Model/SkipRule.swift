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

    /// The toast's words: "Not going to Design review" or "Popped Design review".
    static func toast(title: String, skipped: Bool) -> String {
        skipped ? "Not going to \(title)" : "Popped \(title)"
    }

    /// The quiet line once the toast has gone: "Not going: 3:00 PM Design review".
    static func line(title: String, time: String) -> String {
        "Not going: \(time) \(title)"
    }
}
