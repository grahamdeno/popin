import Foundation

/// Work hours: Pop In rings full screen only inside them; outside, meetings get the quiet notification. Pure, tested.
struct WorkHours: Equatable, Sendable {
    var on: Bool
    /// Minutes after midnight.
    var start: Int
    var end: Int
    /// Calendar weekday numbers (1 Sunday ... 7 Saturday).
    var days: Set<Int>

    static let standard = WorkHours(on: false, start: 8 * 60, end: 17 * 60, days: [2, 3, 4, 5, 6])

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard on else { return true }
        let c = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        guard let day = c.weekday, days.contains(day) else { return false }
        let minute = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        return start <= end ? (minute >= start && minute < end) : (minute >= start || minute < end)
    }

    /// "Weekdays 8:00 AM to 5:00 PM", or "Off".
    func summary(calendar: Calendar = .current) -> String {
        guard on else { return "Off" }
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        func time(_ m: Int) -> String {
            f.string(from: calendar.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date(timeIntervalSince1970: 0)) ?? .now)
        }
        let dayText: String
        switch days {
        case [2, 3, 4, 5, 6]: dayText = "Weekdays"
        case Set(1...7): dayText = "Every day"
        default: dayText = days.sorted().map { calendar.veryShortWeekdaySymbols[$0 - 1] }.joined(separator: " ")
        }
        return "\(dayText) \(time(start)) to \(time(end))"
    }
}

/// Pausing alerts for a while (lunch, focus time). Pure, tested.
enum PauseRule {
    /// A meeting starting before the pause ends gets no alarm and no notification.
    static func silences(_ start: Date, pausedUntil: Date?, now: Date) -> Bool {
        guard let pausedUntil, pausedUntil > now else { return false }
        return start < pausedUntil
    }

    /// Until the start of tomorrow.
    static func endOfDay(from now: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: now.addingTimeInterval(24 * 3600))
    }
}

/// Snooze on the alarm screen: ring again a little later.
enum Snooze {
    static let length: TimeInterval = 2 * 60
}

/// Free users can try any Pro theme for one day, once per theme. Pure, tested.
enum ThemeTrial {
    static func active(theme: String, day: String, trialTheme: String?, trialDay: String?) -> Bool {
        trialTheme == theme && trialDay == day
    }

    static func today(_ now: Date = .now) -> String {
        Calendar.current.startOfDay(for: now).formatted(.iso8601.year().month().day())
    }
}

/// The "New this month" card: themes released lately, at most once every four weeks, and not at all for someone
/// who has waved two cards away in a row. Pure, tested.
enum WhatsNew {
    static func shouldShow(new: [String], seen: Set<String>, ignoredInARow: Int, lastShown: Date?, now: Date) -> Bool {
        guard ignoredInARow < 2, new.contains(where: { !seen.contains($0) }) else { return false }
        if let lastShown, now.timeIntervalSince(lastShown) < 28 * 86400 { return false }
        return true
    }
}

/// When an alarm goes unpopped and the next meeting's alarm comes due, the newer meeting takes over: the older one
/// counts as missed. It leaves Home and stops ringing, and the alarm screen mentions it. Pure, tested.
enum NewestWins {
    /// A started meeting is missed once a later ringing meeting has reached its own ring time.
    static func isMissed(_ m: Meeting, among all: [Meeting], now: Date, lead: TimeInterval, rings: (Meeting) -> Bool) -> Bool {
        guard m.start <= now, rings(m) else { return false }
        return all.contains { n in
            n.id != m.id && n.start > m.start && rings(n) && now >= n.start.addingTimeInterval(-lead)
        }
    }
}

extension NewestWins {
    /// Two meetings share an alarm when they start in the same minute (as AlarmPlanner merges them).
    static func sameMinute(_ a: Date, _ b: Date) -> Bool { abs(a.timeIntervalSince(b)) < 60 }

    /// Story 1.3: what clears with the alarm that is ringing: the earlier meetings it took over from (the "Also
    /// missed" line) and ringing meetings in the same minute that share its alarm. Before `current` reaches its own
    /// ring time nothing else clears, so popping one meeting early from Home leaves the others alone.
    static func stack(for current: Meeting, among open: [Meeting], now: Date, lead: TimeInterval,
                      rings: (Meeting) -> Bool) -> [Meeting] {
        guard now >= current.start.addingTimeInterval(-lead) else { return [] }
        return open.filter { m in
            guard m.id != current.id, rings(m) else { return false }
            if sameMinute(m.start, current.start) { return true }
            return m.start < current.start && isMissed(m, among: open, now: now, lead: lead, rings: rings)
        }
        .sorted { $0.start < $1.start }
    }
}

/// Apple's rating prompt, asked once: after someone has popped into a few meetings and come back to Pop In, so the
/// question lands when the app has just worked for them, never while an alarm is ringing or a call is opening.
enum ReviewPrompt {
    static let joinsBeforeAsking = 3
    static func isDue(joins: Int, asked: Bool, alarmShowing: Bool) -> Bool {
        !asked && !alarmShowing && joins >= joinsBeforeAsking
    }
}
