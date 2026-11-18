# Pop In UX audit

Adapted from Shoebox (`docs/audit/08-ux-audit.md` there). Run by `.github/workflows/ux-audit.yml` on a branch commit
whose message contains `[audit]`, or by hand. The report (pictures, checks, timings, Apple's accessibility audit,
contact sheets) lands on the `ci-audit` branch as `SUMMARY.md` and `sheets/`.

## Layers

| Layer | Question | Who | Evidence |
|---|---|---|---|
| 1. Walk | Does every step work? | XCUITest in the CI simulator (`App/PromptlyUITests/Journeys.swift`) in demo mode | A check and a picture per step |
| 2. Expert review | Is each step clear, findable, calm and friendly? | Opus reading the pictures against the rubric | Findings rated 1 to 4, in `docs/audit/findings.md` |
| 3. People | Can a stranger do it? | Graham's phone checks, then five TestFlight testers | Task success, ease 1 to 7 |

## Journeys

| # | Journey | What it walks |
|---|---|---|
| J1 | First run | Hello, calendars why, alarms why, which calendars, covered, Home |
| J2 | Home, minutes away | Read the card, pop to join, Undo |
| J3 | Not going | Not going (a picture of the meeting put away, with Undo up), Undo, the meeting is back |
| J4 | Home, a day away | The calm state |
| J5 | Takeover and late | Ringing screen; 50 s and 75 s after the ring (buds); pop |
| J6 | Settings (free) | From Home: More, Settings, Ring before, 2 minutes (the benchmark). Then every row opens and comes back; Sound; Pop sound; a locked theme opens Pro; Restore |
| J7 | Many calendars | 22 calendars in 5 accounts. From Home: More, Settings, Calendars, search "soccer", switch one off. From Home again: turn a whole account off |
| J8 | Nothing coming up | Empty Home, Try a pop |
| J9 | Unicorn | Bubble, pop with confetti, sprinkles and unicorns |
| J10 | Fortune | Black ball, the fortune on the card, the mist pop |
| J11 | Moon and Grenade | Each ball and its pop; Moon says "Next transmission" |
| J12 | Every held theme | For each of the 40 holiday and novelty themes: Home with that theme, the pop, then Settings' Theme row must name the theme asked for |
| J13 | Edge cases | Missed under a new alarm, paused, outside work hours, own reminder, merged duplicate, the More menu, Add a reminder, Pop for fun |

**Benchmarks** (`docs/audit-benchmarks.json`) are counted from Home, the way a person starts, and include the taps to
reach Settings. The targets stay as set, so a job that costs more from Home shows as over target until the app
changes (7.1 adds a Settings button on Home).

**A journey that stops early** (an exception ends it before its last step) is listed under Failed checks in
SUMMARY.md, with the last picture it took and the first error in the test log. A journey missing from one config is
listed too. A control drawn off the screen is a failed check, and the walk goes on.

Demo mode: `-screenshots -scene <name>` (`App/Promptly/App/ScreenshotMode.swift`), `-free` for the free version.
No calendar, no alarms, no system prompts, nothing saved.

Not walked: the Lock Screen alarm and its sound, widgets, Live Activity, a real purchase, VoiceOver, Reduce Motion
and Reduce Transparency. These go to the phone checks.

## Configs

pro-light (iPhone 17 Pro), big-text (Accessibility XXXL), small-phone (iPhone SE or 16e), ipad (iPad Pro 13",
landscape). Pop In is light only, so there is no dark run.

## Rubric

Severity: 4 blocks the task, 3 a person will stumble, 2 slows or confuses, 1 cosmetic.

1. Can a first-time person tell what to do next, without help?
2. Does every action say what it did, and can it be undone?
3. Is every gesture also a visible word and a VoiceOver action? (The bubble is a button; Not going is a word.)
4. Do words read over the bubble at every size and color, Unicorn included?
5. Does text grow with the person's text size without clipping or overlap?
6. Is anything shown that the person did not need at that moment?
7. Does the copy say what it means in plain, friendly words? No jargon, no em-dashes.
8. Is the list short enough to scan? Long lists are grouped, folded or searchable.
9. Is every target at least 44 pt, and does nothing jump under a finger?

Pop In's own rules: calm white; the bubble is the main button; a visible Not going; Bubble/Steady switch still works;
Pro choices marked and open the Pro sheet, never a dead end.

## Phone checks (Graham, before testers)

1. Lock the phone and let a test alarm ring (Settings, tap the version line 5 times, Ring in 20 s): full screen,
   through Silent; the sound loops; Open joins and stops it.
2. Force-quit Pop In, then wait for an alarm: it still rings.
3. VoiceOver on Home: the card, the bubble ("Pop the bubble to join …") and Not going are read; Join and Not going
   are actions.
4. Reduce Motion: no wobble or buds; the pop fades.
5. Largest text: Home, the takeover and Settings read without broken words.
6. Pro: Test the purchase works; Unicorn, Popcorn and Chimes unlock.

## Testers (five, no help first; ease 1 to 7 after each)

1. Make Pop In ring 5 minutes before meetings.
2. Your soccer calendar shouldn't ring. Stop it.
3. A meeting is about to start. Join it from Pop In.
4. You don't plan to go to the next meeting. Make Pop In leave it alone. Then change your mind.
5. Change the bubble's color.

## Runs

| Date | Commit | Result |
|---|---|---|
| Nov 11 | 7421ca1 | First walk, 4 configs, 36 journeys. Found UX-1 to UX-11 (findings.md), led by first run blocked at large text. |
| Nov 11 | 87fdd95 | Final code, 4 configs, 36 journeys. UX-1 to UX-11 hold (first run completes at the largest text). New, small: at the largest text the Pro row squeezes and the Rings line cuts off (PR #19). The rest is test-side: big-text Settings walk loses its rows off screen; Skip counts the Undo tap. |
| Nov 14 | 08de82d | 4 configs, 52 journeys. SUMMARY.md said no failed checks, but the walk had three faults found later (Grok, Nov 18): every J12 picture showed Fortune, the Settings benchmarks were counted from inside Settings, and big-text J13 stopped after picture 05 without being listed. Fixed in 7.4. |
| Nov 18 | be557fe | 3 configs (small-phone got no runner), 39 journeys. J12 shows 40 different balls and never the wrong theme, J3 has its Not going picture, and big-text J13 finishes; stopped journeys are now listed. Not a pass yet: the Settings sheet opened too slowly for the Theme row in 10 of 40 themes (pro-light) and 6 (ipad), and a menu item's moving frame stopped pro-light J6 and ipad J13 early, both test-side and fixed in review. A simulator fault stopped pro-light J7. |
| Nov 18 | b521ccd | 4 configs (small-phone on a retry of that job), 52 journeys. pro-light is clean: benchmarks from Home read Ring before 4 against 3, find a calendar 5 against 3, turn off an account 4 against 1, and J12 names the theme asked for in all 40 in pro-light, small-phone and ipad (a few read from the Settings scene because the More menu didn't open Settings). The review's tap change stopped the oversized bubble from being popped at the largest text and stopped ipad J2 early; put back in the next commit. |
