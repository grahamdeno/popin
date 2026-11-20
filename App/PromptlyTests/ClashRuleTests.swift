import XCTest
@testable import Promptly

/// Story 1.1: catch double-booking before it rings.
final class ClashRuleTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000 - 1_800_000_000.truncatingRemainder(dividingBy: 60))
    private func m(_ id: String, _ minutes: Double, length: Double = 30, cal: String = "work") -> Meeting {
        Meeting(id: id, eventID: id, title: id, start: t0.addingTimeInterval(minutes * 60),
                end: t0.addingTimeInterval((minutes + length) * 60), calendarID: cal, joinURL: nil)
    }

    func testSameMinuteMeetingsClash() {
        let a = m("a", 60), b = m("b", 60.5), c = m("c", 90)
        let groups = ClashRule.groups([a, b, c], rings: { _ in true })
        XCTAssertEqual(groups.map { $0.map(\.id) }, [["a", "b"]])
    }

    func testPartialOverlapIsNotAClash() {
        let a = m("a", 60, length: 60), b = m("b", 75)
        XCTAssertTrue(ClashRule.groups([a, b], rings: { _ in true }).isEmpty)
    }

    func testQuietMeetingsDontClash() {
        let a = m("a", 60), quiet = m("q", 60, cal: "quiet")
        XCTAssertTrue(ClashRule.groups([a, quiet], rings: { $0.calendarID != "quiet" }).isEmpty)
    }

    /// Picking one drops the rest; with them no longer ringing, the clash is gone.
    func testPickingOneDropsTheOthers() {
        let a = m("a", 60), b = m("b", 60), c = m("c", 60)
        let group = ClashRule.groups([a, b, c], rings: { _ in true })[0]
        let dropped = ClashRule.dropped(picking: b, from: group)
        XCTAssertEqual(dropped, ["a", "c"])
        XCTAssertTrue(ClashRule.groups([a, b, c], rings: { !dropped.contains($0.id) }).isEmpty)
    }

    func testWords() {
        XCTAssertEqual(ClashRule.line(count: 2, time: "1:00 PM"), "2 meetings at 1:00 PM · Pick one")
        XCTAssertEqual(ClashRule.droppedLine(title: "Design review", time: "1:00 PM"), "Not ringing: 1:00 PM Design review")
    }

    func testDroppedLinesSkipClearedAndOver() {
        let a = m("a", 60), b = m("b", -60), c = m("c", 60)
        let lines = ClashRule.droppedLines([a, b, c], dropped: ["a", "b", "c"], cleared: ["c"], now: t0)
        XCTAssertEqual(lines.map(\.id), ["a"])
    }
}
