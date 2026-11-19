import XCTest
@testable import Promptly

/// Story 8.10: the Add reminder sheet's quick times and its Add rule.
final class ReminderTimeTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testChipsSetTheTimeFromNow() {
        XCTAssertEqual(ReminderTime.in15.date(from: now), now.addingTimeInterval(900))
        XCTAssertEqual(ReminderTime.in30.date(from: now), now.addingTimeInterval(1800))
        XCTAssertEqual(ReminderTime.in60.date(from: now), now.addingTimeInterval(3600))
        XCTAssertNil(ReminderTime.pick.date(from: now), "Pick a time uses the picker")
    }

    func testChipWords() {
        XCTAssertEqual(ReminderTime.allCases.map(\.label), ["In 15 min", "30 min", "1 hour", "Pick a time"])
    }

    func testAddNeedsATitle() {
        XCTAssertFalse(ReminderTime.canAdd(title: ""))
        XCTAssertFalse(ReminderTime.canAdd(title: "   \n"))
        XCTAssertTrue(ReminderTime.canAdd(title: "Pick up Nora"))
    }
}
