# Pop In roadmap: 1.1 and beyond

The running plan from 1.0 forward. Build from this file. docs/plan.md stays as the history of how 1.0 was decided;
read it for context, but this file says what comes next.

## Rules for this file
- Add items only when the owner raises or approves them. Write down the owner's words and the date.
- Each item lists: the problem, what we decided, open questions, and which model each step needs
  (Opus for feel, data safety and judgment; Sonnet for building and shipping).
- When an item ships, move it to "Shipped" with the version and build. Don't delete it.
- Nothing ships until the owner says ship. He prefers one big release over several small ones.
- The 1.0 rules in CLAUDE.md still apply: calendar and Reminders stay read only, no network, keep the
  Bubble / Steady switch, keep a visible "Not going", and never press Submit for Review.

## Where things stand (2026-11-16)
- 1.0 (build 1056) approved and live in the US App Store, EU excluded. Grok checked on 2026-11-16: the page,
  subtitle, icon, 8 screenshots, Pop In Pro $6.99 and all three tips are live, and it shows up in search
  (12th for "Pop In Meeting Alarms").
- tangomike.app tag reads "On the App Store" (grahamdeno/tangomike PR #6).

## Dated checks
- **Monday 2026-11-30:** Snowball and Ornament unlock in the App Store copy, the first themes on the release
  calendar (GumPalette.releaseDays). Owner checks Settings > Theme on his phone. A scheduled reminder is set.
  If they don't appear, look at releaseDays and seasonsReady.

## 1.1 candidates (unordered until the owner ranks them)

### 1. Stacked alarms: one alarm at a time (owner, 2026-11-16)
- **What happened:** two meetings started at the same time, and the owner joined from his work computer and
  skipped the phone. Then the next meeting came due. When he got to his phone, three alarms were ringing.
  Owner: "Is it the best experience for those to all stay open and I have to pop them all? Or does that feel
  like an unwanted pile up?"
- **Likely cause (not yet confirmed on a device):** the in-app screen already follows "newest meeting wins"
  (Sprint 29) and shows "Missed: ...". But each meeting has its own AlarmKit alarm, so iOS rings each one on
  its own schedule and they stack at the system level.
- **Proposed (owner agreed to plan it, 2026-11-16):**
  - Only one alarm rings at a time. When a new meeting's alarm fires, stop any older Pop In alarm still ringing.
  - Older meetings become a quiet line, not another alarm: "Also missed: 1:00 Standup, 1:00 Design review · Join".
  - One pop or stop clears the stack.
  - Meetings that start at the same minute get one alarm showing both, with a Join for each.
- **Not now:** a "joined elsewhere" button to silence the rest of a meeting. Revisit if one-at-a-time isn't enough.
- **Steps:** (a) reproduce on a device: two same-time meetings plus a later one, all left unpopped. Confirm
  whether the extra alarms are AlarmKit system alarms, backup alarms, or both. (Sonnet.) (b) Settle the wording
  and the look of the missed line and the two-meeting alarm. (Opus.) (c) Build it in Model/ with SimulatedDayTests
  cases: same-minute pair, pair plus later meeting, popped vs unpopped. (Sonnet.)

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
- tangomike.app: add an App Store link to Pop In's entry now that the store page is live. Owner hasn't decided yet.

## Shipped
- 1.0 build 1056, approved 2026-11-16.
