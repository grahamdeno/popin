import XCTest

/// The journeys of the UX audit (docs/audit/ux-audit.md), in the order a person meets them. Each is one job, walked
/// step by step in Pop In's demo mode. A check that fails is written down and the walk goes on.
@MainActor
final class Journeys: XCTestCase {
    override func setUp() { continueAfterFailure = true }

    private func popBubble(_ a: Audit, title: String = "Design review") -> Bool {
        let bubble = a.any(containing: "Pop the bubble to join \(title)")
        guard a.expect("the bubble is a button named for the meeting", bubble, severity: 3) else {
            a.tapAt(0.5, 0.82)
            return false
        }
        a.tap("the bubble", bubble)
        return true
    }

    /// Home's header (7.1): ⋯ reads "More"; the gear reads "Settings" and opens Settings in one tap.
    private static let more = "home-more"

    /// From Home to Settings the way a person gets there: the gear in the header. One tap, counted.
    @discardableResult
    private func openSettingsFromHome(_ a: Audit, severity: Int = 3) -> Bool {
        // A Settings sheet that was just closed is still fading out; two "Settings" bars at once break the next query
        // (J7 stopped early in every config, November 19). Wait for it to go first.
        // The closing sheet may be on any page (J7 closes it from Calendars), so wait for every navigation bar to go;
        // Home has none. A gear tap during the close was ignored (J7, every config, November 19).
        let anyBar = a.app.navigationBars.firstMatch
        if anyBar.exists {
            _ = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: anyBar)], timeout: 5)
        }
        guard a.tap("Settings (gear)", a.app.buttons["home-settings"], severity: severity) else { return false }
        // The sheet rises after the tap. Wait for it, so the next query doesn't run against Home: J12 lost
        // the Theme row in 10 of 40 themes without this wait (pro-light, November 18). One more tap if it didn't.
        let bar = a.app.navigationBars["Settings"].firstMatch
        if !bar.waitForExistence(timeout: 4) {
            a.check("Settings opened on the first tap", false, severity: 1)
            a.tap("Settings (gear), second try", a.app.buttons["home-settings"], severity: 1)
        }
        return a.expect("Settings opens", bar, timeout: 5, severity: severity)
    }

    // MARK: Home's layout (item 7.1)

    private func countdown(_ a: Audit) -> XCUIElement {
        a.app.descendants(matching: .any).matching(identifier: "countdown").firstMatch
    }

    /// The header stays on screen and both buttons can be tapped.
    private func headerChecks(_ a: Audit, _ place: String) {
        let more = a.app.buttons[Journeys.more]
        let gear = a.app.buttons["home-settings"]
        a.check("More is on screen and hittable (\(place))", more.waitForExistence(timeout: 3) && more.isHittable, severity: 4)
        a.check("the gear (Settings) is on screen and hittable (\(place))", gear.waitForExistence(timeout: 3) && gear.isHittable, severity: 4)
        // VoiceOver reads these names.
        a.check("VoiceOver names the ⋯ button More (\(place))", more.label == "More", severity: 3, detail: "label \(more.label)")
        a.check("VoiceOver names the gear Settings (\(place))", gear.label == "Settings", severity: 3, detail: "label \(gear.label)")
    }

    /// Not going can be reached by scrolling the column, and is at least 44 pt tall.
    @discardableResult
    private func notGoingChecks(_ a: Audit, _ place: String) -> Bool {
        let notGoing = a.app.buttons["Not going"]
        guard a.expect("Not going exists (\(place))", notGoing, severity: 4) else { return false }
        a.reveal(notGoing, tries: 8)
        let reached = a.check("Not going is reachable by scrolling (\(place))", notGoing.isHittable, severity: 4)
        a.check("Not going is at least 44 pt tall (\(place))", notGoing.frame.height >= 44, severity: 3,
                detail: "height \(notGoing.frame.height)")
        return reached
    }

    /// The bubble can be tapped with the column at the top and again after it has scrolled to the bottom.
    private func bubbleChecks(_ a: Audit) {
        let bubble = a.any(containing: "Pop the bubble to join Design review")
        a.check("the bubble is hittable with the column at the top", bubble.waitForExistence(timeout: 3) && bubble.isHittable, severity: 4)
        let column = a.app.scrollViews.firstMatch
        if column.exists { for _ in 0..<4 { column.swipeUp() } }
        a.pause(0.4)
        a.check("the bubble is hittable with the column at the bottom", bubble.exists && bubble.isHittable, severity: 4)
    }

    /// The Settings row "Ring before", whose label carries the choice ("Ring before, 2 min"). Demo mode already rings
    /// 2 minutes before, so the row is read rather than any "2 min" on screen (the Home card has one too).
    private func ringsTwoMinutesBefore(_ a: Audit) -> Bool {
        let row = a.app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Ring before")).firstMatch
        return row.waitForExistence(timeout: 2) && row.label.contains("2 min")
    }

    /// Closes the Settings sheet, back to Home. Not counted as part of any job.
    private func closeSettings(_ a: Audit) {
        let done = a.app.buttons["Done"].firstMatch
        if done.waitForExistence(timeout: 2), done.isHittable { done.tap() }
        a.pause(1.0)
    }

    // J1. First run: hello, calendars, alarms, choose calendars, covered, Home.
    func test01_FirstRun() {
        let a = Audit("J1-first-run")
        defer { a.finish() }
        a.launch("welcome")
        a.shot("hello")
        a.accessibility("hello")
        a.labels("hello")
        a.check("hello says what Pop In does", a.text(containing: "rings before each meeting").exists, severity: 2)
        a.tap("Get started", a.app.buttons["Get started"], severity: 4)
        a.pause(0.8)
        a.shot("calendars-why")
        a.accessibility("calendars-why")
        a.tap("Allow calendar access", a.button(startingWith: "Allow calendar"), severity: 4)
        a.pause(1.2)
        a.shot("alarms-why")
        a.accessibility("alarms-why")
        a.check("shows both alarm looks before iOS asks", a.app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", "phone is locked")).firstMatch.exists, severity: 3)
        a.tap("Allow alarms", a.button(startingWith: "Allow alarms"), severity: 4)
        a.pause(1.2)
        a.shot("which-calendars")
        a.accessibility("which-calendars")
        a.labels("which-calendars")
        a.expect("calendars are listed by account", a.text(containing: "Exchange"), severity: 3)
        a.tap("Done", a.app.buttons["Done"], severity: 4)
        a.pause(1.2)
        a.shot("covered")
        a.accessibility("covered")
        a.check("covered names the next meeting", a.text(containing: "Next up").exists, severity: 2)
        a.tap("Done (covered)", a.app.buttons["Done"], severity: 4)
        a.pause(1.5)
        a.shot("home-after-first-run")
        a.expect("Home shows the next meeting", a.any(containing: "Design review"), severity: 4)
    }

    // J2. Home with a meeting minutes away: read it, pop to join, Undo.
    func test02_HomeSoon() {
        let a = Audit("J2-home-soon")
        defer { a.finish() }
        a.launch("home")
        a.shot("home")
        a.accessibility("home")
        a.labels("home")
        a.expect("the card names the meeting", a.any(containing: "Design review"), severity: 4)
        a.expect("the card says how long", a.any(containing: "min"), severity: 3)
        a.expect("the card says it will ring", a.any(containing: "Rings"), severity: 3)
        a.expect("Not going is visible", a.app.buttons["Not going"], severity: 4)
        a.expect("Settings is reachable", a.app.buttons["home-settings"], severity: 3)
        // 7.1: the header is fixed, Not going is reachable and 44 pt, the bubble is tappable at both ends of the column.
        headerChecks(a, "column at the top")
        bubbleChecks(a)
        a.shot("home-column-bottom", note: "The column scrolled to its end; the header stays at the top")
        headerChecks(a, "column at the bottom")
        notGoingChecks(a, "Home")
        a.launch("home")
        a.begin("Join the next meeting")
        let ok = popBubble(a)
        let undo = a.app.buttons["Undo"]
        a.done("Join the next meeting", ok)
        // Undo lasts 5 s and a picture takes 5 to 20 s, so tap Undo first and take the pictures after. The old order
        // (picture, then Undo) lost Undo on small-phone (November 19).
        a.check("Undo is offered after the pop", undo.waitForExistence(timeout: 2), severity: 3)
        a.begin("Undo a pop")
        a.tap("Undo", undo)
        a.pause(1.2)
        a.shot("after-undo")
        a.done("Undo a pop", a.any(containing: "Pop the bubble to join Design review").waitForExistence(timeout: 3))
        // The mid-pop picture, from a second pop at the end (not counted in either job).
        if popBubble(a) {
            a.pause(0.3)
            a.shot("popping", note: "mid-pop")
        }
    }

    // J3. Not going, then Undo.
    func test03_NotGoing() {
        let a = Audit("J3-not-going")
        defer { a.finish() }
        a.launch("home")
        a.begin("Skip a meeting")
        // At the largest text Not going is below the first screen: scroll the column to it (a swipe is not a tap).
        let notGoing = a.reveal(a.app.buttons["Not going"], tries: 8)
        a.tap("Not going", notGoing, severity: 4)
        // Skipping is one tap; Undo is a separate job. Undo lasts 5 s and a picture takes longer, so tap Undo first.
        let undo = a.app.buttons["Undo"]
        let offered = undo.waitForExistence(timeout: 2)
        a.done("Skip a meeting", offered)
        a.check("Undo is offered", offered, severity: 3)
        a.tap("Undo", undo)
        a.pause(0.8)
        a.shot("after-undo")
        let back = a.any(containing: "Pop the bubble to join Design review")
        a.check("the meeting is back", back.waitForExistence(timeout: 3), severity: 3)
        // 7.2: skip again and let the toast go. The quiet line takes over, and its Undo brings the meeting back after
        // 10 seconds.
        let again = a.reveal(a.app.buttons["Not going"], tries: 8)
        guard again.exists && again.isHittable else {
            a.check("Not going can be tapped a second time", false, severity: 3)
            return
        }
        again.tap()
        a.check("the toast names the skip", a.any(containing: "Not going to Design review").waitForExistence(timeout: 2), severity: 2)
        let toastUndo = a.app.buttons["Undo"]
        if toastUndo.exists {
            let screen = a.app.windows.firstMatch.frame
            a.check("the toast's Undo is inside the bottom quarter", toastUndo.frame.minY >= screen.height * 0.75, severity: 2,
                    detail: "Undo at \(toastUndo.frame), screen \(screen)")
        }
        a.shot("not-going", note: "Toast: Not going to Design review · Undo")
        a.pause(10)
        a.check("the toast has gone after 5 seconds", !a.app.buttons["Undo"].exists, severity: 2)
        let line = a.reveal(a.app.buttons["undo-skip"], tries: 8)
        a.shot("not-going-line", note: "Not going: [time] Design review · Undo, in the strip under the card")
        a.check("the quiet line shows the skipped meeting", a.any(containing: "Not going:").exists, severity: 3)
        a.check("the quiet line's Undo is at least 44 pt", line.exists && line.frame.height >= 44, severity: 3,
                detail: "height \(line.frame.height)")
        a.tap("Undo on the quiet line, 10 seconds later", line, severity: 3)
        a.pause(0.8)
        a.check("the meeting is back after 10 seconds", back.waitForExistence(timeout: 3), severity: 3)
        a.shot("after-line-undo")
    }

    // J4. Home a day ahead: the calm state.
    func test04_HomeFar() {
        let a = Audit("J4-home-far")
        defer { a.finish() }
        a.launch("far")
        a.shot("home-far")
        a.accessibility("home-far")
        a.labels("home-far")
        a.expect("the day is named", a.any(containing: "Tomorrow"), severity: 2)
        a.expect("Not going is visible", a.app.buttons["Not going"], severity: 3)
        // 7.1: the countdown keeps its size when the hint line appears. This scene has no hint (a day away); the
        // Home scene (7 minutes, with a link) has one. No demo scene sits at 11 minutes, so the two scenes stand in.
        let far = countdown(a)
        a.expect("the countdown is named (a day away)", far, severity: 3)
        let farHeight = far.frame.height
        a.launch("home")
        let near = countdown(a)
        a.expect("the countdown is named (7 minutes)", near, severity: 3)
        let hint = a.app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Pop the bubble to join")).firstMatch
        a.check("the hint is showing in the near scene", hint.exists, severity: 3)
        a.check("the countdown keeps its size when the hint appears", abs(farHeight - near.frame.height) < 1, severity: 3,
                detail: "a day away \(farHeight) pt; 7 minutes with the hint \(near.frame.height) pt")
    }

    // J5. The takeover when it rings, then late with buds.
    func test05_Takeover() {
        let a = Audit("J5-takeover")
        defer { a.finish() }
        a.launch("now")
        a.shot("ringing")
        a.accessibility("ringing")
        a.labels("ringing")
        a.expect("Not going on the takeover", a.app.buttons["Not going"], severity: 4)
        a.expect("the meeting title", a.any(containing: "Design review"), severity: 4)
        // 7.3: the card follows M2, its buttons are inside it, and nothing overlaps the meeting time. Queries stay
        // inside the alarm card (Home sits under it with its own Not going), and nothing here swipes: a swipe on the
        // alarm screen lands on the bubble and pops it (J5 stopped early in every config, November 19).
        let card = a.app.descendants(matching: .any).matching(identifier: "alarm-card").firstMatch
        if a.expect("the alarm card is shown", card, severity: 4) {
            a.check("the card says Starts in", card.staticTexts["Starts in"].exists, severity: 3)
            a.check("the card says how to join",
                    card.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Pop the bubble to join")).firstMatch.exists,
                    severity: 3)
            let snooze = card.buttons["Snooze 2 min"].firstMatch
            let notGoing = card.buttons["Not going"].firstMatch
            let span = card.descendants(matching: .any).matching(identifier: "alarm-span").firstMatch
            a.check("Snooze 2 min is the button's word and VoiceOver name", snooze.exists, severity: 3)
            a.check("Not going is in the card, at least 44 pt", notGoing.exists && notGoing.frame.height >= 44, severity: 3,
                    detail: "Not going \(notGoing.frame)")
            a.check("Snooze 2 min is at least 44 pt", snooze.exists && snooze.frame.height >= 44, severity: 3,
                    detail: "Snooze \(snooze.frame)")
            if span.exists {
                let clear = !span.frame.intersects(notGoing.frame) && !span.frame.intersects(snooze.frame)
                a.check("nothing overlaps the meeting time", clear, severity: 4,
                        detail: "time \(span.frame), Not going \(notGoing.frame), Snooze \(snooze.frame)")
            } else {
                a.check("the meeting time is shown", false, severity: 3)
            }
            // The card's scroll area stops at three quarters of the screen, so the bubble can be tapped in the bottom
            // quarter. (The card itself can be taller and scroll; its frame isn't clipped, so measure the scroll area.)
            let screen = a.app.windows.firstMatch.frame
            let scroll = a.app.descendants(matching: .any).matching(identifier: "alarm-scroll").firstMatch
            a.check("the card leaves the bottom quarter for the bubble",
                    scroll.exists && scroll.frame.maxY <= screen.height * 0.75 + 1,
                    severity: 4, detail: "scroll area \(scroll.frame), screen \(screen)")
        }
        a.launch("late", settle: 3)
        a.shot("late-50s", note: "50 s after the ring: the first bud should be out")
        a.pause(25)
        a.shot("late-75s", note: "75 s after the ring: two or three buds")
        a.begin("Pop the late bubble")
        a.done("Pop the late bubble", popBubble(a))
        // The tap really popped: the alarm card is gone.
        let lateCard = a.app.descendants(matching: .any).matching(identifier: "alarm-card").firstMatch
        a.check("the pop closed the alarm", !lateCard.waitForExistence(timeout: 2), severity: 4)
        a.pause(0.4)
        a.shot("late-popping")
    }

    // J6. Settings: every row opens its screen and comes back.
    func test06_Settings() {
        let a = Audit("J6-settings")
        defer { a.finish() }
        // The benchmark is counted from Home, the way a person starts: More, Settings, Ring before, 2 minutes.
        a.launch("home", free: true)
        a.begin("Ring 2 minutes before")
        if openSettingsFromHome(a) {
            a.tap("Ring before", a.reveal(a.any(containing: "Ring before")))
            a.pause(0.8)
            // Demo mode already rings 2 minutes before, so the row alone can't show the choice was made: the tap must land too.
            let chose = a.tap("2 minutes", a.any(containing: "2 minutes"))
            a.stop("Ring 2 minutes before")
            a.back()
            a.pause(0.6)
            a.done("Ring 2 minutes before", chose && ringsTwoMinutesBefore(a))
        } else {
            a.done("Ring 2 minutes before", false)
        }
        // The rest of Settings, every row, from the Settings scene.
        a.launch("settings", free: true, settle: 3)
        a.shot("settings-top")
        a.accessibility("settings")
        a.labels("settings")
        // 8.1: choice rows show their value on the right ("Ring before" shows "2 min" in the demo).
        let ringBefore = a.app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Ring before")).firstMatch
        a.check("Ring before shows its value", ringBefore.exists && ringBefore.label.contains("min"), severity: 2,
                detail: ringBefore.exists ? ringBefore.label : "not found")
        // 8.4: one way to mark Pro, the word in a pill. No "✦" and no "(Pro)".
        a.check("no ✦ on Settings", !a.any(containing: "✦").exists, severity: 2)
        a.check("no (Pro) on Settings", !a.any(containing: "(Pro)").exists, severity: 2)
        a.expect("Test the alarm is visible", a.any(containing: "Test the alarm"), severity: 3)
        for row in ["Calendars", "Ring before", "Sound"] {
            a.expect("row \(row) shows", a.any(containing: row), severity: 3)
        }
        a.tap("Ring before", a.any(containing: "Ring before"))
        a.pause(0.8)
        a.shot("ring-before")
        a.accessibility("ring-before")
        a.tap("2 minutes", a.any(containing: "2 minutes"))
        a.back()
        a.pause(0.6)
        a.check("Ring before shows 2 min", ringsTwoMinutesBefore(a), severity: 3)
        let sound = a.app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Sound")).firstMatch
        a.tap("Sound", a.reveal(sound))
        a.pause(0.8)
        a.shot("sound")
        a.accessibility("sound")
        a.check("Pro sounds are marked", a.any(containing: "Pro").exists, severity: 2)
        a.back()
        a.pause(0.6)
        let popSound = a.app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Pop sound")).firstMatch
        // At the largest text the row sits about four screens down; six swipes didn't reach it (November 18).
        a.revealOnScreen(popSound, tries: 24)
        a.shot("settings-bottom")
        a.accessibility("settings-bottom")
        a.labels("settings-bottom")
        a.tap("Pop sound", popSound)
        a.pause(0.8)
        a.shot("pop-sound")
        a.back()
        a.pause(0.6)
        let theme = a.app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Theme")).firstMatch
        a.tap("Theme", a.reveal(theme))
        a.pause(0.8)
        a.shot("theme-gallery")
        a.check("no ✦ in the theme gallery", !a.any(containing: "✦").exists, severity: 2)
        a.accessibility("theme-gallery")
        let unicorn = a.app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Unicorn")).firstMatch
        a.tap("Unicorn (locked)", a.reveal(unicorn))
        a.pause(1.0)
        // A theme not tried yet offers "Try it for today" first; the Pro sheet is one tap further.
        let getPro = a.app.buttons["Get Pop In Pro"]
        if getPro.waitForExistence(timeout: 2) { a.tap("Get Pop In Pro", getPro) }
        a.pause(1.2)
        a.shot("pro-sheet-from-locked")
        a.expect("a locked choice opens Pop In Pro", a.any(containing: "Pop In Pro"), severity: 3)
        a.expect("Restore purchase", a.reveal(a.app.buttons["Restore purchase"]), severity: 3)
        a.accessibility("pro-sheet")
    }

    // J7. A long list of calendars: fold, search, turn a whole account off.
    func test07_ManyCalendars() {
        let a = Audit("J7-many-calendars")
        defer { a.finish() }
        a.launch("manycals", settle: 3)
        // This scene opens on Settings; close it so both jobs are counted from Home.
        closeSettings(a)
        a.begin("Find and turn off one calendar")
        openSettingsFromHome(a)
        a.tap("Calendars", a.reveal(a.any(containing: "Calendars")))
        a.pause(0.8)
        a.shot("calendars")
        a.accessibility("calendars")
        a.labels("calendars")
        // 8.4: the alert menu marks paid choices under a "Pro" heading, never "(Pro)". Open it, look, then pick Smart
        // again so nothing changes.
        let modeMenu = a.app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", "alerts: Smart")).firstMatch
        if modeMenu.exists && modeMenu.isHittable {
            modeMenu.tap()
            a.pause(0.6)
            a.check("no (Pro) in the alert menu", !a.any(containing: "(Pro)").exists, severity: 2)
            a.check("no ✦ in the alert menu", !a.any(containing: "✦").exists, severity: 2)
            let smart = a.app.buttons["Smart: rings for video meetings"].firstMatch
            if smart.waitForExistence(timeout: 2) { smart.tap() } else { a.tapAt(0.5, 0.05) }
            a.pause(0.6)
            a.check("the alert menu closed", !a.app.buttons["Smart: rings for video meetings"].exists, severity: 2)
        } else {
            a.check("the alert menu could be opened", false, severity: 2)
        }
        let search = a.app.textFields["Find a calendar"]
        if a.expect("search shows with many calendars", search, severity: 2) {
            a.tap("search", search)
            search.typeText("soccer")
            a.pause(0.8)
            a.shot("search-soccer")
            let toggle = a.app.switches["Soccer"]
            a.done("Find and turn off one calendar", a.tap("Soccer switch", toggle))
            a.pause(0.5)
            a.shot("soccer-off")
        } else {
            a.done("Find and turn off one calendar", false)
        }
        a.tap("clear search", a.app.buttons["Clear search"], severity: 2)
        a.pause(0.6)
        closeSettings(a)
        a.begin("Turn off a whole account")
        var allOffDone = false
        if openSettingsFromHome(a), a.tap("Calendars", a.reveal(a.any(containing: "Calendars"))) {
            a.pause(0.8)
            allOffDone = a.tap("Turn all off", a.app.buttons["Turn all off"].firstMatch)
        }
        a.done("Turn off a whole account", allOffDone)
        a.pause(0.6)
        a.shot("account-off")
    }

    // J8. Nothing coming up: the empty Home and the demo pop.
    func test08_Empty() {
        let a = Audit("J8-empty")
        defer { a.finish() }
        a.launch("empty")
        a.shot("empty")
        a.accessibility("empty")
        a.labels("empty")
        a.expect("says nothing is coming up", a.any(containing: "Nothing coming up"), severity: 3)
        let tryPop = a.app.buttons["Try a pop"]
        a.check("Try a pop is at least 44 pt", tryPop.exists && tryPop.frame.height >= 44, severity: 2,
                detail: "height \(tryPop.frame.height)")
        a.tap("Try a pop", tryPop, severity: 3)
        a.pause(1.5)
        a.shot("demo")
        a.labels("demo")
    }

    // J9. Unicorn mode: the bubble, the pop with confetti, sprinkles and unicorns.
    func test09_Unicorn() {
        let a = Audit("J9-unicorn")
        defer { a.finish() }
        a.launch("unicorn")
        a.shot("unicorn-home")
        a.accessibility("unicorn-home")
        _ = popBubble(a)
        a.pause(0.25)
        a.shot("unicorn-pop-early")
        a.pause(0.3)
        a.shot("unicorn-pop-late")
    }

    // J10. Fortune: the black ball, the fortune on the card, the mist pop.
    func test10_Fortune() {
        let a = Audit("J10-fortune")
        defer { a.finish() }
        a.launch("fortune")
        a.shot("fortune-home")
        a.accessibility("fortune-home")
        a.labels("fortune-home")
        a.expect("the card shows a fortune", a.any(containing: "Fortune:"), severity: 3)
        _ = popBubble(a)
        a.pause(0.3)
        a.shot("fortune-pop")
    }

    // J11. Moon and Grenade: the ball, its marks and topper, the pop.
    func test11_MoonAndGrenade() {
        let a = Audit("J11-moon-grenade")
        defer { a.finish() }
        for theme in ["moon", "grenade"] {
            a.launch(theme)
            a.shot("\(theme)-home")
            a.accessibility("\(theme)-home")
            _ = popBubble(a)
            a.pause(0.3)
            a.shot("\(theme)-pop")
        }
        a.launch("moon")
        a.check("Moon says Next transmission", a.any(containing: "Next transmission").exists, severity: 2)
    }

    /// The held themes (holiday and novelty) with the name Settings shows for each (`GumPalette.label`).
    private static let heldThemes: [(String, String)] = [
        ("snowball", "Snowball"), ("ornament", "Ornament"), ("pumpkin", "Pumpkin spice"), ("disco", "Disco"),
        ("soap", "Soap bubble"), ("planet", "Planet"), ("basketball", "Basketball"), ("donut", "Donut"),
        ("waterBalloon", "Water balloon"), ("eyeball", "Eyeball"), ("fishbowl", "Fishbowl"), ("moodRing", "Mood ring"),
        ("lavaLamp", "Lava lamp"), ("soccer", "Soccer"), ("hockey", "Hockey puck"), ("tennis", "Tennis ball"),
        ("golf", "Golf ball"), ("baseball", "Baseball"), ("bowling", "Bowling ball"), ("pixel", "8-bit"),
        ("gumball", "Gumball machine"), ("cherry", "Cherry"), ("orange", "Orange"), ("macaron", "Macaron"),
        ("cakePop", "Cake pop"), ("earth", "Earth"), ("sun", "Sun"), ("dandelion", "Dandelion"), ("atom", "Atom"),
        ("geode", "Geode"), ("yarn", "Ball of yarn"), ("arcadeButton", "Big red button"), ("clock", "Clock"),
        ("marble", "Marble"), ("duck", "Rubber duck"), ("easterEgg", "Easter egg"), ("valentine", "Valentine"),
        ("fireworks", "Fireworks"), ("beachBall", "Beach ball"), ("zen", "Zen stone"),
    ]

    /// Reads the theme Settings names (its Theme row) and checks it is the one asked for.
    private func checkTheme(_ a: Audit, _ raw: String, _ label: String, where place: String) {
        let row = a.app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Theme")).firstMatch
        a.reveal(row)
        let shown = row.waitForExistence(timeout: 3) ? row.label : "(no Theme row)"
        a.check("the theme shown is the one asked for", shown.contains(label), severity: 3,
                detail: "asked for \(raw) (\(label)); Settings says \"\(shown)\" (\(place))")
    }

    // J12. Every held theme (holiday and novelty): the ball and the pop, one picture each, on Home with `-theme`
    // (the fortune scene sets Fortune over `-theme`, so every picture showed Fortune before November 18). After the
    // pictures, Settings is opened from Home in the same launch and its Theme row must name the theme asked for.
    func test12_AllThemes() {
        let a = Audit("J12-all-themes")
        defer { a.finish() }
        for (theme, label) in Journeys.heldThemes {
            a.launch("home", theme: theme, settle: 2)
            a.shot("\(theme)")
            a.accessibility("home-\(theme)")
            a.check("the card shows no fortune (only Fortune does)", !a.any(containing: "Fortune:").exists, severity: 3,
                    detail: theme)
            _ = popBubble(a)
            a.pause(0.3)
            a.shot("\(theme)-pop")
            a.pause(1.0)
            let gear = a.app.buttons["home-settings"]
            if gear.exists && gear.isHittable && openSettingsFromHome(a, severity: 2) {
                checkTheme(a, theme, label, where: "same launch as the pictures")
            } else {
                // If the gear can't be tapped, read the theme in the Settings
                // scene instead, which takes `-theme` through the same demo setup as Home.
                a.check("Settings opens from Home to read the theme", false, severity: 2,
                        detail: "\(theme): read from the Settings scene instead")
                a.launch("settings", theme: theme, settle: 2)
                checkTheme(a, theme, label, where: "Settings scene")
            }
        }
    }

    // J13. Edge cases: the screens a person meets on an awkward day, for a sticking-point review.
    func test13_EdgeCases() {
        let a = Audit("J13-edge-cases")
        defer { a.finish() }
        a.launch("missed")
        a.shot("missed-under-new-alarm", note: "New alarm up; the unpopped earlier meeting shows as Also missed with Join")
        a.accessibility("missed")
        // 7.3: the missed line wraps, is at least 44 pt, and its Join is its own button named for the meeting.
        a.expect("the missed line says Also missed", a.any(containing: "Also missed:"), severity: 3)
        let joinOld = a.button(startingWith: "Join ")
        if a.expect("the missed meeting has its own Join", joinOld, severity: 3) {
            a.check("the missed meeting's Join is at least 44 pt", joinOld.frame.height >= 44, severity: 3,
                    detail: "height \(joinOld.frame.height)")
        }
        a.launch("paused")
        a.shot("paused-home", note: "Paused until is the first row of the column; card says Paused until")
        // 7.1: the Paused line is the first row of the column and at least 44 pt tall.
        let pausedRow = a.button(startingWith: "Paused until")
        if a.expect("the Paused line is a button", pausedRow, severity: 3) {
            a.check("the Paused line is at least 44 pt tall", pausedRow.frame.height >= 44, severity: 3,
                    detail: "height \(pausedRow.frame.height)")
            let title = a.any(containing: "Design review")
            a.check("the Paused line is above the card", title.exists && pausedRow.frame.minY < title.frame.minY, severity: 3,
                    detail: "paused \(pausedRow.frame.minY), card \(title.frame.minY)")
        }
        a.launch("outside")
        a.shot("outside-work-hours", note: "Card says Outside work hours, quiet notification")
        a.launch("reminder")
        a.shot("own-reminder-next", note: "An own reminder is next: card label Reminder")
        a.launch("dupes")
        a.shot("duplicate-merged", note: "Design review and its FW copy show as one meeting")
        a.launch("home")
        // Every tap goes through the recorder, so a control that can't be tapped is a failed check, not a stop.
        if a.tap("More", a.app.buttons[Journeys.more]) {
            a.pause(0.8)
            a.shot("more-menu", note: "Add a reminder, Pop for fun, Pause alerts")
            if a.tap("Add a reminder", a.app.buttons["Add a reminder"], timeout: 2) {
                a.pause(1)
                a.shot("add-reminder-sheet")
                a.accessibility("add-reminder")
            }
        }
        a.launch("playground", settle: 3)
        a.shot("pop-for-fun")
        let ball = a.app.descendants(matching: .any).matching(NSPredicate(format: "label ENDSWITH 'bubble'")).firstMatch
        if a.tap("a playground bubble", ball, timeout: 3) {
            a.pause(0.25)
            a.shot("pop-for-fun-popped")
        }
        a.accessibility("playground")
        let round = a.app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Target round")).firstMatch
        if round.waitForExistence(timeout: 2) {
            a.tap("Target round", round)
            a.pause(1.0)
            a.check("the target is named", a.app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Pop only")).firstMatch.exists, severity: 2)
            a.shot("pop-for-fun-target")
        }
    }
}
