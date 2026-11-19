# Pop In roadmap

The running plan for Pop In. It follows Graham's playbook (grahamdeno/playbook, version 1.0.0): the process, stages,
roles, rules, item format and standards live there and aren't repeated here. This file holds what's specific to Pop
In: where things stand, decisions, release scope, the backlog and what shipped. docs/plan.md is the history of how 1.0
was decided.

**To pick up the work:** read "Where things stand", then "Decision log", then "Release scope", in that order.

## Product specifics

- **Standing rules:** see CLAUDE.md, "Rules that must never be missed".
- **Uploads and deploys:** see CLAUDE.md, "Uploads and deploys in this repo".
- **Core flow (regression list):** grant calendar access; a meeting rings while the phone is locked; pop to join opens
  the right app; Not going; snooze; quiet hours; buying Pro and restoring purchases (sandbox).
- **Edge cases always checked in Shape:** same-minute meetings, all-day events, quiet hours, paused, Pro versus free,
  big text, iPad, small phone. Light only (no dark mode in 1.0).
- **Guard:** `scripts/read_only_guard.py` enforces read-only Calendar and Reminders and no network or SDKs.
- **Device checks** (the simulator can't prove alarms): alarms ring while locked, Join opens the right app, Live
  Activity and Dynamic Island look right, widgets update, the theme icon switches. Full list in
  docs/audit/ux-audit.md.
- **UX audit:** a commit with `[audit]` runs `ux-audit.yml` in four setups (Pro light, big text, small phone, iPad).
  Findings go in docs/audit/findings.md.
- **Version and build:** `MARKETING_VERSION` in `project.yml`, bumped before the test build. The build number is
  1000 plus the testflight workflow run number.
- **Listing source:** docs/app-store-listing.md. Screenshots: `screenshots.yml`, then `publish-screenshots.yml`
  with the run id (a ship step: it publishes public URLs).
- **Privacy answer:** "Data Not Collected". The page is `site/privacy.html`.
- **Websites:** popin.tangomike.app (`site/` here, deployed by `pages.yml` on merge), tangomike.app
  (grahamdeno/tangomike).
- **Compiled-in dates:** the theme release calendar, `GumPalette.releaseDays` in `App/Shared/GumColors.swift`.
- **EU:** excluded until there's a DSA trader declaration.

## Steps that can't be undone (Pop In extras)

The playbook's list applies. Also:
- **Release calendar dates** in `GumPalette.releaseDays` are compiled into the app. A wrong date can only be fixed by
  shipping another update. Opus checks each one against the real occasion; Graham approves.

## Decision log

Newest first. Refined decisions only.

| Date | Decision | Why |
|---|---|---|
| 2026-11-19 | The seven findings first proposed for later (GR-16, GR-20, GR-21, GR-22, D-15, D-18, D-20) are in 1.1 as stories 8.13 to 8.17 | Graham: handle them in 1.1 |
| 2026-11-19 | A missed alarm goes quiet for up to 15 minutes before the next meeting's alarm rather than risk silencing it | Graham chose the quiet gap (option A): the meeting he can still make always rings |
| 2026-11-19 | Story 1.2 plans on a 15-minute alert (an iPhone alarm rings about 15 minutes, and AlarmKit alarms ring like Clock); no separate phone test | Published measurements; Graham asked not to be given a manual test |
| 2026-11-19 | A missed alarm with no later meeting to hand over to stops when its meeting ends | Graham's decision; it never rings overnight |
| 2026-11-19 | 1.1 carries every finding from Grok's design review: epics 8 to 11 join epics 1 and 7, in one release. Items 2 to 6 stay in 1.2. Epics 8 and 9 are still to shape; each is shaped and read back before it's built, and the scope stays frozen to what they list | Graham: one release; Pop In has no active users yet |
| 2026-11-19 | Story 1.2 changes: a missed alarm keeps ringing at one steady volume until it's dismissed or a later ringing meeting reaches its ring time. The 7-minute auto-stop is dropped | Graham's decision. A missed meeting should never go quiet on its own |
| 2026-11-19 | Graham's written exception for epic 7 and 1.1 (his handoff note, sent in the Pop In Product chat on 2026-11-19): Opus reviews and merges 1.1 work, makes test builds, and after the go-live verdict from a different model (Fable) runs the release triggers, naming each trigger, version and commit in its PR. Graham confirms this allowance in his own message before the first release trigger runs. Nobody reviews their own work. Graham still presses Submit for Review and Release. Deleting, force-pushing, renaming, archiving, transferring, purchases, prices, product IDs, secrets and release-calendar dates stay his | Speed: no active users, one release |
| 2026-11-19 | Benchmark "Find and turn off one calendar" is 4 taps from Home (the gear, Calendars, search, the switch) | Search is the quick way through 22 calendars. The walk on c4a63f1 (run 44508485401) counted 4 in every config; it was 5 before 7.1 |
| 2026-11-19 | Epic 7 step 1 settled: words never sit on the gum (Fortune's fortune excepted); words over the bubble sit on a white plate of at least 90%; ten accent text colors darken; Home's header stays fixed at every text size and the card scrolls over a bubble that keeps its size; "Pop the bubble to join" moves into the alarm card; the card is the white plate unless glass passes Apple's audit on every theme | A script over all 46 themes: white words on the gum fail on 41, one text color per theme fails on 17, a bare "Then" line fails on all 46. On a 90% plate, ink, secondary and every accent text pass 4.5:1 over any color, the darkest theme art included |
| 2026-11-18 | 1.1 scope reopened and frozen again: epic 7 added (Home and the alarm work for everyone). Standing merge go extends to epic 7 | Grok's design review found a severity 4 (big-text Home) and a severity 3 (Not going can't be undone after 5 s) on 1.0; the playbook fixes both before the next release. The M1 Home layout goes in now so Home is rebuilt once |
| 2026-11-18 | 1.2 will honor the widgets' tinted and clear Home Screen modes | It's how iOS draws widgets, not an app dark mode; the app stays light only |
| 2026-11-18 | Pro sheet follows mockup M4 (trio hero, two-column features, price bar, Restore link), in 1.2 | Graham preferred it to the current sheet |
| 2026-11-18 | Settings as a native Form: try one page first (1.2), then decide | Free Dynamic Type and VoiceOver structure against a rebuild and a shift in look |
| 2026-11-18 | Design review inputs: Grok passes 1 and 2 and mockups M1 to M6, in docs/design-review/2026-11-18/ once that PR merges | Reference for epics 7 to 9 |
| 2026-11-16 | 1.1 scope approved and frozen: epic 1, stories 1.1 to 1.4. Items 2 to 6 wait for 1.2. No new purchases | One release that fixes alarm pile-ups; theme work isn't blocked (Fireworks unlocks 2026-12-14 as built) |
| 2026-11-16 | Standing merge go for 1.1: each 1.1 PR merges once its review passes, if the merge uploads and deploys nothing | Graham doesn't approve each PR |
| 2026-11-16 | A clash means meetings that start in the same minute. Partial overlaps are not a clash | Simple and predictable; story 1.3 keeps partial overlaps from ringing together |
| 2026-11-16 | (Superseded 2026-11-19 by the new story 1.2.) The auto-stop is fixed at 7 minutes in 1.1, not a setting | No new setting; revisit after real use |
| 2026-11-16 | Pop In moves onto the playbook (1.0.0); 1.1 is the first release planned under it | One process across all apps |
| 2026-11-16 | Epic "Ring only when it matters" approved as a 1.1 candidate | Found in real use on 1.0: several alarms rang at once |

## Where things stand (2026-11-19)
- 1.0 (build 1056) approved and live in the US App Store, EU excluded. Grok checked on 2026-11-16: the page,
  subtitle, icon, 8 screenshots, Pop In Pro $6.99 and all three tips are live, and it shows up in search
  (12th for "Pop In Meeting Alarms").
- tangomike.app tag reads "On the App Store" (grahamdeno/tangomike PR #6).
- 2026-11-18: Grok's design review is in; epic 7 added to 1.1.
- 2026-11-18: 7.4 merged (#52): the audit walk now shows each theme, counts from Home and lists stopped journeys.
- 2026-11-19: epic 7 step 1 settled (contrast, icons, the large-text Home); criteria added to 7.1 to 7.3.
- 2026-11-19: 7.1 merged (#56), reviewed by Opus. The small-phone audit runs again. 1.1 now carries epics 1 and 7
  to 11 under Graham's written exception. Story 1.2 rewritten (a missed alarm keeps ringing). Next: Opus builds 7.2,
  7.3 and story 1.2, a different model reviews.

## Release scope
- **1.1 (approved 2026-11-16, reopened 2026-11-18 and 2026-11-19, frozen):** epic 1 "Ring only when it matters",
  stories 1.1 to 1.4; epic 7 "Home and the alarm work for everyone", items 7.1 to 7.5; epic 8 design polish; epic 9
  widgets; item 10 Settings as a native Form (one page first); item 11 demo mode saves nothing. One release. New
  ideas go to 1.2.
- **Waits for 1.2:** items 2 to 6 (theme polish, "Pop for fun" feel, Mood ring pop, travel buffer, Watch and Mac).
- **Purchases approved:** none new.
- **Go-aheads:** merge, standing for all 1.1 items as each passes review, when the merge uploads and deploys nothing
  (2026-11-16, 2026-11-18). From 2026-11-19, Graham's written exception (decision log) lets Opus also make 1.1
  test builds and, after the go-live verdict from a different model (Fable), run the release triggers, each named
  with its commit in a PR, once Graham has confirmed that allowance in his own message. Submit for Review and
  Release stay Graham's.
- **Target:** rough, not a deadline: after Fireworks drops on 2026-12-14.

## Dated checks
- **Monday 2026-11-30:** Snowball and Ornament unlock in the App Store copy, the first themes on the release
  calendar (GumPalette.releaseDays). Graham checks Settings > Theme on his phone. A scheduled reminder is set.
  If they don't appear, look at releaseDays and seasonsReady.

## Backlog

Items 1 and 7 to 11 are in 1.1. Items 2 to 6 wait for 1.2.

### 1. Epic: Ring only when it matters (approved 2026-11-16)
**Goal:** Pop In rings only for a meeting that needs the user now. Meetings already handled, skipped or clashing
don't pile up as ringing alarms.

**Context:** found in real use on 1.0. With two meetings at the same start time and a later meeting, all left
unpopped while the user joined from another device, three alarms were ringing at once when he picked up his phone.
The in-app screen already follows "newest meeting wins" (Sprint 29). The likely cause is at the system level: each
meeting has its own AlarmKit alarm, and iOS rings each one separately. Not yet confirmed on a device.
Code check (2026-11-16): `AlarmPlanner` already gives meetings ringing in the same minute one shared alarm. Other
sources of extra alarms: the backup alarm one minute after a ring (set while Pop In is open), the early heads-up
alarm, and snoozes. The device check tells these apart.

**Requirement that still holds:** while an alarm rings, it is a real, loud alarm unless story 1.4 applies. Quieter
ringing must never cost a missed meeting.

#### 1.1 Catch double-booking before it rings
As someone with overlapping meetings, I want Pop In to flag the clash ahead of time and let me pick one, so only
the meeting I choose rings.
- Given two or more ringing meetings start at the same minute, when Home shows them, then it says they clash and
  offers a pick (for example, "2 meetings at 1:00 · Pick one").
- Given the user picks one, then only that meeting rings. The other shows as a quiet line with Join, and no alarm.
- Given the user doesn't pick, then the same-minute meetings ring once together (see 1.3).
- Picking never changes the calendar. Calendar access stays read only.
- Settled 2026-11-16: only meetings that start in the same minute clash. Partial overlaps are not a clash.
- Proposed 2026-11-19 (Opus, from Fable's review), waiting for Graham's yes: the "Not ringing" line also has Undo
  until the meeting starts, so a mis-tapped pick can be reversed, as Not going can (7.2); undone after its ring time,
  its alarm comes up at once. A dropped meeting appears only on that line.

#### 1.2 A missed alarm keeps ringing until it's handled or the next meeting takes over (changed 2026-11-19)
As someone who sometimes misses an alarm, I want it to keep ringing at the same volume until I deal with it or my
next meeting takes over, so a missed meeting never goes quiet on its own and never rings over the next one.
- Given an alarm rang and nobody popped, snoozed, chose Not going or dismissed it, then it keeps ringing at one
  steady volume. It never gets louder or softer. Given iOS mutes the alert on its own, then it rings again within
  60 seconds, at the same volume, unless that repeat would still be sounding when the next meeting's alarm is due.
- Given a repeat would overlap the next meeting's alarm, then it isn't planned: the missed alarm goes quiet for up to
  15 minutes before the next meeting's alarm, so that alarm always rings (Graham chose this, 2026-11-19).
- The ring inside Pop In starts at full volume (the two-minute rise before the start is removed). Story 1.4's
  quieter alarm, when it applies, stays steady at its own level.
- Given the person taps Dismiss on the Lock Screen, then it stops and doesn't ring again for that meeting. The
  meeting stays on Home until it's missed or over, as today. While Pop In is open, its alarm screen keeps ringing
  until the bubble is popped, snoozed or Not going is chosen.
- Given a later meeting that rings reaches its own ring time (the moment its bubble takes over on Home), then the
  earlier alarm stops by itself, and the earlier meeting counts as missed (newest wins, as today).
- Given the later meeting is skipped with Not going, paused, or set to a quiet notification, then it doesn't take
  over: the earlier alarm keeps ringing. The later meeting's early heads-up alarm doesn't take over either; only its
  own ring time does.
- Given two meetings start in the same minute, then they share one alarm (as today), and it follows these rules as
  one.
- Given the person dismisses in the same minute the next alarm comes due, then the earlier alarm stops and the next
  one rings normally.
- Given a snooze, then the meeting rings again after 2 minutes and follows these rules from there.
- Given no later meeting takes over before the missed meeting ends, then the alarm stops when the meeting ends
  (settled by Graham, 2026-11-19).
- How it's built (2026-11-19): AlarmKit has no setting for how long an alert sounds. iPhone alarms ring for about
  15 minutes and then stop on their own, and AlarmKit alarms ring the way Clock does, so Pop In plans on 15 minutes
  (to be confirmed on Graham's phone with the first test build, no separate test). Unlocking the phone takes the
  full-screen alert away, but the alarm keeps sounding until it's stopped from the Live Activity or Pop In is opened.
  Also, a later alarm that fires
  while an earlier one still sounds can be silenced. So Pop In schedules repeat alarms for an unhandled meeting,
  spaced so that none is still sounding when the next meeting's alarm is due. Dismiss on any repeat cancels the
  rest (a stop intent). While Pop In is open it stops the old alarm itself at the handover.
- Build risks to cover: `stopAlerting()` stops every ringing alarm, so a stop at the handover must name the old
  alarm only; `sync()` reschedules any missing alarm, so a dismissed meeting needs its own saved state ("dismissed,
  not cleared"); repeats count against the planner's limit of 24; the one-minute safety backup becomes the first
  repeat; Lock Screen Dismiss needs a stop intent (none today) and can only be checked on the phone.
- Checked by: SimulatedDayTests for each line above (back-to-back meetings, two at the same time, a meeting that
  ends before the next alarm, a dismiss at the handover, a later meeting skipped with Not going, a heads-up that
  doesn't take over); a unit test that no repeat
  is planned to sound within the alert length of the next ring time; a unit test that the in-app ring has no
  volume rise; Graham's phone check of a missed alarm, its repeat after iOS mutes it, a Lock Screen Dismiss, and
  the handover to the next.

#### 1.3 One alarm at a time
As someone with back-to-back meetings, I want only one Pop In alarm ringing at a time, so when I come back to my
phone I see what needs me now.
- Given an older alarm is still ringing, when a newer meeting's alarm fires, then the older alarm stops (1.2 says
  how).
- Given earlier meetings went unpopped, when the current alarm shows, then they appear as one quiet line
  ("Also missed: 1:00 Standup, 1:00 Design review"), each with Join while it's still running.
- Given that stack, when the user pops the current alarm or chooses Not going, then the whole stack clears.
- Given two meetings start at the same minute and no pick was made, then one alarm rings showing both, with a Join
  for each.
- Proposed 2026-11-19 (Opus, from Fable's review), waiting for Graham's yes: popping or Not going on a shared alarm stops the same-minute
  meetings ringing but doesn't clear them; they stay on Home as story 1.1's "Not ringing" line with Join, so a
  meeting is never lost by answering its neighbour. Snooze snoozes them together. A meeting seconds later in the same
  minute never takes over. Undo right after the pop brings everything back; Undo later on the quiet line brings back
  only the skipped meeting.

#### 1.4 Gentler alarms while in a meeting
As someone already in a meeting, I want the next meeting's alarm to be gentle, so it doesn't startle me or
interrupt others while I'm speaking.
- **In a meeting on another device:** given the user popped an earlier meeting that is still running, when the next
  alarm comes due, then the full-screen alarm still shows, but with a quieter sound.
- **In a meeting on the phone:** given the user is on a call on the phone (for example, they tapped Join and the
  meeting app is on a call), when the next alarm comes due, then there is no full-screen takeover. It's a nudge
  instead: a soft sound or haptic with Join.
- Given the earlier meeting has ended, then alarms return to normal.
- Open (check before shaping the build): can Pop In tell that the phone is on a call without network or new data
  collection (for example, through CallKit's call observer)? Can AlarmKit play a quieter alarm, or does it need a
  separate quiet sound file?

**Out of scope:** a "joined elsewhere" button. Revisit if this epic isn't enough.

**Steps:**
1. Reproduce the pile-up on a device and confirm the cause (AlarmKit system alarms, backup alarms, or both). Answer
   the open questions in 1.4 with a small device spike. (Sonnet.)
2. Settle the clash pick, the missed line, the quiet alarm sound and the nudge, and answer the open questions in
   1.1 and 1.2. (Opus, with Graham.)
3. Build it in Model/, with SimulatedDayTests cases for every criterion above. (Sonnet.)

### 7. Epic: Home and the alarm work for everyone (approved 2026-11-18, in 1.1)
**Goal:** every person can reach every control on Home and the alarm screen at any text size, and can change their
mind about a skipped meeting.

**Context:** Grok's design review on 2026-11-18 (pass 1 UX, pass 2 design, mockups M1 and M2; files in
docs/design-review/2026-11-18/) found GR-1 (severity 4: at Accessibility XXXL, Home's header and the only route to
Settings go off screen and nothing scrolls) and GR-2 (severity 3: Not going can be undone for 5 seconds only). The
playbook fixes both before the next release. Home is rebuilt once, in the M1 layout, rather than patched now and
redone in 1.2.

**Rules that hold:** the bubble is the main button; a visible Not going; the Bubble / Steady switch keeps working;
light only; calendar read only.

#### 7.1 Home: new card layout that works at every text size (GR-1, D-1, D-2, D-3, GR-5)
As someone who uses large text, I want Home to fit and scroll, so I can always reach the bubble, Not going and
Settings.
- Given any text size up to Accessibility XXXL, when Home shows the next meeting, then the header (wordmark, ⋯ and a
  gear) stays on screen and the card scrolls if needed.
- Given the meeting gets close and the hint line appears, then the countdown keeps its size; the title wraps instead
  (remove the countdown's `minimumScaleFactor`).
- The card follows M1: one meta row (Next · service on the leading side, Rings… on the trailing side), title, large
  countdown, time span, then a footer with the hint and a Not going button at least 44 pt.
- "Then" is a plain line under the card, not a floating pill.
- The gear opens Settings in one tap. ⋯ keeps Add a reminder, Pop for fun and Pause.
- Steady gets the same countdown and layout.
- A debug-only switch, next to Bubble / Steady, shows the card as glass or near-opaque white (D-5). Graham picks on
  the phone; the other is removed before release.
- Icons are SF Symbols, not emoji (the list below). Text on the bubble meets AA contrast.
- Settled 2026-11-19 (epic 7 step 1):
  - **Contrast.** Given any theme and any bubble size, when words can have the bubble behind them, then they sit on a
    white plate of at least 90% opacity and use ink, secondary or the theme's accent text. Checked by a unit test that,
    for every theme, measures each of those colors on the plate over the theme's light, base and dark colors and over
    black, and requires 4.5:1.
  - Given any theme, then its accent text measures at least 4.5:1 on white and on the plate over black. Ten values
    change: Fishbowl 0B6D97, Gumball machine 1E6B97, Orange A14E0F, Macaron A3446C, Sun 9B5309, Dandelion 546D34,
    Marble 1E6B97, Rubber duck 816004, Easter egg 3A689E, Beach ball B83729.
  - Given any text size, then no words are drawn on the gum, except Fortune's fortune.
  - **Header.** Given Accessibility XXXL, when Home shows a meeting, then the wordmark, ⋯ and the gear stay fixed at
    the top at their normal size on a white backing, each button at least 44 pt, and a long press shows the button's
    name large.
  - **Scrolling.** Given content taller than the space, then the paused line, the card, the "Then" strip and the new
    themes card scroll under the header, and Not going is reachable and at least 44 pt.
  - **Bubble.** Given any text size on iPhone, then the bubble keeps its size (it shows the time left), the card never
    covers the bottom quarter of the screen, and the bubble is hittable there with the column scrolled to the top or
    the bottom. On iPad the bubble sits beside the column, which scrolls at full height.
  - **Countdown.** Given the hint line appears, then the countdown keeps its size. The countdown is 88 pt at the
    default size and grows with text size up to the size where "23 h 59" still fits on one line of the smallest
    supported iPhone.
  - **Card at large sizes.** Given an accessibility text size, then the meta row stacks ("Next · service", then
    "Rings…"), and the footer stacks: the hint, then a full-width Not going.
  - **Then.** Given a meeting after the next one, then "Then [time] · [title]" shows in a quiet strip under the card,
    on the plate. At accessibility sizes the title goes under the time, two lines at most, and the time never breaks.
  - **Paused.** Given alerts are paused, then "Paused until [time] · Resume" is the first row of the column, at least
    44 pt.
  - **Card material.** The card is the white plate. The glass look stays behind the debug switch for Graham's phone
    check, and can only be chosen if Apple's accessibility audit shows no contrast failure on Home for every theme.
  - **VoiceOver.** ⋯ reads "More", the gear reads "Settings", and icons beside words are not read on their own.
- Icons: ⋯ `ellipsis` in a 44 pt circle ("More"); gear `gearshape` ("Settings"); menu `plus` (Add a reminder),
  `circle.hexagongrid` (Pop for fun), `pause` (Pause alerts), `bell` (Resume alerts); Settings leaves the menu;
  paused line `pause.fill`; card `bell.fill` or `bell.slash` beside "Rings…", `hand.tap` beside the hint; new themes
  card `xmark` ("Dismiss"). The mockups' emoji are not used. Theme art emoji stay as decoration, hidden from
  VoiceOver.
- Checked by: big-text, small-phone and iPad walk pictures, and walk checks that ⋯ and the gear are on screen and
  hittable, the bubble is hittable with the column at the top and at the bottom, Not going is reachable, and the
  countdown is the same height at 11 and 9 minutes; the contrast unit test; Apple's audit on Home for every J12
  theme; benchmark "Ring before" from Home in 3 taps.

#### 7.2 Bring back a skipped meeting (GR-2, GR-6)
As someone who tapped Not going by mistake, I want to bring the meeting back until it starts, so a slow tap doesn't
cost me the alarm.
- Given I tap Not going, then the toast says "Not going to [title] · Undo". After a pop, it says "Popped [title] ·
  Undo".
- Given the toast has gone, then the meeting shows as a quiet line ("Not going: 3:00 Design review · Undo") until
  it starts.
- Given I tap Undo before the start, then its alarm comes back exactly as it was.
- Nothing is written to the calendar. App state only.
- Given any text size up to Accessibility XXXL, when the toast shows, then the toast and its Undo are on screen
  (the 2026-11-18 audit drew Undo below the screen edge at XXXL).
- Settled 2026-11-19: given any text size up to Accessibility XXXL, then the toast sits above the bottom edge
  inside the bottom quarter, its message wraps (three lines at most) with Undo on its own row at large sizes, and
  Undo is at least 44 pt. Given the toast has gone, then the "Not going…" line sits in the same strip as "Then", on
  the plate.
- Checked by: unit tests in Model/, a walk step that undoes after 10 seconds, and J2 and J3 Undo at big text.

#### 7.3 Alarm screen: clear countdown and controls (D-4, GR-4, GR-7, GR-8; built with story 1.3)
As someone whose alarm is ringing, I want to see how long I have and what each button does, so I act without
thinking.
- The card follows M2: a "Starts in" label, a large countdown, the title, the span and service, then Not going and
  "Snooze 2 min" side by side inside the card.
- At any text size, nothing overlaps the meeting time.
- "Snooze 2 min" is the visible word and the VoiceOver name.
- Story 1.3's "Also missed" line wraps, is at least 44 pt tall, and has its own Join for each meeting.
- Settled 2026-11-19: the countdown is 96 pt at the default size, under "Starts in". Given a meeting with a link,
  then the card shows "Pop the bubble to join" above the two buttons ("Pop the bubble when ready" without a link).
  No words on the gum (mockup M2 drew them there; they fail contrast on 41 themes). All words follow 7.1's plate
  rule. Given an accessibility text size, then Not going and "Snooze 2 min" stack full width inside the card, each
  at least 44 pt. Icons: `zzz` on Snooze; `clock.badge.exclamationmark` on the missed line, not read on its own; each
  missed meeting's Join reads "Join [title]".
- Checked by: big-text and small-phone takeover pictures; the Apple accessibility audit on the screen.

#### 7.4 Requirement: the audit walk shows what it claims
- J12 shows each theme, not Fortune (`Journeys.swift` launches the fortune scene, which overrides `-theme`).
- Benchmarks are counted from Home, not from inside Settings.
- J3 pictures the Not going state as well as the Undo.
- A journey that stops early counts as a failed check in SUMMARY.md.
- Checked by: an `[audit]` run with the fixed journeys before 1.1's own audit.
- Done 2026-11-18 (#52), walk on 57f9d4e. Known limit until 7.1: the ⋯ menu often doesn't open Settings in the
  iPad and small-phone walks, so those benchmarks are mostly not done.

#### 7.5 Requirement: iPad App Store screenshots are upright (GR-3)
- The screenshot pipeline stores landscape iPad frames the right way round before they are published.
- Checked by: the pictures from `screenshots.yml`; Grok on the live store after 1.1 is approved. Publishing and
  uploading happen under 1.1's ship go.

**Out of scope:** the rest of the design review (items 8 to 10, 1.2). A "Join" word on the card: only if 7.1's
scrolling isn't enough at XXXL, and only with Graham's approval.

**Steps:**
1. Settle contrast on the bubble, the SF Symbols and the XXXL Home layout. (Opus.) Done 2026-11-19.
2. Fix the audit walk first (7.4), then build 7.1 to 7.3 on their own branches, with tests. (Sonnet.)
3. Review each PR. (Opus.)
4. Phone checks: card style, big text, Undo after the toast. (Graham.)

### 8. Epic: Design polish (approved 2026-11-18, in 1.1, shaped 2026-11-19)
Goal: the rest of the app matches the care of Home and the alarm. From Grok's design review (D-7, D-9 to D-11,
D-14, D-15, D-16, D-17, D-18, D-19, D-20; GR-10, GR-12 to GR-22). Every finding is in 1.1 (Graham, 2026-11-19). Steps: Opus builds each story on its own branch; Fable reviews; one audit walk before the test build.

#### 8.1 Settings rows show their values (D-7, M3)
- Given Settings, then every row that opens a choice shows its current value on the right in secondary ("2 min",
  "Pop", "Bubblegum").
- Given Pro isn't owned, then the Pro row shows three theme balls, two lines of text and a black capsule with the
  price from the App Store (never a price written into the app). Given Pro is owned, the capsule is gone.
- Checked by: J6 labels (each row's value); the price comes from StoreKit (review).

#### 8.2 Pro sheet (D-9, M4, GR-12)
- Given the Pro sheet, then it shows a centred trio of theme balls, a centred title and one line, the features in two
  columns (one column at accessibility sizes), and a bar fixed at the bottom, on the plate (epic 7's card rule), with "[price] One time · no
  subscription", a 56 pt "Unlock Pro" and a "Restore purchase" link.
- The price comes from the App Store. The feature icons are hidden from VoiceOver; each feature reads as its words.
- Given a purchase or restore succeeds, then the phone gives a success tap.
- Checked by: J6 pro-sheet picture and labels; Apple's audit reports no "description" items on the sheet.

#### 8.3 Theme gallery (D-10, M6)
- Given the gallery, then each theme is a 64 pt ball with no box. The chosen one has a 2 pt ink ring and VoiceOver
  reads it as selected. A locked theme shows the "Pro" pill. Surprise me and the groups stay.
- Given a theme is picked, then the phone gives a selection tap.
- Given the largest text, then names wrap under the balls and nothing is clipped.
- Checked by: J12 and J6 gallery pictures; a walk check that the chosen theme reads "selected"; Graham's phone check
  of the tap.

#### 8.4 One way to mark Pro (GR-13)
- Given anything that needs Pro, then it's marked with the small "Pro" pill, a word. No "✦" and no "(Pro)" anywhere.
- The pill is a white word on the theme's accent color and measures at least 4.5:1 on every theme.
- Checked by: walk labels on every Settings page contain no "✦" or "(Pro)"; review.

#### 8.5 One light on every ball (D-11)
- Given a small ball (Settings, the Pro sheet, the gallery), then it has the same gloss streak and window as the big
  bubble, scaled to its size.
- Checked by: gallery and Pro sheet pictures.

#### 8.6 Taps you can feel and see (D-14, D-19)
- Given Undo, then a light tap; given a theme pick, a selection tap; given an unlock, a success tap. The alarm's own
  buzz is unchanged.
- Given a button is pressed, then it shrinks slightly (0.97) and dims (0.9). With Reduce Motion it only dims.
- These taps follow the iPhone's own System Haptics setting, not Pop In's "Buzz as it gets close" (that one is the
  alarm's buzz).
- Checked by: unit test of the pressed-state values with and without Reduce Motion; Graham's phone check of the taps.

#### 8.7 Nothing coming up (D-16)
- Given no meeting ahead, then Home shows a centred empty state on the plate: "Nothing coming up" (22 pt semibold at
  the default size, scaling with text size), one line, and "Try a pop" as a text button. The resting bubble below
  stays as it is today (not tappable).
- Checked by: J8 picture; a walk check that "Try a pop" is at least 44 pt.

#### 8.8 Tap areas and text that grows (GR-14, GR-18)
- Given Calendars or Work hours, then each calendar's mode menu and each work-day circle is at least 44 pt (the look
  stays the same; the tap area grows).
- Given the largest text, then "Pop In can't see your calendar" grows with it, and the fortune words grow up to a cap.
  The wordmark stays fixed.
- Checked by: walk checks on the frames; Apple's audit reports no "dynamicType" item for those two texts.

#### 8.9 iPad (GR-15, GR-17)
- An iPad amendment to 7.1: given a regular-width iPad, then Home's countdown is 110 pt at the default size (growing
  with text size up to 7.1's one-line cap), and the card sits centred vertically beside the bubble. When the column is
  taller than the space it scrolls from the top under the header, as in 7.1. First run's column is at most 640 pt
  wide, centred.
- Checked by: iPad pictures (J1, J2, J4).

#### 8.10 Add a reminder (GR-10)
- Given the Add reminder sheet, then the time can be set with "In 15 min", "30 min", "1 hour" or "Pick a time".
- Given no title, then Add is disabled. Given your reminders list, then an Edit button deletes without a swipe. The
  footer says "this device".
- Checked by: unit test of the chip times; J13 picture and checks (Add disabled, Edit present).

#### 8.11 Calendars read calmly (D-17)
- Given Calendars, then each switched-on calendar row ends with its mode in secondary ("Smart", "Always rings",
  "Quiet") and a small chevron, one tappable menu of at least 44 pt. The accent color is gone from these labels.
  Switches are ink. Calendar dots are 10 pt. Still read only.
- Checked by: J7 picture; the read-only guard.

#### 8.12 The site and support pages use the app's words (GR-19)
- Given popin.tangomike.app and its support page, then they say Smart, Always rings and Quiet; "Open" for the Lock
  Screen; and the alarm screen's alt text names the bubble, Not going and Snooze.
- This deploys the site (`site/**`): it ships with 1.1 as a release trigger, after Graham confirms the ship allowance.
- Checked by: review of `site/` against the app's strings.

#### 8.13 Your own reminders say Skip (GR-16)
- Given your own reminder (or a timed one from Reminders) is next, then its card, its VoiceOver action, the alarm screen, the toast ("Skipped [title]
  · Undo"), the quiet line ("Skipped: [time] [title]") and its Undo label say "Skip" or "Skipped" instead of "Not
  going". Meetings keep "Not going" unchanged.
- Checked by: J13 own-reminder scene: "Skip" shows and "Not going" doesn't; a unit test of the words.

#### 8.14 First run in fewer steps (GR-21, D-18)
- Given a first run, then the hello screen and the calendar screen are one: "Never miss the start of a meeting", the
  reason Pop In needs the calendar, and "Allow calendar access". First run takes one tap fewer.
- The card sits in the top third, and the bubble is fully visible above the buttons.
- Checked by: J1 pictures; the walk's first-run tap count is one lower than today.

#### 8.15 Theme in the ⋯ menu (GR-20)
- Given the ⋯ menu, then "Theme" opens the theme gallery directly.
- Checked by: a walk check and benchmark "Change the theme" in 3 taps from Home: ⋯, Theme, a theme (it applies
  when the sheet closes).

#### 8.16 Motion that links the toast to the card (D-15; the glass morph is left out, since cards are on the plate)
- Given a pop or a skip, then the toast rises from the bottom edge with a quick, firm spring. Given an alarm is set,
  then the bell beside "Rings…" wiggles once. With Reduce Motion, both simply appear.
- Checked by: review; Graham's phone check.

#### 8.17 The site looks like the app (GR-22, D-20; the store pictures follow the brand sheet in 7.5)
- Given popin.tangomike.app, then the hero and "How it works" are white with the bubble's pink, and the dark band is
  used only for Pro and the price. A one-page brand sheet (`docs/brand.md`) records the white ground, ink #141414,
  the bubble as the only color mass, and the type. Pink words on white measure at least 4.5:1.
- This deploys the site: it ships with 1.1 as a release trigger, after Graham confirms the ship allowance.
- Checked by: a picture of the site at 1280 and 390 wide; review of `site/` and `docs/brand.md`.

### 9. Epic: Widgets look like the app (approved 2026-11-18, in 1.1, shaped 2026-11-19)
Goal: the widgets and the Live Activity read like Home, on every Home Screen look. From GR-11, D-12, D-13 (M5).
The widgets stay light on a dark Home Screen (light only). Steps: Opus builds; Fable reviews; Graham checks them on
his phone with the test build. The audit walk doesn't reach widgets, so the phone check is the check.

#### 9.1 The count reads like the app (D-12)
- Given a widget, then the count says "8 min" with the unit in secondary, refreshed each minute (no ticking seconds),
  and the ball has the big bubble's light.
- Checked by: unit tests of the count text and that timeline entries come a minute apart; Graham's phone check.

#### 9.2 Tinted and clear Home Screens (GR-11)
- Given a tinted or clear Home Screen, then the widget drops its white fill, draws the ball as an outline, and marks
  the ball and count to take the tint. Text uses text styles, not fixed sizes.
- Checked by: Graham's phone check on a tinted and a clear Home Screen.

#### 9.3 Live Activity (D-13)
- Given the Lock Screen, then the Live Activity shows the title (17 pt semibold at the default size, scaling), a count
  (34 pt at the default size, scaling) and a thin progress bar in the accent. The compact Dynamic Island shows a small
  ball and "8m".
- Checked by: Graham's phone check.

### 10. Settings as a native Form: try one page (approved 2026-11-18, in 1.1)
- Rebuild the Alarm page as a `Form`, compare pictures with the current page, then decide (D-8).
- Sonnet builds the trial; Opus and Graham decide.

### 11. Requirement: demo mode saves nothing (approved 2026-11-18, in 1.1)
- Starting Pop In in demo mode (`-screenshots`) leaves the saved settings unchanged, including the theme and Surprise
  me. Today the theme is saved (the `gumColor` didSet runs in `init`) and a saved Surprise me is kept, though
  `docs/audit/ux-audit.md` says demo mode saves nothing.
- Checked by: a unit test that starts each demo scene and compares the saved settings before and after.
- Out of scope: changing what demo mode shows.
- Steps: Sonnet builds with the test; Opus reviews.

### 2. Polish each theme before its drop (from the 1.0 handoff)
- Polish each theme ahead of its Monday on the release calendar. Next dates: Fireworks 2026-12-14, Duck 2027-01-04.
- Opus for look and feel; Sonnet to build.

### 3. Tune how "Pop for fun" feels (from the 1.0 handoff)
- Opus.

### 4. Give Mood ring its own pop (from the 1.0 handoff)
- Opus for the feel; Sonnet to build.

### 5. Travel buffer (held until after 1.0)
- Ring earlier for meetings that have a location. Needs a decision on how the buffer is set.
- Opus to decide; Sonnet to build.

### 6. Watch and Mac apps (later)
- The Mac app would also fix a known iOS limit: when the phone is unlocked, AlarmKit shows a banner, not a full
  screen.
- Large. Plan separately before building.

## Small follow-ups
- tangomike.app: add an App Store link to Pop In's entry now that the store page is live. Not yet approved.

## Shipped
- 1.0 build 1056, approved 2026-11-16.
