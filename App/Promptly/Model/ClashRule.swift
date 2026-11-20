import Foundation

/// Story 1.1: catch double-booking before it rings. Only ringing meetings that start in the same minute clash
/// (settled 2026-11-16; partial overlaps don't). Picking one drops the others: they show as a quiet line with Join
/// and get no alarm. Picking never changes the calendar.
enum ClashRule {
    /// Groups of two or more ringing meetings that start in the same minute, soonest first. Each group is in a
    /// stable order (start, then title, then ID).
    static func groups(_ meetings: [Meeting], rings: (Meeting) -> Bool) -> [[Meeting]] {
        let ringing = meetings.filter(rings)
        let byMinute = Dictionary(grouping: ringing) { Int(($0.start.timeIntervalSince1970 / 60).rounded(.down)) }
        return byMinute.values
            .filter { $0.count > 1 }
            .map { $0.sorted { ($0.start, $0.title, $0.id) < ($1.start, $1.title, $1.id) } }
            .sorted { $0[0].start < $1[0].start }
    }

    /// The clash `meeting` is in, if any.
    static func group(for meeting: Meeting, in groups: [[Meeting]]) -> [Meeting]? {
        groups.first { g in g.contains { $0.id == meeting.id } }
    }

    /// The meetings to drop when `picked` is chosen from `group`.
    static func dropped(picking picked: Meeting, from group: [Meeting]) -> Set<String> {
        Set(group.map(\.id)).subtracting([picked.id])
    }

    /// "2 meetings at 1:00 PM · Pick one".
    static func line(count: Int, time: String) -> String { "\(count) meetings at \(time) · Pick one" }

    /// "Not ringing: 1:00 PM Design review", for a meeting dropped by a pick.
    static func droppedLine(title: String, time: String) -> String { "Not ringing: \(time) \(title)" }

    /// Dropped meetings still worth a line on Home: not cleared and not over, soonest first.
    static func droppedLines(_ meetings: [Meeting], dropped: Set<String>, cleared: Set<String>, now: Date) -> [Meeting] {
        meetings.filter { dropped.contains($0.id) && !cleared.contains($0.id) && $0.end > now }.sorted { $0.start < $1.start }
    }
}
