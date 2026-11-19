import XCTest
@testable import Promptly

/// Story 8.5: every small ball has the big bubble's light, scaled to its size.
final class BallLightTests: XCTestCase {
    func testLightScalesWithTheBall() {
        let small = BallLight.metrics(size: 44), big = BallLight.metrics(size: 88)
        XCTAssertEqual(big.windowCenter.x, small.windowCenter.x * 2, accuracy: 0.001)
        XCTAssertEqual(big.window.width, small.window.width * 2, accuracy: 0.001)
        XCTAssertEqual(big.streakInset, small.streakInset * 2, accuracy: 0.001)
    }

    /// The window and glint sit where the big bubble puts them (upper left window, glint near the top).
    func testLightSitsWhereTheBubblePutsIt() {
        let m = BallLight.metrics(size: 100)
        XCTAssertEqual(m.windowCenter.x, 31, accuracy: 0.001)
        XCTAssertEqual(m.windowCenter.y, 25, accuracy: 0.001)
        XCTAssertEqual(m.streakInset, 7.5, accuracy: 0.001)
        XCTAssertLessThan(m.glintCenter.y, m.windowCenter.y)
    }

    /// Tiny balls (Dynamic Island) keep a visible streak and drop the glint.
    func testTinyBallsKeepAStreakAndDropTheGlint() {
        let m = BallLight.metrics(size: 16)
        XCTAssertGreaterThanOrEqual(m.streakWidth, 1.2)
        XCTAssertFalse(m.showsGlint)
        XCTAssertTrue(BallLight.metrics(size: 64).showsGlint)
    }
}
