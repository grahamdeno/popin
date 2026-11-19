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

    /// Back-to-back: 10:00 to 10:30, then 10:30. The first stops at the second's ring time, 10:28. A 15-minute
    /// repeat from 10:13:30 would still sound at 10:28, so none is planned: the quiet gap Graham chose.
    func testBackToBackHandsOverAtTheNextRingTime() {
        let a = meeting("a", 10, 0), b = meeting("b", 10, 30)
        let stop = MissedAlarmRule.stopTime(for: a, firstRing: ring(a), later: later(b), rings: always)
        XCTAssertEqual(stop, at(10, 28))
        let repeats = MissedAlarmRule.repeats(firstRing: ring(a), stop: stop, dismissed: false, after: ring(a))
        XCTAssertTrue(repeats.isEmpty, "a repeat would overlap the next alarm")
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
        assertQuietAtStop(MissedAlarmRule.repeats(firstRing: ring(a), stop: stop, dismissed: false, after: ring(a)), stop: stop)
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
        XCTAssertTrue(MissedAlarmRule.repeats(firstRing: ring(a), stop: stop, dismissed: true, after: ring(a)).isEmpty)
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
        let a = meeting("a", 10, 0, minutes: 120)
        let snoozeRing = ring(a).addingTimeInterval(Snooze.length)
        let repeats = MissedAlarmRule.repeats(firstRing: snoozeRing, stop: a.end, dismissed: false, after: snoozeRing)
        XCTAssertEqual(repeats.first, snoozeRing.addingTimeInterval(MissedAlarmRule.alertLength + MissedAlarmRule.regap))
        assertQuietAtStop(repeats, stop: a.end)
    }

    /// A muted alarm rings again within 60 seconds, all the way to the stop: each sync tops up the next repeats from
    /// now, so a long meeting never goes quiet early while Pop In gets a chance to run.
    func testRepeatsCoverTheWholeMeetingAcrossSyncs() {
        XCTAssertLessThanOrEqual(MissedAlarmRule.regap, 60)
        let a = meeting("a", 10, 0, minutes: 120)
        let step = MissedAlarmRule.alertLength + MissedAlarmRule.regap
        // One sync plans at most the cap, counted from now; an all-day block reaches it.
        let first = MissedAlarmRule.repeats(firstRing: ring(a), stop: a.end, dismissed: false, after: ring(a))
        XCTAssertLessThanOrEqual(first.count, MissedAlarmRule.maxRepeats)
        let long = meeting("long", 10, 0, minutes: 600)
        XCTAssertEqual(MissedAlarmRule.repeats(firstRing: ring(long), stop: long.end, dismissed: false, after: ring(long)).count,
                       MissedAlarmRule.maxRepeats)
        // Sync every 5 minutes, as the app does when it runs; collect everything ever planned.
        var planned = Set<Date>()
        var t = ring(a)
        while t < a.end {
            planned.formUnion(MissedAlarmRule.repeats(firstRing: ring(a), stop: a.end, dismissed: false, after: t))
            t = t.addingTimeInterval(300)
        }
        let all = ([ring(a)] + planned.sorted())
        for (x, y) in zip(all, all.dropFirst()) {
            XCTAssertEqual(y.timeIntervalSince(x), step, accuracy: 0.001, "a gap between rings")
        }
        // The last ring ends within one step of the stop.
        XCTAssertLessThanOrEqual(a.end.timeIntervalSince(all.last!.addingTimeInterval(MissedAlarmRule.alertLength)), step)
        assertQuietAtStop(Array(planned), stop: a.end)
    }

    /// After a snooze, a later meeting that has already rung still ends the earlier alarm: nothing more rings.
    func testSnoozeAfterTheNextMeetingRangPlansNothing() {
        let a = meeting("a", 10, 0), b = meeting("b", 10, 5)
        let snoozeRing = ring(b).addingTimeInterval(60)
        let stop = MissedAlarmRule.stopTime(for: a, firstRing: snoozeRing, later: later(b), rings: always)
        XCTAssertEqual(stop, ring(b))
        XCTAssertTrue(MissedAlarmRule.repeats(firstRing: snoozeRing, stop: stop, dismissed: false, after: snoozeRing).isEmpty)
        XCTAssertFalse(MissedAlarmRule.shouldRing(firstRing: snoozeRing, stop: stop, dismissed: false, now: snoozeRing))
    }

    /// When the time to the handover is shorter than one alert, the rule says so (only Pop In, running, can stop it).
    func testFirstRingOverlapIsFlagged() {
        let a = meeting("a", 10, 0)
        XCTAssertTrue(MissedAlarmRule.firstRingOverlaps(firstRing: at(9, 58), stop: at(9, 58).addingTimeInterval(30)))
        XCTAssertFalse(MissedAlarmRule.firstRingOverlaps(firstRing: at(9, 58), stop: a.end))
    }

    /// Part 2 can start the first repeat at the one-minute safety backup.
    func testFirstRepeatCanStartAtTheSafetyBackup() {
        let a = meeting("a", 10, 0)
        let repeats = MissedAlarmRule.repeats(firstRing: ring(a), stop: a.end, dismissed: false, after: ring(a), firstRepeatAfter: 60)
        XCTAssertEqual(repeats.first, ring(a).addingTimeInterval(60))
    }

    /// The alert is planned as 15 minutes, like the Clock app.
    func testAlertLengthIsFifteenMinutes() {
        XCTAssertEqual(MissedAlarmRule.alertLength, 15 * 60)
    }

    // MARK: Part 2: the repeat alarms to schedule

    private func anchor(_ m: Meeting) -> MissedAlarmRule.Anchor { .init(meeting: m, firstRing: ring(m)) }

    /// A chain stops before the next meeting's first ring; the next meeting's chain runs to its own end.
    func testChainsStopBeforeTheNextMeetingRings() {
        let a = meeting("a", 10, 0, minutes: 60), b = meeting("b", 10, 45, minutes: 60)
        let plan = MissedAlarmRule.repeatAlarms(anchors: [anchor(a), anchor(b)], dismissed: [], now: at(9, 0), budget: 24)
        let aRepeats = plan.filter { $0.meeting.id == "a" }, bRepeats = plan.filter { $0.meeting.id == "b" }
        XCTAssertFalse(aRepeats.isEmpty)
        for r in aRepeats { XCTAssertLessThanOrEqual(r.fireDate.addingTimeInterval(MissedAlarmRule.alertLength), ring(b)) }
        XCTAssertFalse(bRepeats.isEmpty)
        for r in bRepeats { XCTAssertLessThanOrEqual(r.fireDate.addingTimeInterval(MissedAlarmRule.alertLength), b.end) }
    }

    /// Same-minute meetings share one chain, as they share one alarm.
    func testSameMinuteMeetingsShareOneChain() {
        let a = meeting("a", 10, 0, minutes: 60), b = meeting("b", 10, 0, minutes: 90)
        let plan = MissedAlarmRule.repeatAlarms(anchors: [anchor(a), anchor(b)], dismissed: [], now: at(9, 0), budget: 24)
        XCTAssertEqual(Set(plan.map(\.meeting.id)), ["a"])
        XCTAssertEqual(Set(plan.map(\.fireDate)).count, plan.count, "no two repeats at the same moment")
    }

    /// A dismissed meeting gets no repeats; the others keep theirs.
    func testDismissedMeetingGetsNoRepeats() {
        let a = meeting("a", 10, 0, minutes: 60), b = meeting("b", 13, 0, minutes: 60)
        let plan = MissedAlarmRule.repeatAlarms(anchors: [anchor(a), anchor(b)], dismissed: ["a"], now: at(9, 0), budget: 24)
        XCTAssertTrue(plan.allSatisfy { $0.meeting.id == "b" })
        XCTAssertFalse(plan.isEmpty)
    }

    /// The budget keeps the soonest repeats.
    func testBudgetKeepsTheSoonest() {
        let a = meeting("a", 10, 0, minutes: 240), b = meeting("b", 15, 0, minutes: 240)
        let all = MissedAlarmRule.repeatAlarms(anchors: [anchor(a), anchor(b)], dismissed: [], now: at(9, 0), budget: 24)
        let three = MissedAlarmRule.repeatAlarms(anchors: [anchor(a), anchor(b)], dismissed: [], now: at(9, 0), budget: 3)
        XCTAssertEqual(three.map(\.fireDate), Array(all.map(\.fireDate).prefix(3)))
        XCTAssertTrue(MissedAlarmRule.repeatAlarms(anchors: [anchor(a)], dismissed: [], now: at(9, 0), budget: 0).isEmpty)
    }

    /// Re-syncing gives the same IDs, so repeats are never duplicated.
    func testRepeatIDsAreStable() {
        let a = meeting("a", 10, 0, minutes: 120)
        let one = MissedAlarmRule.repeatAlarms(anchors: [anchor(a)], dismissed: [], now: at(9, 0), budget: 24)
        let two = MissedAlarmRule.repeatAlarms(anchors: [anchor(a)], dismissed: [], now: at(9, 30), budget: 24)
        XCTAssertEqual(one.map(\.id), two.map(\.id))
        XCTAssertEqual(Set(one.map(\.id)).count, one.count)
    }

    /// Over a whole simulated day of start times and gaps, no repeat is planned to sound into the stop time.
    func testNoRepeatEverSoundsIntoTheStop() {
        for startMinute in stride(from: 0, through: 120, by: 5) {
            for gap in [0, 5, 10, 15, 30, 45, 60, 90] {
                let a = meeting("a", 9, startMinute)
                let b = meeting("b", 9, startMinute + 30 + gap)
                let stop = MissedAlarmRule.stopTime(for: a, firstRing: ring(a), later: later(b), rings: always)
                assertQuietAtStop(MissedAlarmRule.repeats(firstRing: ring(a), stop: stop, dismissed: false, after: ring(a)), stop: stop)
            }
        }
    }
}
