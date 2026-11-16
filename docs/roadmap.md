# Pop In product plan: 1.1 and beyond

The running plan from 1.0 forward. It has two parts: **how we ship** (the checklist every change runs through, from
idea to release) and **what's next** (the roadmap). Build from this file. docs/plan.md stays as the history of how
1.0 was decided; read it for context, but this file says what comes next and how.

## The team
| Who | Does |
|---|---|
| **Graham (owner)** | Decides what gets built, ranks the list, tests on his phone, says "ship", presses Submit for Review and Release. |
| **Claude, Opus** | Feel, wording, design, data safety, judgment calls, reviewing the audit pictures, writing this plan. |
| **Claude, Sonnet** | Building, tests, CI, PRs and merges, docs updates, the websites (repo side). |
| **Grok** | Anything in a browser or account Claude can't reach: App Store Connect, the live App Store, device-side checks Graham hands off. Always reports back in chat. |

## How we ship: idea to release

Every change, from a one-line fix to a big feature, goes through these stages in order. Small changes can move
through a stage quickly, but they don't skip it. Each stage ends at a gate. Don't start the next stage until the
gate is met.

> **Steps that can't be undone, and who does them**
> - **Pushing to the `testflight` branch** uploads a build to TestFlight. Claude does this only after Graham says ship.
> - **Submit for Review** in App Store Connect. **Graham only.** Agents stop right before it.
> - **Release** (when manual release is chosen). **Graham only.**
> - **New or changed in-app purchases or prices.** These go live with the version. Graham approves each one.
> - **Release calendar dates** (GumPalette.releaseDays). These are compiled into the app, so a wrong date can only be
>   fixed by shipping another update.
> - **Deleting** anything: branches with unmerged work, App Store Connect items, website pages. Ask first.

### Stage 1. Idea
- [ ] Claude turns what Graham raised into a backlog item (see "How items are written" below) and briefs it back
      to him in chat. Graham's own words never go into this file.
- [ ] State the problem as the user feels it, not the fix.
- [ ] Check it against the 1.0 rules: read-only calendar and Reminders, no network, no analytics, nothing leaves the phone.
      An idea that breaks one of these goes back to Graham as a decision, not a task.
- **Gate:** Graham approves the brief-back. Then it's added here with the date approved.

### Stage 2. Shape (Opus)
- [ ] Reproduce the problem first if it's a bug (on a device or in SimulatedDayTests). Write down what's actually happening.
- [ ] Decide the behavior, the wording and the look. Use plain words, one decision per screen, the calm white style.
- [ ] Mock it up on the design canvas if it's visual.
- [ ] List the edge cases: same-minute meetings, all-day events, quiet hours, paused, Pro vs free, big text, iPad,
      small phone, light and dark.
- [ ] Decide what's free and what's Pro.
- [ ] Note any App Store impact: new screenshots, listing text, review notes, in-app purchases.
- [ ] Note any website impact: popin.tangomike.app, tangomike.app.
- **Gate:** Graham approves the shape. Record the decision here with the date.

### Stage 3. Plan the release (Graham decides, Opus proposes)
- [ ] Opus proposes the scope: which shaped items go into this version, in order, and what waits. Weigh user pain,
      size, risk to alarms, and dated drops on the release calendar.
- [ ] Graham picks the scope. Record it under "Release scope" below, with the version number and the date.
- [ ] **Freeze the scope.** New ideas found during the build go to Stage 1 for the next version. They join this one
      only if Graham explicitly swaps something out, or if it's a fix for a bug this release introduced.
- [ ] Set a rough target, not a deadline: the next themed drop that needs code, or "when it's ready."
- [ ] Everything in scope ships together as one release.
- **Gate:** scope recorded and frozen.

