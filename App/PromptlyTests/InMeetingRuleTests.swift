import XCTest
@testable import Promptly

/// Story 1.4: gentler alarms while already in a meeting.
final class InMeetingRuleTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
    private func m(_ id: String, _ minutes: Double, length: Double = 30) -> Meeting {
        Meeting(id: id, eventID: id, title: id, start: t0.addingTimeInterval(minutes * 60),
                end: t0.addingTimeInterval((minutes + length) * 60), calendarID: "work", joinURL: nil)
    }
    private func alarm(_ meeting: Meeting, at minutes: Double) -> PlannedAlarm {
        PlannedAlarm(id: UUID(), meeting: meeting, fireDate: t0.addingTimeInterval(minutes * 60), countdownSeconds: nil)
    }

    /// In a popped meeting that is still running: the next alarm is the quiet version, with its own ID.
    func testAlarmDuringAPoppedMeetingIsQuiet() {
        let a = m("a", 0, length: 60), b = m("b", 45)
        let ring = alarm(b, at: 43)
        let result = InMeetingRule.apply([ring], popped: [a])
        XCTAssertEqual(result.alarms.count, 1)
        XCTAssertNotEqual(result.alarms[0].id, ring.id)
        XCTAssertEqual(result.alarms[0].id, InMeetingRule.quietID(ring.id))
        XCTAssertEqual(result.quiet, [result.alarms[0].id])
        XCTAssertEqual(result.alarms[0].fireDate, ring.fireDate, "the alarm still rings, at the same time")
    }

    /// Once the earlier meeting has ended, alarms are normal again.
    func testNormalAfterTheMeetingEnds() {
        let a = m("a", 0, length: 30), b = m("b", 45)
        let ring = alarm(b, at: 43)
        let result = InMeetingRule.apply([ring], popped: [a])
        XCTAssertEqual(result.alarms[0].id, ring.id)
        XCTAssertTrue(result.quiet.isEmpty)
    }

    /// Not going doesn't count as being in a meeting; a pop does.
    func testOnlyPoppedMeetingsCount() {
        let a = m("a", 0), b = m("b", 0)
        let popped = InMeetingRule.popped([a, b], cleared: ["a", "b"], skipped: ["b"])
        XCTAssertEqual(popped.map(\.id), ["a"])
    }

    /// Test and snooze alarms keep their IDs, and a meeting doesn't make its own alarm quiet.
    func testProtectedAndOwnAlarmsStayNormal() {
        let a = m("a", 0, length: 60), b = m("b", 45)
        let snooze = alarm(b, at: 47)
        XCTAssertEqual(InMeetingRule.apply([snooze], popped: [a], except: [snooze.id]).alarms[0].id, snooze.id)
        let own = alarm(a, at: 10)
        XCTAssertEqual(InMeetingRule.apply([own], popped: [a]).alarms[0].id, own.id)
    }

    /// The quiet ID is stable, so a re-sync doesn't duplicate the alarm.
    func testQuietIDIsStable() {
        let id = UUID()
        XCTAssertEqual(InMeetingRule.quietID(id), InMeetingRule.quietID(id))
        XCTAssertNotEqual(InMeetingRule.quietID(id), id)
    }

    /// The quiet sound ships with the app.
    func testQuietSoundIsInTheBundle() {
        let name = (InMeetingRule.quietSoundFile as NSString).deletingPathExtension
        XCTAssertNotNil(Bundle(for: AppModel.self).url(forResource: name, withExtension: "wav")
                        ?? Bundle.main.url(forResource: name, withExtension: "wav"))
    }
}
