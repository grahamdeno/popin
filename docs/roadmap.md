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
| 2026-11-18 | 1.1 scope reopened and frozen again: epic 7 added (Home and the alarm work for everyone). Standing merge go extends to epic 7 | Grok's design review found a severity 4 (big-text Home) and a severity 3 (Not going can't be undone after 5 s) on 1.0; the playbook fixes both before the next release. The M1 Home layout goes in now so Home is rebuilt once |
| 2026-11-18 | 1.2 will honor the widgets' tinted and clear Home Screen modes | It's how iOS draws widgets, not an app dark mode; the app stays light only |
| 2026-11-18 | Pro sheet follows mockup M4 (trio hero, two-column features, price bar, Restore link), in 1.2 | Graham preferred it to the current sheet |
| 2026-11-18 | Settings as a native Form: try one page first (1.2), then decide | Free Dynamic Type and VoiceOver structure against a rebuild and a shift in look |
| 2026-11-18 | Design review inputs: Grok passes 1 and 2 and mockups M1 to M6, in docs/design-review/2026-11-18/ once that PR merges | Reference for epics 7 to 9 |
| 2026-11-16 | 1.1 scope approved and frozen: epic 1, stories 1.1 to 1.4. Items 2 to 6 wait for 1.2. No new purchases | One release that fixes alarm pile-ups; theme work isn't blocked (Fireworks unlocks 2026-12-14 as built) |
| 2026-11-16 | Standing merge go for 1.1: each 1.1 PR merges once its review passes, if the merge uploads and deploys nothing | Graham doesn't approve each PR |
| 2026-11-16 | A clash means meetings that start in the same minute. Partial overlaps are not a clash | Simple and predictable; story 1.3 keeps partial overlaps from ringing together |
| 2026-11-16 | The auto-stop is fixed at 7 minutes in 1.1, not a setting | No new setting; revisit after real use |
| 2026-11-16 | Pop In moves onto the playbook (1.0.0); 1.1 is the first release planned under it | One process across all apps |
| 2026-11-16 | Epic "Ring only when it matters" approved as a 1.1 candidate | Found in real use on 1.0: several alarms rang at once |

## Where things stand (2026-11-18)
- 1.0 (build 1056) approved and live in the US App Store, EU excluded. Grok checked on 2026-11-16: the page,
  subtitle, icon, 8 screenshots, Pop In Pro $6.99 and all three tips are live, and it shows up in search
  (12th for "Pop In Meeting Alarms").
