import CryptoKit
import Foundation

/// Story 1.4: gentler alarms while the owner is already in a meeting. A meeting they popped (joined, or cleared with
/// a pop) that is still running at the next alarm's ring time means they're in it, on this phone or another device:
/// the full-screen alarm still shows, but with a quieter sound. Once that meeting ends, alarms are normal again.
/// The alarm is never skipped or silenced: quieter ringing must never cost a missed meeting.
enum InMeetingRule {
    /// The quieter alarm sound (scripts/make_quiet_alarm.py: the recorded pops at a quarter of the level).
    static let quietSoundFile = "quiet_alarm.wav"
    /// Pop In's own ring while it's open, at the same quarter level.
    static let quietVolume: Float = 0.25

    /// True when one of the popped meetings is running at `ring`.
    static func isInMeeting(at ring: Date, popped: [Meeting]) -> Bool {
        popped.contains { $0.start <= ring && ring < $0.end }
    }

    /// The meetings that count as "in": cleared with a pop, not skipped with Not going.
    static func popped(_ meetings: [Meeting], cleared: Set<String>, skipped: Set<String>) -> [Meeting] {
        meetings.filter { cleared.contains($0.id) && !skipped.contains($0.id) }
    }

    /// A quiet alarm gets its own ID, so switching between quiet and normal replaces the scheduled alarm (iOS can't
    /// change a scheduled alarm's sound).
    static func quietID(_ id: UUID) -> UUID {
        var b = Array(SHA256.hash(data: Data((id.uuidString + "|quiet").utf8)).prefix(16))
        b[6] = (b[6] & 0x0F) | 0x50
        b[8] = (b[8] & 0x3F) | 0x80
        return UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
                           b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))
    }

    /// The alarms to schedule, with those ringing during a popped meeting swapped for their quiet versions, and the
    /// set of quiet IDs.
    /// `except` keeps alarms that must keep their ID (test and snooze alarms, which the service protects by ID).
    static func apply(_ alarms: [PlannedAlarm], popped: [Meeting], except: Set<UUID> = []) -> (alarms: [PlannedAlarm], quiet: Set<UUID>) {
        var quiet: Set<UUID> = []
        let out = alarms.map { a -> PlannedAlarm in
            guard !except.contains(a.id), isInMeeting(at: a.fireDate, popped: popped.filter { $0.id != a.meeting.id }) else { return a }
            let q = PlannedAlarm(id: quietID(a.id), meeting: a.meeting, fireDate: a.fireDate, countdownSeconds: a.countdownSeconds)
            quiet.insert(q.id)
            return q
        }
        return (out, quiet)
    }
}
