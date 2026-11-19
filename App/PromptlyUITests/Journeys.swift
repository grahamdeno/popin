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

    private static let more = "More: add a reminder, pop for fun, pause alerts, settings"

    /// From Home to Settings the way a person gets there: the More menu, then Settings. Two taps, counted.
    @discardableResult
    private func openSettingsFromHome(_ a: Audit, severity: Int = 3) -> Bool {
        guard a.tap("More", a.app.buttons[Journeys.more], severity: severity) else { return false }
        a.pause(0.6)
        guard a.tap("Settings (in More)", a.app.buttons["Settings"], severity: severity) else { return false }
        // The sheet rises after the menu closes. Wait for it, so the next query doesn't run against Home: J12 lost
        // the Theme row in 10 of 40 themes without this wait (pro-light, November 18).
        return a.expect("Settings opens", a.app.navigationBars["Settings"], timeout: 5, severity: severity)
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
        a.expect("Settings is reachable", a.app.buttons["More: add a reminder, pop for fun, pause alerts, settings"], severity: 3)
        a.begin("Join the next meeting")
        let ok = popBubble(a)
        a.pause(0.3)
        a.shot("popping", note: "mid-pop")
        let undo = a.app.buttons["Undo"]
        a.done("Join the next meeting", ok)
        // Undo lasts 5 s; tap it first and take the pictures after, so slow UI queries can't outlast it.
        a.check("Undo is offered after the pop", undo.waitForExistence(timeout: 2), severity: 3)
        a.begin("Undo a pop")
        a.tap("Undo", undo)
        a.pause(1.2)
        a.shot("after-undo")
        a.done("Undo a pop", a.any(containing: "Pop the bubble to join Design review").waitForExistence(timeout: 3))
    }

    // J3. Not going, then Undo.
    func test03_NotGoing() {
        let a = Audit("J3-not-going")
        defer { a.finish() }
        a.launch("home")
        a.begin("Skip a meeting")
        a.tap("Not going", a.app.buttons["Not going"], severity: 4)
        // Skipping is one tap; Undo is a separate job. Undo lasts 5 s, so tap it before any slow picture.
        let undo = a.app.buttons["Undo"]
        let offered = undo.waitForExistence(timeout: 2)
        a.done("Skip a meeting", offered)
        // The Not going state itself, while Undo is still up (a picture is quick; the slow checks wait until after).
        a.shot("not-going", note: "Design review is put away; Undo is offered")
        a.check("Undo is offered", offered, severity: 3)
        a.check("Undo is still up after the picture", undo.exists, severity: 2)
        a.tap("Undo", undo)
        a.pause(0.8)
        a.shot("after-undo")
        a.check("the meeting is back", a.any(containing: "Design review").waitForExistence(timeout: 3), severity: 3)
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
        a.launch("late", settle: 3)
        a.shot("late-50s", note: "50 s after the ring: the first bud should be out")
        a.pause(25)
        a.shot("late-75s", note: "75 s after the ring: two or three buds")
        a.begin("Pop the late bubble")
        a.done("Pop the late bubble", popBubble(a))
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
        a.reveal(popSound, tries: 12)
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
        a.tap("Try a pop", a.app.buttons["Try a pop"], severity: 3)
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
            a.check("the card shows no fortune (only Fortune does)", !a.any(containing: "Fortune:").exists, severity: 3,
                    detail: theme)
            _ = popBubble(a)
            a.pause(0.3)
            a.shot("\(theme)-pop")
            a.pause(1.0)
            let more = a.app.buttons[Journeys.more]
            if more.exists && more.isHittable && openSettingsFromHome(a, severity: 2) {
                checkTheme(a, theme, label, where: "same launch as the pictures")
            } else {
                // At the largest text More is drawn off the screen (Home header, 7.1). Read the theme in the Settings
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
        a.shot("missed-under-new-alarm", note: "New alarm up; the unpopped earlier meeting shows as Missed with Join")
        a.accessibility("missed")
        a.launch("paused")
        a.shot("paused-home", note: "Paused until pill under the header; card says Paused until")
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
            a.shot("more-menu", note: "Add a reminder, Pop for fun, Pause alerts, Settings")
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
