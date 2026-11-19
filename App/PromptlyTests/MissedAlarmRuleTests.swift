import XCTest
@testable import Promptly

/// Story 1.2 (docs/roadmap.md): a missed alarm keeps ringing until it's dismissed, a later ringing meeting reaches
/// its ring time, or the meeting ends. Simulated mornings with a 2-minute lead.
final class MissedAlarmRuleTests: XCTestCase {
    private let day = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_800_000_000))!
    private func at(_ h: Int, _ m: Int) -> Date { day.addingTimeInterval(TimeInterval((h - 8) * 3600 + m * 60)) }
    private func meeting(_ id: String, _ h: Int, _ m: Int, minutes: Int = 30) -> Meeting {
        Meeting(id: id, eventID: id, title: id, start: at(h, m), end: at(h, m).addingTimeInterval(TimeInterval(minutes * 60)),
                calendarID: "work", joinURL: nil)
    }
    private func ring(_ m: Meeting) -> Date { m.start.addingTimeInterval(-120) }
    private func later(_ ms: Meeting...) -> [MissedAlarmRule.Later] { ms.map { .init(meeting: $0, ringTime: ring($0)) } }
    private let always: (Meeting) -> Bool = { _ in true }

    /// No repeat may still be sounding at the stop time.
    private func assertQuietAtStop(_ repeats: [Date], stop: Date, file: StaticString = #filePath, line: UInt = #line) {
        for r in repeats {
            XCTAssertLessThanOrEqual(r.addingTimeInterval(MissedAlarmRule.alertLength), stop, "repeat at \(r) still sounds at \(stop)",
                                     file: file, line: line)
        }
    }

    /// Back-to-back: 10:00 to 10:30, then 10:30. The first stops at the second's ring time, 10:28.
    func testBackToBackHandsOverAtTheNextRingTime() {
        let a = meeting("a", 10, 0), b = meeting("b", 10, 30)
        let stop = MissedAlarmRule.stopTime(for: a, firstRing: ring(a), later: later(b), rings: always)
        XCTAssertEqual(stop, at(10, 28))
        let repeats = MissedAlarmRule.repeats(firstRing: ring(a), stop: stop, dismissed: false)
        XCTAssertFalse(repeats.isEmpty)
        assertQuietAtStop(repeats, stop: stop)
        XCTAssertTrue(MissedAlarmRule.shouldRing(firstRing: ring(a), stop: stop, dismissed: false, now: at(10, 27)))
        XCTAssertFalse(MissedAlarmRule.shouldRing(firstRing: ring(a), stop: stop, dismissed: false, now: at(10, 28)))
    }

    /// With no later meeting, the alarm stops when its meeting ends (Graham, 2026-11-19).
    func testStopsWhenTheMeetingEnds() {
        let a = meeting("a", 10, 0), b = meeting("b", 11, 0)
        let stop = MissedAlarmRule.stopTime(for: a, firstRing: ring(a), later: later(b), rings: always)
        XCTAssertEqual(stop, a.end)
        XCTAssertEqual(MissedAlarmRule.stopTime(for: a, firstRing: ring(a), later: [], rings: always), a.end)
        assertQuietAtStop(MissedAlarmRule.repeats(firstRing: ring(a), stop: stop, dismissed: false), stop: stop)
    }

    /// Two meetings in the same minute share one alarm and follow the rule as one.
    func testSameMinuteMeetingsShareOneAlarm() {
        let a = meeting("a", 10, 0), b = meeting("b", 10, 0, minutes: 60)
        let plan = AlarmPlanner.plan(meetings: [a, b], leadMinutes: 2, now: at(9, 0), cleared: [])
        XCTAssertEqual(plan.count, 1)
        let shared = plan[0].meeting
        let stop = MissedAlarmRule.stopTime(for: shared, firstRing: plan[0].fireDate, later: [], rings: always)
        XCTAssertEqual(stop, at(11, 0), "the shared alarm runs to the later end")
    }

    /// Dismissed: no repeats, and it's not ringing, even in the minute of the handover.
    func testDismissPlansNothingMore() {
        let a = meeting("a", 10, 0), b = meeting("b", 10, 30)
        let stop = MissedAlarmRule.stopTime(for: a, firstRing: ring(a), later: later(b), rings: always)
        XCTAssertTrue(MissedAlarmRule.repeats(firstRing: ring(a), stop: stop, dismissed: true).isEmpty)
        XCTAssertFalse(MissedAlarmRule.shouldRing(firstRing: ring(a), stop: stop, dismissed: true, now: at(10, 28)))
    }

    /// A later meeting skipped with Not going, paused or quiet doesn't take over: the earlier alarm runs to its end.
    func testSkippedOrQuietLaterMeetingDoesNotTakeOver() {
        let a = meeting("a", 10, 0), b = meeting("b", 10, 15)
        let stop = MissedAlarmRule.stopTime(for: a, firstRing: ring(a), later: later(b), rings: { $0.id != "b" })
        XCTAssertEqual(stop, a.end)
    }

    /// Only the later meeting's own ring time takes over, not its early heads-up.
    func testHeadsUpDoesNotTakeOver() {
        let a = meeting("a", 10, 0), b = meeting("b", 10, 30)
        // The heads-up would come 10 minutes before b; the caller passes b's own ring time.
        let stop = MissedAlarmRule.stopTime(for: a, firstRing: ring(a), later: later(b), rings: always)
        XCTAssertEqual(stop, ring(b))
        XCTAssertGreaterThan(stop, b.start.addingTimeInterval(-600))
    }

    /// After a snooze, the meeting rings again 2 minutes later and the rule runs from there.
    func testSnoozeRestartsFromTheSnoozeRing() {
        let a = meeting("a", 10, 0)
        let snoozeRing = ring(a).addingTimeInterval(Snooze.length)
        let repeats = MissedAlarmRule.repeats(firstRing: snoozeRing, stop: a.end, dismissed: false)
        XCTAssertEqual(repeats.first, snoozeRing.addingTimeInterval(MissedAlarmRule.alertLength + MissedAlarmRule.regap))
        assertQuietAtStop(repeats, stop: a.end)
    }

    /// A muted alarm rings again within 60 seconds, and repeats stay within the budget.
    func testRepeatsComeBackWithinAMinuteAndAreCapped() {
        XCTAssertLessThanOrEqual(MissedAlarmRule.regap, 60)
        let a = meeting("a", 10, 0, minutes: 240)
        let repeats = MissedAlarmRule.repeats(firstRing: ring(a), stop: a.end, dismissed: false)
        XCTAssertEqual(repeats.count, MissedAlarmRule.maxRepeats)
        for (x, y) in zip([ring(a)] + repeats, repeats) {
            XCTAssertEqual(y.timeIntervalSince(x), MissedAlarmRule.alertLength + MissedAlarmRule.regap, accuracy: 0.001)
        }
    }

    /// Over a whole simulated day of start times and gaps, no repeat is planned to sound into the stop time.
    func testNoRepeatEverSoundsIntoTheStop() {
        for startMinute in stride(from: 0, through: 120, by: 5) {
            for gap in [0, 5, 10, 15, 30, 45, 60, 90] {
                let a = meeting("a", 9, startMinute)
                let b = meeting("b", 9, startMinute + 30 + gap)
                let stop = MissedAlarmRule.stopTime(for: a, firstRing: ring(a), later: later(b), rings: always)
                assertQuietAtStop(MissedAlarmRule.repeats(firstRing: ring(a), stop: stop, dismissed: false), stop: stop)
            }
        }
    }
}
