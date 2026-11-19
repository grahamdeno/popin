import XCTest
@testable import Promptly

/// Story 8.6: a pressed button shrinks slightly and dims; with Reduce Motion it only dims.
final class PressedLookTests: XCTestCase {
    func testPressedShrinksAndDims() {
        XCTAssertEqual(PressedLook.scale(pressed: true, reduceMotion: false), 0.97)
        XCTAssertEqual(PressedLook.opacity(pressed: true), 0.9)
    }

    func testReduceMotionOnlyDims() {
        XCTAssertEqual(PressedLook.scale(pressed: true, reduceMotion: true), 1)
        XCTAssertEqual(PressedLook.opacity(pressed: true), 0.9)
    }

    func testAtRestNothingChanges() {
        XCTAssertEqual(PressedLook.scale(pressed: false, reduceMotion: false), 1)
        XCTAssertEqual(PressedLook.opacity(pressed: false), 1)
    }
}
