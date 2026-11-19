import Foundation
import WidgetKit

/// The upcoming meetings, written by the app into the shared App Group for the Home Screen widget.
/// The widget never reads the calendar itself.
struct WidgetSnapshot: Codable, Sendable {
    struct Item: Codable, Hashable, Sendable {
        let id: String
        let title: String
        let start: Date
        let end: Date
        let service: String
        let hasLink: Bool
    }

    var items: [Item]

    static let suite = "group.com.grahamdeno.promptly"
    private static let key = "widgetSnapshot"

    static func load(defaults: UserDefaults? = UserDefaults(suiteName: suite)) -> WidgetSnapshot {
        guard let data = defaults?.data(forKey: key),
              let snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return WidgetSnapshot(items: []) }
        return snap
    }

    func save(defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshot.suite)) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults?.set(data, forKey: Self.key)
        WidgetCenter.shared.reloadTimelines(ofKind: NextMeetingKind.kind)
    }

    /// Meetings that haven't ended by `date`.
    func upcoming(at date: Date) -> [Item] {
        items.filter { $0.end > date }.sorted { $0.start < $1.start }
    }
}

enum NextMeetingKind {
    static let kind = "PromptlyNextMeeting"
}

/// When the widget redraws. Pure, unit tested.
enum WidgetTimeline {
    /// Story 9.1: one entry a minute, on the minute before the start (so "8 min" turns to "7 min" on time), then the
    /// start and the end. No ticking seconds. If `maxEntries` cuts the minutes short, the list ends there (no start or
    /// end) and the timeline reloads at its end.
    static func entryDates(now: Date, start: Date?, end: Date?, maxEntries: Int = 90) -> [Date] {
        guard let start, let end, end > now else { return [now] }
        var dates: [Date] = [now]
        if start > now {
            // Minutes before the start, nearest to now first, at whole minutes from the start.
            var k = Int((start.timeIntervalSince(now) / 60).rounded(.down))
            while k >= 1, dates.count < maxEntries {
                let t = start.addingTimeInterval(-TimeInterval(k * 60))
                if t > now { dates.append(t) }
                k -= 1
            }
            // Capped before the start: end the timeline at the last minute, so `.atEnd` reloads there instead of
            // holding a stale count until the meeting.
            if k >= 1 { return Array(Set(dates.filter { $0 >= now })).sorted() }
        }
        dates.append(start)
        dates.append(end)
        return Array(Set(dates.filter { $0 >= now })).sorted()
    }

    /// The bubble's growth over the last hour, 0 to 1 (same curve as the app).
    static func progress(now: Date, start: Date) -> Double {
        let remaining = start.timeIntervalSince(now)
        guard remaining > 0 else { return 1 }
        return min(1, max(0, 1 - remaining / 3600))
    }

    /// Opens Promptly and pops this meeting's bubble there.
    static func popURL(meetingID: String) -> URL? {
        var c = URLComponents()
        c.scheme = "promptly"
        c.host = "pop"
        c.queryItems = [URLQueryItem(name: "id", value: meetingID)]
        return c.url
    }
}

/// The count as the app writes it: "8" "min", "2 h" "05", "3" "days", "Now". Shared by Home and the widgets (9.1).
enum CountText {
    static func parts(now: Date, start: Date) -> (big: String, unit: String) {
        let seconds = Int(start.timeIntervalSince(now).rounded(.up))
        if seconds <= 0 { return ("Now", "") }
        let minutes = Int((Double(seconds) / 60).rounded(.up))
        if minutes < 60 { return ("\(minutes)", "min") }
        let hours = minutes / 60
        if hours < 24 { return ("\(hours) h", String(format: "%02d", minutes % 60)) }
        let days = hours / 24
        return ("\(days)", days == 1 ? "day" : "days")
    }

    /// The short form for the Dynamic Island: "8m", "2h", "3d", "Now".
    static func short(now: Date, start: Date) -> String {
        let seconds = Int(start.timeIntervalSince(now).rounded(.up))
        if seconds <= 0 { return "Now" }
        let minutes = Int((Double(seconds) / 60).rounded(.up))
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }
}
