import XCTest
@testable import Promptly

/// Item 11 (docs/roadmap.md): starting Pop In in demo mode leaves the saved settings unchanged, the theme and
/// Surprise me included. AppModel uses `Prefs.demo()` whenever `ScreenshotMode.isOn`; the demo scene is fixed per
/// launch by the process arguments, so these tests exercise the store every demo scene goes through.
final class DemoModeTests: XCTestCase {
    private func freshSuite() -> (name: String, defaults: UserDefaults) {
        let name = "promptly.tests.\(UUID().uuidString)"
        return (name, UserDefaults(suiteName: name)!)
    }

    /// Everything a demo sets (theme, Surprise me, lead time, ball style, cleared and skipped meetings) lands in the
    /// demo store; the real settings read the same before and after.
    func testDemoWritesNeverReachTheRealSettings() {
        let real = freshSuite()
        let owner = Prefs(defaults: real.defaults)
        owner.gumColor = .moon
        owner.surprise = true
        owner.leadMinutes = 3
        owner.ballStyle = .steady
        owner.clearedMeetingIDs = ["keep@1"]
        let before = real.defaults.dictionaryRepresentation().filter { !$0.key.hasPrefix("NS") && !$0.key.hasPrefix("Apple") }

        let demoName = "promptly.tests.demo.\(UUID().uuidString)"
        let demo = Prefs.demo(suiteName: demoName)
        demo.gumColor = .unicorn
        demo.surprise = false
        demo.leadMinutes = 2
        demo.ballStyle = .bubble
        demo.clearedMeetingIDs = ["shot-design@1"]
        demo.skippedMeetingIDs = ["shot-design@1"]
        demo.onboarded = true

        let after = real.defaults.dictionaryRepresentation().filter { !$0.key.hasPrefix("NS") && !$0.key.hasPrefix("Apple") }
        XCTAssertEqual(NSDictionary(dictionary: before), NSDictionary(dictionary: after))
        XCTAssertEqual(owner.gumColor, .moon)
        XCTAssertTrue(owner.surprise)
        XCTAssertEqual(owner.leadMinutes, 3)
        XCTAssertEqual(owner.ballStyle, .steady)
        XCTAssertEqual(owner.clearedMeetingIDs, ["keep@1"])
        UserDefaults().removePersistentDomain(forName: demoName)
    }

    /// Each demo launch starts empty: nothing one demo saved is read by the next, so a saved Surprise me never
    /// carries into a demo.
    func testEachDemoLaunchStartsEmpty() {
        let demoName = "promptly.tests.demo.\(UUID().uuidString)"
        let first = Prefs.demo(suiteName: demoName)
        first.surprise = true
        first.gumColor = .grenade
        let second = Prefs.demo(suiteName: demoName)
        XCTAssertFalse(second.surprise)
        XCTAssertNotEqual(second.gumColor, .grenade)
        UserDefaults().removePersistentDomain(forName: demoName)
    }

    /// The demo store is never the real App Group suite.
    func testDemoSuiteIsNotTheRealSuite() {
        XCTAssertNotEqual(Prefs.demoSuite, Prefs.suite)
    }
}
