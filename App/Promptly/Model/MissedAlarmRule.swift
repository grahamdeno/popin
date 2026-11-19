import CryptoKit
import Foundation

/// Story 1.2 (docs/roadmap.md): a missed alarm keeps ringing, at one steady volume, until it's dismissed, a later
/// meeting that rings reaches its own ring time, or the meeting ends. Pure, unit tested; the planner and the
/// AlarmService turn these times into AlarmKit alarms.
///
/// AlarmKit has no setting for how long one alert sounds, and iOS mutes it on its own after `alertLength`. So the
/// ringing is built from repeats: each starts `regap` after the one before goes quiet, and none is planned to still
/// be sounding when the stop time comes (a later alarm that fires over an earlier one can be silenced).
enum MissedAlarmRule {
    /// How long iOS lets one alert sound before muting it: about 15 minutes, like the Clock app (roadmap story 1.2).
    static let alertLength: TimeInterval = 15 * 60
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

    /// A meeting that rings fully, and when it first rang (or will): its ring time, or its snooze ring.
    struct Anchor: Equatable, Sendable {
        var meeting: Meeting
        var firstRing: Date
    }

    /// Story 1.2 part 2: the repeat alarms to schedule now. Same-minute meetings share one chain (as they share one
    /// alarm). Each chain stops at its meeting's end or the next anchor's first ring, whichever is first, with no
    /// repeat still sounding then (the quiet gap Graham chose). Dismissed meetings get none. Soonest first, at most
    /// `budget` (first rings are planned before any repeats, so repeats never crowd one out).
    static func repeatAlarms(anchors: [Anchor], dismissed: Set<String>, now: Date, budget: Int) -> [PlannedAlarm] {
        guard budget > 0 else { return [] }
        // Merge anchors that ring in the same minute, as the planner merges their alarms.
        var merged: [Anchor] = []
        for a in anchors.sorted(by: { $0.firstRing < $1.firstRing }) {
            if let last = merged.last, abs(last.firstRing.timeIntervalSince(a.firstRing)) < 60 {
                let m = last.meeting
                merged[merged.count - 1].meeting = Meeting(id: m.id, eventID: m.eventID, title: "\(m.title) + \(a.meeting.title)",
                                                           start: min(m.start, a.meeting.start), end: max(m.end, a.meeting.end),
                                                           calendarID: m.calendarID, joinURL: m.joinURL ?? a.meeting.joinURL)
            } else {
                merged.append(a)
            }
        }
        var out: [PlannedAlarm] = []
        for (i, a) in merged.enumerated() {
            let later = merged[(i + 1)...].map { Later(meeting: $0.meeting, ringTime: $0.firstRing) }
            let stop = stopTime(for: a.meeting, firstRing: a.firstRing, later: later, rings: { _ in true })
            let isDismissed = dismissed.contains(a.meeting.id)
            for date in repeats(firstRing: a.firstRing, stop: stop, dismissed: isDismissed, after: now) {
                out.append(PlannedAlarm(id: repeatID(meetingID: a.meeting.id, at: date), meeting: a.meeting,
                                        fireDate: date, countdownSeconds: nil))
            }
        }
        return Array(out.sorted { $0.fireDate < $1.fireDate }.prefix(budget))
    }

    /// The anchors for every meeting still to ring or ringing: open (not cleared, not over), first ring at its snooze
    /// ring if it was snoozed (the chain follows the rules from there), otherwise at its ring time.
    static func anchors(meetings: [Meeting], cleared: Set<String>, snoozeRings: [String: Date], leadMinutes: Int,
                        now: Date) -> [Anchor] {
        meetings.filter { $0.end > now && !cleared.contains($0.id) }.map { m in
            Anchor(meeting: m, firstRing: snoozeRings[m.id] ?? m.start.addingTimeInterval(-TimeInterval(leadMinutes * 60)))
        }
    }

    /// Slots kept for the soonest repeats even when first rings fill the budget, so a missed alarm today is never
    /// crowded out by alarms planned for tomorrow.
    static let reservedSlots = 4

    /// What to hand AlarmKit: first rings plus repeats within `limit`. Repeats inside the open window are left out
    /// only for meetings Pop In is showing (its own loop is ringing them); every other repeat stays scheduled, so a
    /// killed Pop In still has Apple's alarms. If the reserved repeats push past the limit, the latest first rings
    /// wait for a later sync.
    static func schedule(firstRings: [PlannedAlarm], anchors: [Anchor], dismissed: Set<String>, now: Date, limit: Int,
                         openUntil: Date?, showing: Set<String>) -> (firstRings: [PlannedAlarm], repeats: [PlannedAlarm]) {
        var candidates = repeatAlarms(anchors: anchors, dismissed: dismissed, now: now, budget: limit)
        if let openUntil {
            candidates = candidates.filter { !($0.scheduleDate <= openUntil && showing.contains($0.meeting.id)) }
        }
        let budget = max(limit - firstRings.count, min(reservedSlots, candidates.count))
        let repeats = Array(candidates.prefix(max(0, min(budget, limit))))
        let kept = Array(firstRings.sorted { $0.scheduleDate < $1.scheduleDate }.prefix(max(0, limit - repeats.count)))
        return (kept, repeats)
    }

    /// The same meeting and time give the same ID, so a re-sync never duplicates a repeat.
    static func repeatID(meetingID: String, at date: Date) -> UUID {
        let key = meetingID + "|repeat|" + String(Int(date.timeIntervalSince1970))
        var b = Array(SHA256.hash(data: Data(key.utf8)).prefix(16))
        b[6] = (b[6] & 0x0F) | 0x50
        b[8] = (b[8] & 0x3F) | 0x80
        return UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
                           b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))
    }
}