### Stage 4. Build (Sonnet)
- [ ] Branch from main. One branch per item in the frozen scope. Merging to main is fine; nothing ships until Stage 7.
- [ ] Put business rules in Model/, unit tested, separate from views.
- [ ] Add or update tests: unit tests for the rule, SimulatedDayTests for alarm timing, UI journeys for new screens.
- [ ] Keep the Bubble / Steady switch and a visible "Not going" working.
- [ ] Run `xcodegen generate`. Never edit Promptly.xcodeproj by hand.
- [ ] CI must be green: build.yml (read-only guard, build, all tests).
- **Gate:** green CI, with the test results recorded in the PR. Never claim a pass that wasn't run.

### Stage 5. Test
- [ ] **Automated** (CI): unit tests, SimulatedDayTests, read-only guard.
- [ ] **UX audit** (Sonnet runs it, Opus reviews): push a commit with `[audit]` in the message. ux-audit.yml walks
      the journeys in four setups (Pro light, big text, small phone, iPad). Opus rates the pictures and logs findings
      in docs/audit/findings.md. Fix anything rated 3 or 4 before shipping.
- [ ] **Accessibility:** Apple's accessibility audit (part of the UX audit), VoiceOver labels on new controls, Dynamic Type.
- [ ] **On a real device** (Graham, or a checklist Graham hands to Grok): alarms actually ring while the phone is
      locked, Join opens the right app, Live Activity and Dynamic Island look right, widgets update, and the theme
      icon switches. The simulator can't prove alarms.
- [ ] **Regression:** the core flow still works: grant calendar access, a meeting rings, pop to join, Not going,
      snooze, quiet hours, buying Pro and restoring purchases (sandbox).
- [ ] **TestFlight** for anything that touches alarms, purchases or permissions. Graham lives on the build for at
      least a day of real meetings.
- **Gate:** Graham says ship.

### Stage 6. Prepare the release (Sonnet, with Opus for words)
- [ ] Bump `MARKETING_VERSION` in project.yml (1.1, 1.2 and so on). The build number is set automatically
      (1000 + the testflight workflow run number).
- [ ] Write "What's New" for the App Store: short, plain, what changed for the user.
- [ ] Update docs/app-store-listing.md if the description, promotional text, keywords or review notes change.
- [ ] New screenshots if the UI in them changed: run screenshots.yml, then publish-screenshots.yml with the run id,
      so Grok can upload them.
- [ ] Review notes: tell Apple anything that's hard to find: new purchases, date-locked themes, demo steps.
- [ ] Privacy: confirm the App Privacy answers ("Data Not Collected") are still true. Update site/privacy.html if anything changed.
- [ ] Release calendar: check every new or changed date in GumPalette.releaseDays against the real occasion.
- [ ] Docs: move the item to "Shipped" below, update CLAUDE.md if a rule changed, and add any new known issues.
- **Gate:** Graham reviews the What's New text and any listing changes.

### Stage 7. Upload and submit
- [ ] Claude merges to main, then pushes main to `testflight`. **This uploads the build.** Only after "ship".
- [ ] Tell Graham what to expect: the build shows up in App Store Connect in about 15 to 30 minutes, after processing.
      Don't sit and wait for it.
- [ ] Grok (prompt from Claude) fills in App Store Connect: new version, select the build, What's New, listing changes,
      screenshots, review notes, export compliance ("None"), and leaves the EU setting as it is unless Graham changed it.
      **Grok stops before Submit for Review.**
- [ ] **Graham presses Submit for Review.**
- **Gate:** status shows Waiting for Review.

### Stage 8. Review and release
- [ ] If Apple rejects it: Graham pastes the message, Opus decides the response, Sonnet fixes it, and we go back to Stage 7.
- [ ] On approval: release (automatic, or **Graham presses Release** if manual was chosen).
- [ ] Grok checks the live store: page, version, What's New, screenshots, prices, and search.
- [ ] Websites (Sonnet): update popin.tangomike.app (site/ in this repo, deployed by pages.yml on merge) and
      tangomike.app (grahamdeno/tangomike) if features, screenshots or status changed. Check that support.html
      still answers the real questions.
- [ ] Tag the release in git: `v1.1` on the commit that was shipped.
- **Gate:** live in the store, with the sites matching.

