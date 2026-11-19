import Foundation

/// Story 1.2 (docs/roadmap.md): a missed alarm keeps ringing, at one steady volume, until it's dismissed, a later
/// meeting that rings reaches its own ring time, or the meeting ends. Pure, unit tested; the planner and the
/// AlarmService turn these times into AlarmKit alarms.
///
/// AlarmKit has no setting for how long one alert sounds, and iOS mutes it on its own after `alertLength`. So the
/// ringing is built from repeats: each starts `regap` after the one before goes quiet, and none is planned to still
/// be sounding when the stop time comes (a later alarm that fires over an earlier one can be silenced).
enum MissedAlarmRule {
    /// How long iOS lets one alert sound before muting it. An assumption until Graham's phone check measures it.
    static let alertLength: TimeInterval = 60
    /// A muted alarm rings again this soon (the story says within 60 seconds).
    static let regap: TimeInterval = 30
    /// At most this many future repeats are planned at once, so they fit the planner's budget of alarms. Each sync
    /// tops them up from `now`; if Pop In never runs again, ringing ends after this many.
    static let maxRepeats = 8

    /// A meeting that can take over: its ring time, and whether it would ring.
    struct Later: Equatable {
        var meeting: Meeting
        var ringTime: Date
    }

    /// When the missed alarm must be quiet: the earlier of its meeting's end and the ring time of the first later
    /// meeting that rings. A later meeting that is skipped, paused or quiet doesn't take over (the caller leaves it
    /// out of `later`, or `rings` says no). Only a later meeting's own ring time counts, not its early heads-up.
    static func stopTime(for meeting: Meeting, firstRing: Date, later: [Later], rings: (Meeting) -> Bool) -> Date {
        let takeover = later
            .filter { $0.meeting.id != meeting.id && $0.meeting.start > meeting.start && rings($0.meeting) }
            .map(\.ringTime)
            .min()
        return min(meeting.end, takeover ?? meeting.end)
    }

    /// The next repeat ring times after `now`. The first comes `firstRepeatAfter` the first ring (by default when it's
    /// muted plus `regap`; part 2 may start it at the one-minute safety backup), then one every `alertLength + regap`.
    /// None is still sounding at `stop`. Nothing is planned for a dismissed meeting. At most `maxCount` are returned,
    /// counted from `now`, so each sync tops them up.
    static func repeats(firstRing: Date, stop: Date, dismissed: Bool, after now: Date,
                        alertLength: TimeInterval = alertLength, regap: TimeInterval = regap,
                        firstRepeatAfter: TimeInterval? = nil, maxCount: Int = maxRepeats) -> [Date] {
        guard !dismissed, alertLength > 0 else { return [] }
        let step = alertLength + regap
        var out: [Date] = []
        var next = firstRing.addingTimeInterval(firstRepeatAfter ?? step)
        while next.addingTimeInterval(alertLength) <= stop, out.count < maxCount {
            if next > now { out.append(next) }
            next = next.addingTimeInterval(step)
        }
        return out
    }

    /// True when the first alert itself may still be sounding at the stop time (an alert longer than the time to the
    /// handover). Only Pop In, running, can stop it then; the phone check covers it.
    static func firstRingOverlaps(firstRing: Date, stop: Date, alertLength: TimeInterval = alertLength) -> Bool {
        firstRing.addingTimeInterval(alertLength) > stop
    }

    /// True while the missed alarm should be ringing at `now` (used by the in-app watcher, which can stop the alarm
    /// itself at the handover).
    static func shouldRing(firstRing: Date, stop: Date, dismissed: Bool, now: Date) -> Bool {
        !dismissed && now >= firstRing && now < stop
    }
}
