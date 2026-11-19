import XCTest
@testable import Promptly

/// Item 7.2 (docs/roadmap.md): bring back a skipped meeting until it starts. One test per criterion; the toast's
/// place on screen at large text is checked by the walk (J2, J3).
final class SkipRuleTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func meeting(_ id: String, inMinutes m: Double, title: String = "Design review") -> Meeting {
        let start = now.addingTimeInterval(m * 60)
        return Meeting(id: Meeting.makeID(eventID: id, start: start), eventID: id, title: title,
                       start: start, end: start.addingTimeInterval(1800), calendarID: "c", joinURL: nil)
    }

    /// Given I tap Not going, the toast says "Not going to [title]"; after a pop, "Popped [title]". Undo sits beside it.
    func testToastWords() {
        XCTAssertEqual(SkipRule.toast(title: "Design review", skipped: true), "Not going to Design review")
        XCTAssertEqual(SkipRule.toast(title: "Design review", skipped: false), "Popped Design review")
    }

    /// Given the toast has gone, the meeting shows as a quiet line until it starts.
    func testQuietLineUntilTheStart() {
        let m = meeting("a", inMinutes: 30)
        XCTAssertEqual(SkipRule.line(title: m.title, time: "3:00 PM"), "Not going: 3:00 PM Design review")
        XCTAssertEqual(SkipRule.restorable([m], skipped: [m.id], now: now).map(\.id), [m.id])
        // While its toast is still up, the line waits.
        XCTAssertTrue(SkipRule.restorable([m], skipped: [m.id], now: now, hiding: m.id).isEmpty)
        // At the start, the line goes and Undo no longer applies.
        XCTAssertTrue(SkipRule.restorable([m], skipped: [m.id], now: m.start).isEmpty)
        XCTAssertFalse(SkipRule.canRestore(m, skipped: [m.id], now: m.start))
        XCTAssertTrue(SkipRule.canRestore(m, skipped: [m.id], now: m.start.addingTimeInterval(-1)))
    }

    /// Only skipped meetings get the line, soonest first. A popped meeting (joined) doesn't.
    func testOnlySkippedMeetingsSoonestFirst() {
        let late = meeting("late", inMinutes: 90, title: "Lunch")
        let soon = meeting("soon", inMinutes: 20, title: "Standup")
        let popped = meeting("popped", inMinutes: 40, title: "Sync")
        let lines = SkipRule.restorable([late, popped, soon], skipped: [late.id, soon.id], now: now)
        XCTAssertEqual(lines.map(\.title), ["Standup", "Lunch"])
    }

    /// Given I tap Undo before the start, its alarm comes back exactly as it was: same ID, same ring time.
    func testUndoBringsTheSameAlarmBack() {
        let m = meeting("a", inMinutes: 30)
        let before = AlarmPlanner.plan(meetings: [m], leadMinutes: 2, now: now, cleared: [])
        let skipped = AlarmPlanner.plan(meetings: [m], leadMinutes: 2, now: now.addingTimeInterval(60), cleared: [m.id])
        let restored = AlarmPlanner.plan(meetings: [m], leadMinutes: 2, now: now.addingTimeInterval(120), cleared: [])
        XCTAssertTrue(skipped.isEmpty)
        XCTAssertEqual(restored.map(\.id), before.map(\.id))
        XCTAssertEqual(restored.map(\.fireDate), before.map(\.fireDate))
    }

    /// Nothing is written to the calendar: skips live in Pop In's own settings, and survive a relaunch.
    func testSkipsAreAppStateAndSurviveARelaunch() {
        let defaults = UserDefaults(suiteName: "promptly.tests.\(UUID().uuidString)")!
        let prefs = Prefs(defaults: defaults)
        XCTAssertTrue(prefs.skippedMeetingIDs.isEmpty)
        prefs.skippedMeetingIDs = ["a@1", "b@2"]
        XCTAssertEqual(Prefs(defaults: defaults).skippedMeetingIDs, ["a@1", "b@2"])
    }

    /// A simulated morning, minute by minute: the line stays up to the last minute before the start, then goes.
    func testSimulatedMinutesUntilTheStart() {
        let m = meeting("a", inMinutes: 10)
        for minute in 0...12 {
            let t = now.addingTimeInterval(Double(minute) * 60)
            let shows = !SkipRule.restorable([m], skipped: [m.id], now: t).isEmpty
            XCTAssertEqual(shows, minute < 10, "minute \(minute)")
        }
    }
}