### Stage 9. After release
- [ ] Watch the first week: App Store Connect crash reports, ratings and reviews (Grok can pull these).
      Opus drafts replies to reviews and Graham approves them.
- [ ] Turn real problems into ideas (Stage 1) with the date.
- [ ] Dated checks: confirm each release-calendar drop actually unlocks on its Monday.
- [ ] Update "Where things stand" in this file.

### What else to keep in mind
- **Apple account:** the developer membership renews every year, and agreements, tax and banking must stay current
  or sales stop.
- **New iOS versions:** each September, test on the new iOS beta before it ships (AlarmKit and Liquid Glass change).
- **EU:** excluded until there's a DSA trader declaration. Revisit if Graham wants EU sales.
- **Support email** and the support page must work.
- **Secrets** (signing, App Store Connect key) live in GitHub Actions secrets. Never print or commit them.

## Rules for this file
- Add items only after the owner approves a brief-back. Never paste the owner's own words here; write the refined item.
- Record the date each item was approved.

## How items are written
- **Epic** for a large area of work that holds several stories (for example, Watch app).
- **User story** for one change a user notices: "As a [user], I want [behavior] so that [outcome]."
- **Acceptance criteria:** testable statements, written as Given / When / Then where it helps. These become the tests.
- **Requirement** for a rule the app must always follow (for example, read-only calendar access).
- **Each item also has:** context (what we know and the likely cause), out of scope, open questions, and steps
  with the model each step needs (Opus for feel, data safety and judgment; Sonnet for building and shipping).
- Items carried over from the 1.0 handoff stay short until they're shaped (Stage 2). Then they get the full format.
- When an item ships, move it to "Shipped" with the version and build. Don't delete it.
- Nothing ships until the owner says ship. He prefers one big release over several small ones.
- The 1.0 rules in CLAUDE.md still apply: calendar and Reminders stay read only, no network, keep the
  Bubble / Steady switch, keep a visible "Not going", and never press Submit for Review.

## Where things stand (2026-11-16)
- 1.0 (build 1056) approved and live in the US App Store, EU excluded. Grok checked on 2026-11-16: the page,
  subtitle, icon, 8 screenshots, Pop In Pro $6.99 and all three tips are live, and it shows up in search
  (12th for "Pop In Meeting Alarms").
- tangomike.app tag reads "On the App Store" (grahamdeno/tangomike PR #6).

## Release scope
- **1.1:** not yet planned (Stage 3). Candidates are listed below.

## Dated checks
- **Monday 2026-11-30:** Snowball and Ornament unlock in the App Store copy, the first themes on the release
  calendar (GumPalette.releaseDays). Owner checks Settings > Theme on his phone. A scheduled reminder is set.
  If they don't appear, look at releaseDays and seasonsReady.

## 1.1 candidates (unordered until the owner ranks them)

### 1. Epic: Ring only when it matters (approved 2026-11-16)
**Goal:** Pop In rings only for a meeting that needs the user now. Meetings already handled, skipped or clashing
don't pile up as ringing alarms.

**Context:** found in real use on 1.0. With two meetings at the same start time and a later meeting, all left
unpopped while the user joined from another device, three alarms were ringing at once when he picked up his phone.
The in-app screen already follows "newest meeting wins" (Sprint 29). The likely cause is at the system level: each
meeting has its own AlarmKit alarm, and iOS rings each one separately. Not yet confirmed on a device.

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
- Open: should partial overlaps (1:00 to 2:00 and 1:30 to 2:00) count as a clash, or only same-minute starts?

#### 1.2 Alarms stop on their own after 7 minutes
As someone who sometimes joins from another device, I want an unanswered alarm to stop on its own, so my phone
isn't ringing for a meeting I already handled.
- Given an alarm has rung for 7 minutes without a pop, snooze or Not going, then it stops ringing.
- Then the meeting stays on the Lock Screen and in the Live Activity as "Started · Join" until the meeting ends.
- The meeting counts as missed under newest-meeting-wins, the same as today.
- Open: is 7 minutes fixed, or a setting with 7 as the default?

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