- tangomike.app tag reads "On the App Store" (grahamdeno/tangomike PR #6).
- 2026-11-18: Grok's design review is in; epic 7 added to 1.1. Next: Sonnet fixes the audit walk (7.4).

## Release scope
- **1.1 (approved and frozen 2026-11-16, reopened and frozen again 2026-11-18):** epic 1 "Ring only when it
  matters", stories 1.1 to 1.4, and epic 7 "Home and the alarm work for everyone", items 7.1 to 7.5, in one release.
  New ideas go to 1.2.
- **Waits for 1.2:** items 2 to 6 and 8 to 10 (theme polish, "Pop for fun" feel, Mood ring pop, travel buffer, Watch and Mac).
- **Purchases approved:** none new.
- **Go-aheads:** merge, standing for all 1.1 items (epic 7 included, 2026-11-18) as each passes review, when the merge uploads and deploys nothing
  (2026-11-16). Test build: none yet. Ship: none yet.
- **Target:** rough, not a deadline: after Fireworks drops on 2026-12-14.

## Dated checks
- **Monday 2026-11-30:** Snowball and Ornament unlock in the App Store copy, the first themes on the release
  calendar (GumPalette.releaseDays). Graham checks Settings > Theme on his phone. A scheduled reminder is set.
  If they don't appear, look at releaseDays and seasonsReady.

## Backlog

Items 1 and 7 are in 1.1. Items 2 to 6 and 8 to 10 wait for 1.2.

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

#### 1.2 Alarms stop on their own after 7 minutes
As someone who sometimes joins from another device, I want an unanswered alarm to stop on its own, so my phone
isn't ringing for a meeting I already handled.
- Given an alarm has rung for 7 minutes without a pop, snooze or Not going, then it stops ringing.
- Then the meeting stays on the Lock Screen and in the Live Activity as "Started · Join" until the meeting ends.
- The meeting counts as missed under newest-meeting-wins, the same as today.
- Settled 2026-11-16: 7 minutes is fixed in 1.1, not a setting.

#### 1.3 One alarm at a time
As someone with back-to-back meetings, I want only one Pop In alarm ringing at a time, so when I come back to my
phone I see what needs me now.
- Given an older alarm is still ringing, when a newer meeting's alarm fires, then the older alarm stops.
- Given earlier meetings went unpopped, when the current alarm shows, then they appear as one quiet line
  ("Also missed: 1:00 Standup, 1:00 Design review"), each with Join while it's still running.
- Given that stack, when the user pops or stops the current alarm, then the whole stack clears.
- Given two meetings start at the same minute and no pick was made, then one alarm rings showing both, with a Join
  for each.

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
- Icons are SF Symbols, not emoji. Text on the bubble meets AA contrast.
- Checked by: big-text, small-phone and iPad walk pictures; a walk check that ⋯ and the gear are hittable at XXXL;
  benchmark "Ring before" from Home in 3 taps.

#### 7.2 Bring back a skipped meeting (GR-2, GR-6)
As someone who tapped Not going by mistake, I want to bring the meeting back until it starts, so a slow tap doesn't
cost me the alarm.
- Given I tap Not going, then the toast says "Not going to [title] · Undo". After a pop, it says "Popped [title] ·
  Undo".
- Given the toast has gone, then the meeting shows as a quiet line ("Not going: 3:00 Design review · Undo") until
  it starts.
- Given I tap Undo before the start, then its alarm comes back exactly as it was.
- Nothing is written to the calendar. App state only.
- Checked by: unit tests in Model/ and a walk step that undoes after 10 seconds.

#### 7.3 Alarm screen: clear countdown and controls (D-4, GR-4, GR-7, GR-8; built with story 1.3)
As someone whose alarm is ringing, I want to see how long I have and what each button does, so I act without
thinking.
- The card follows M2: a "Starts in" label, a large countdown, the title, the span and service, then Not going and
  "Snooze 2 min" side by side inside the card.
- At any text size, nothing overlaps the meeting time.
- "Snooze 2 min" is the visible word and the VoiceOver name.
- Story 1.3's "Also missed" line wraps, is at least 44 pt tall, and has its own Join for each meeting.
- Checked by: big-text and small-phone takeover pictures; the Apple accessibility audit on the screen.

#### 7.4 Requirement: the audit walk shows what it claims
- J12 shows each theme, not Fortune (`Journeys.swift` launches the fortune scene, which overrides `-theme`).
- Benchmarks are counted from Home, not from inside Settings.
- J3 pictures the Not going state as well as the Undo.
- A journey that stops early counts as a failed check in SUMMARY.md.
- Checked by: an `[audit]` run with the fixed journeys before 1.1's own audit.

#### 7.5 Requirement: iPad App Store screenshots are upright (GR-3)
- The screenshot pipeline stores landscape iPad frames the right way round before they are published.
- Checked by: the pictures from `screenshots.yml`; Grok on the live store after 1.1 is approved. Publishing and
  uploading happen under 1.1's ship go.

**Out of scope:** the rest of the design review (items 8 to 10, 1.2). A "Join" word on the card: only if 7.1's
scrolling isn't enough at XXXL, and only with Graham's approval.

**Steps:**
1. Settle contrast on the bubble, the SF Symbols and the XXXL Home layout. (Opus.)
2. Fix the audit walk first (7.4), then build 7.1 to 7.3 on their own branches, with tests. (Sonnet.)
3. Review each PR. (Opus.)
4. Phone checks: card style, big text, Undo after the toast. (Graham.)

### 8. Epic: Design polish (approved 2026-11-18, for 1.2, to shape)
- From the review: Settings rows and Pro row (M3), the Pro sheet (M4), the theme gallery (M6, keeping Surprise me and
  the groups), one shared ball highlight (D-11), haptics (D-14), empty state (D-16), pressed buttons (D-19), one PRO
  tag (GR-13), tap areas (GR-14), Pro sheet icons hidden from VoiceOver (GR-12), Add reminder chips (GR-10), iPad
  sizing (GR-15, GR-17), fixed sizes (GR-18), Calendars (D-17), copy on the site and support pages (GR-19).
- Opus shapes; Sonnet builds.

### 9. Epic: Widgets look like the app (approved 2026-11-18, for 1.2, to shape)
- M5: "8 min" as in the app, the big-bubble light, tinted and clear Home Screen modes, text styles (GR-11, D-12), and
  the Live Activity (D-13).
- Opus shapes; Sonnet builds.

### 10. Settings as a native Form: try one page (approved 2026-11-18, for 1.2)
- Rebuild the Alarm page as a `Form`, compare pictures with the current page, then decide (D-8).
- Sonnet builds the trial; Opus and Graham decide.

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
