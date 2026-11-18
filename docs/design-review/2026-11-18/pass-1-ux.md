# Pop In design evaluation (read only), for 1.2 and later

Grok, 2026-11-18. Code: grahamdeno/popin main at 697ba47. Pictures: ci-audit "Audit for 08de82d" (4ac3934, Nov 14 12:10 PM ET), 4 configs × 13 journeys = 52 journeys, 552 PNGs, every one viewed. Rubric: playbook standards/ux-audit.md §7, severity §8.

## Before the findings: three things that don't match

1. **J12 (all themes) doesn't show the themes.** All 80 pictures in every config show the **Fortune** ball and fortune text, whatever the file name (snowball, pumpkin, zen…). Cause, test-side: `Journeys.swift:288` launches `a.launch("fortune", theme: theme)`, and `AppModel.swift:353-358` lets the `fortune` scene override `-theme`. I didn't work around this (no rendering themes another way), so **the 40 held themes are not judged here**. Evidence: `/workspace/popin-eval-evidence/J12_every-theme-shows-Fortune.jpg`.
2. **08de82d isn't on main.** It's the head of `fix/audit-batch` (squash-merged as #32). Ten app PRs since then (#33 to #42: tips, "$6.99 once", the App icon row, the Pop for fun game, new Pro copy) aren't in the pictures. I only raise picture findings where main's code hasn't changed that screen. For example, the "$4.99" and no "once" in the Pro row are fixed on main.
3. **The iPad pictures are saved sideways.** The landscape screens are stored as 2064×2752 portrait PNGs. I rotated copies to view them. The live App Store iPad screenshots have the same problem (GR-3).

Also: J3 (Not going) has only the after-Undo picture, never the Not going state itself. big-text J13 stops after picture 05 (no More menu, Add reminder or Pop for fun pictures), and SUMMARY still reports "Failed checks: None". The benchmarks start inside Settings, not on Home (see GR-5).

## 1. Summary

**Keep exactly as they are**
1. **The bubble as the one main control, with a visible underlined "Not going."** Join, Skip and Pop-late are 1 tap each, which matches every benchmark (SUMMARY.md). It stays calm: one card, one ball, white around it (pro-light/J2-home-soon/01-home.png).
2. **The honest alarm expectations.** The card's "Rings 2 min before" or "Outside work hours, quiet notification" line (HomeView.swift:262-266), and the first-run sketch of the locked versus unlocked alarm (pro-light/J1-first-run/03-alarms-why.png). Nobody gets surprised by a banner.
3. **Settings' shape.** Short groups where every row shows its answer. Calendars are grouped by account, folded and searchable (pro-light/J7-many-calendars/01-calendars.png, 02-search-soccer.png). Every Pro choice opens the Pro sheet; none is a dead end.

**The 5 changes that would help most**
1. **GR-1:** At the largest text sizes, Home pushes its header off screen. That header holds the only route to Settings, Add reminder and Pause, and the bubble ends up hidden behind the card.
2. **GR-2:** "Not going" can only be undone for 5 seconds. After that, there's no way to bring the meeting back.
3. **GR-3:** The live App Store iPad screenshots are sideways.
4. **GR-4 / GR-7:** On the alarm screen at large text, the two pills cover the meeting time. "In 2 min" also reads like a time, not "Snooze."
5. **GR-5:** Settings sits two taps deep behind ⋯. From Home, "Ring 2 minutes before" takes 4 taps against a target of 3. A gear button fixes that and the theme path too.

## 2. Findings (ranked by help to a person)

| ID | Area | Sev | Rule/Opinion | Where | What a person sees now | Suggested change | Effort | Version | Conflicts with a product rule |
|---|---|---|---|---|---|---|---|---|---|
| GR-1 | Workflow | 4 | Rule (rubric 9, 1; §8 "locks a group out") | big-text/J2-home-soon/01-home.png; big-text/J10-fortune/01-fortune-home.png; big-text/J11-moon-grenade/01-moon-home.png; big-text/J13 stops at 05; HomeView.swift:52-63 (no ScrollView) | At Accessibility XXXL the card fills the screen and runs under the status bar. The wordmark and ⋯ menu (the only way to Settings, Add reminder, Pause) are gone. The bubble is a pink sliver behind the card, the "Then" line is off screen, and nothing scrolls. | At accessibility sizes, put the text column in a ScrollView with the header pinned (safeAreaInset top). Shrink the bubble behind it, or add a small "Join" word button in the card that does the same pop. Add a big-text Home check that ⋯ is hittable. | M | possible 1.1 fix | A "Join" word button touches "The bubble is the main button." The bubble stays the main control; the word is a fallback only at accessibility sizes. Graham decides. |
| GR-2 | Workflow | 3 | Rule (rubric 2, 7; tester task 4 in ux-audit.md:74) | pro-light/J3-not-going/01-after-undo.png; HomeView.swift:375-401 (5 s); AppModel.swift:794-806 | Tap Not going and a toast offers Undo for 5 s. After that, there's no way to bring the meeting back. Tester task 4 ("then change your mind") fails if they're slower than 5 s. | Keep a skipped meeting as a quiet line ("Not going: 3:00 Design review · Undo") in the Then/Later area until it starts, or let a tap on a Later row restore it. App state only, no calendar write. | M | possible 1.1 fix | No |
| GR-3 | Website (store listing) | 3 | Rule (HIG/App Store screenshots must show the app as used) | Live store iPad-1-home … iPad-8-fortune, 2064×2752 with sideways content (box: /workspace/popin-eval-web/store-iPad.jpg); same in ci-audit ipad/*.png | Someone shopping on an iPad sees all 8 screenshots turned 90°. | Rotate the iPad frames in the screenshot pipeline (screenshots.yml / publish-screenshots.yml) before upload, and replace them with the next version's submission. That's a ship step and needs Graham's go. | S | possible 1.1 fix | No |
| GR-4 | Visual | 2 | Rule (rubric 9) | big-text/J5-takeover/01-ringing.png, 02-late-50s.png, 03-late-75s.png; big-text/J13-edge-cases/01-missed-under-new-alarm.png; NowView.swift:68-82 | On the alarm screen, the Not going and "In 2 min" pills sit on top of "4:43 PM to 5:13 PM · Zoom." | Put the pills in the stack under the card instead of an overlay with a fixed `offset(y: 60)`. | S | 1.2 (or with 1.1 story 1.3, which already edits NowView) | No |
| GR-5 | Feature placement | 2 | Rule (benchmarks) | HomeView.swift:211-236; Journeys.swift:136,148-152,194 (walk starts in Settings); SUMMARY.md benchmarks | Settings is ⋯ → Settings. From Home: Ring 2 min before = 4 taps (target 3); find and turn off one calendar = 5 taps plus typing (target 3). The audit counts from inside Settings, so it shows "ok." | A gear button beside ⋯ on Home (⋯ keeps Add reminder, Pop for fun, Pause). Measure the benchmarks from Home. | S | 1.2 | No |
| GR-6 | Workflow | 2 | Rule (rubric 2) | pro-light/J2-home-soon/02-popping.png; pro-light/J9-unicorn/02-unicorn-pop-early.png; HomeView.swift:380 | After a pop or a Not going, the toast says "Cleared Design review." It doesn't say whether you joined or skipped. | "Popped Design review · Undo" (or "Joined" when a link opened) and "Not going to Design review · Undo." | S | 1.2 | No |
| GR-7 | Components | 2 | Rule (§6 Names: visible word matches the label; rubric 6) | pro-light/J5-takeover/01-ringing.png; NowView.swift:75-79 | Under "Starts in 2 min" there's a pill reading "In 2 min" with zzz. It reads like the start time. VoiceOver says "Snooze two minutes," so Voice Control users have to guess the word. | Label it "Snooze 2 min," the word Apple's Clock uses. | S | 1.2 | No |
| GR-8 | Components | 2 | Rule (rubric 9, 10; Apple audit hitRegion, textClipped) | pro-light/J13-edge-cases/01-missed-under-new-alarm.png; small-phone/J13…/01; NowView.swift:44-56 | "Missed: 4:38 PM Weekly sync · Join" is a one-line footnote, cut off, with a small tap area. Join is part of the text. | Build it as 1.1 story 1.3's "Also missed" line: its own row that wraps, at least 44 pt, with a separate Join button. | S | 1.2 (or inside 1.1 story 1.3, already in scope) | No |
| GR-9 | Visual | 2 | Rule (rubric 9) | big-text/J7-many-calendars/01-calendars.png, 02-search-soccer.png; big-text/J1-first-run/02-calendars-why.png, 04-which-calendars.png; CalendarsPage.swift:66-104 | At XXXL, account names break mid-word ("Ex-chan-ge," "Gmai-l"). In first run, the pinned button sits mid-text with words showing below it. | At accessibility sizes, stack "Turn all off" under the account name (the UX-2 fix for SettingsLink). Give the pinned button a solid backing that runs to the bottom edge. | S | 1.2 | No |
| GR-10 | Workflow | 2 | Rule (rubric 3: hidden gesture; copy) + Opinion (chips) | pro-light/J13-edge-cases/07-add-reminder-sheet.png; AddReminderSheet.swift:8,14-17,26-33,40-43 | Changing the time takes date and time chips plus wheels. Add works with an empty title. The only way to delete is a swipe. The footer says "this iPhone" on iPad. | Add chips: In 15 min · 30 min · 1 hour · Pick a time. Disable Add until there's a title. Add an Edit button. Say "this device." | S | 1.2 | No |
| GR-11 | Components | 2 | Rule (HIG widgets: rendering modes, text styles) | NextMeetingWidget.swift:10,56-57,71-156; MeetingCountdownActivity.swift:34-89; no `widgetRenderingMode`/`widgetAccentable` in the target | Widgets hard-code a white background, their own colors and about 40 fixed font sizes. On iOS 26's tinted and clear Home Screen they'll render flat and unmarked. Not walked by the audit. | Honor `widgetRenderingMode` (mark the bubble and countdown `.widgetAccentable()`, drop the white fill when accented). Use text styles where they fit. Share the Brand colors. | M | 1.2 | No |
| GR-12 | Components | 2 | Rule (rubric 13; Apple audit "description") | SUMMARY.md: pro-sheet "bell.and.waves.left.and.right", "ipad.landscape", "square.grid.3x3"; ProView.swift:51 | VoiceOver reads the Pro sheet's icons aloud by their SF Symbol names. | `.accessibilityHidden(true)` on each icon, or combine each row. | S | 1.2 | No |
| GR-13 | Visual | 2 | Rule (rubric 18, 1) | pro-light/J6-settings/06-theme-gallery.png (✦); 02-ring-before.png and 03-sound.png ("Pro" pill); CalendarsPage.swift:134-135 ("(Pro)"); SettingsView.swift:106 ("Keep screen on ✦") | Paid items are marked three ways: ✦, a pink "Pro" pill, and "(Pro)." ✦ alone doesn't say "paid." | Use the small "Pro" pill everywhere, a word rather than a symbol. | S | 1.2 | No |
| GR-14 | Components | 2 | Rule (rubric 10) | pro-light/J7-many-calendars/01-calendars.png; pro-light/J13-edge-cases/02-paused-home.png; CalendarsPage.swift:144 (32 pt); HomeView.swift:244 (36 pt); WorkHoursPage.swift:39 (40 pt) | The "Smart ⇕" menu, the "Paused until … · Resume" pill and the work-day circles are under 44 pt. | Make each one at least 44 pt tall. Keep the look and grow only the tap area. | S | 1.2 | No |
| GR-15 | Visual | 1 | Opinion | ipad/J2-home-soon/01-home.png, ipad/J4-home-far/01-home-far.png (rotate to view); HomeView.swift:32-50 (card max 480, countSize 60) | On a 13" iPad left open as a desk clock, the card and countdown are phone-sized in the top-left. There's a wide empty middle, and the bubble sits bottom-right. | On regular width, scale the title and countdown up (for example a 110 pt count) and center the card vertically beside the bubble. | S | 1.2 | No |
| GR-16 | Workflow | 1 | Opinion | pro-light/J13-edge-cases/04-own-reminder-next.png; HomeView.swift:328 | Your own reminder ("Pick up Nora") offers "Not going." | Say "Skip" for reminders. Meetings keep "Not going." | S | 1.2 | Touches "Keep a visible Not going." Meetings keep it unchanged. |
| GR-17 | Visual | 1 | Rule (HIG readable width; same logic as UX-10) | ipad/J1-first-run/01-hello.png … 05-covered.png; WelcomeView.swift:24-63 | iPad first run stretches small text and a black button across the full 13" width. | Cap the column at about 600 to 680 pt, centered. | S | 1.2 | No |
| GR-18 | Styling code | 1 | Rule (§6 text size: list every fixed size) | HomeView.swift:408 (`Brand.display(30)`); BubbleView.swift:688-695 (fortune words) | The "Pop In can't see your calendar" title doesn't grow with text size. The fortune words don't either (Apple audit: "unsupported"). | Use @ScaledMetric or a text style for the permission title. Let the fortune words scale with a cap. Keep the wordmark fixed (deliberate, findings.md). | S | 1.2 | No |
| GR-19 | Website | 1 | Rule (rubric 6: copy says what it means) | site/index.html:33,46 (alt "a Join button"); site/support.html ("Smart or Alarm", "the Join button"); CalendarsPage.swift:133-135; WelcomeView.swift:143 ("Open") | The site and support use words the app doesn't: "Join button" on the alarm screen (there isn't one), "Alarm" (the app says "Always rings"), and "Join" on the Lock Screen (the onboarding says "Open"). | Match the app's words: Smart / Always rings / Quiet; "Open" on the Lock Screen; alt text "the bubble, Not going and Snooze." | S | 1.2 (site deploy = Ship go) | No |
| GR-20 | Feature placement | 1 | Opinion | pro-light/J6-settings/06-theme-gallery.png; ThemeGalleryPage.swift:65-89 | Changing the theme takes ⋯ → Settings → Theme → tile → See it on Home: 5 taps. | With GR-5's gear it's 4. Optionally add "Theme" to the ⋯ menu as a direct sheet (the What's-new card already opens it). | S | 1.2 | No |
| GR-21 | Workflow | 1 | Opinion | pro-light/J1-first-run/01-hello.png, 02-calendars-why.png | First run is 7 taps (2 of them iOS prompts). Hello is a screen with no decision. | Merge Hello into the calendar screen ("Never miss the start of a meeting" plus the why, button "Allow calendar access"). | S | Later | No |
| GR-22 | Website | 1 | Opinion | /workspace/popin-eval-web/site-1280-sheet.jpg; site/site.css:3-4,30 | About 80% of the site is a dark aubergine sheet (#1E1620) in Geist. The app is calm white in SF. | Keep the hero and "How it works" white with the pink, and use the dark sheet only for the Pro and price band. | M | Later | No (it supports "calm white") |
| GR-23 | Website | 1 | Rule (§6 Layout: no sideways scroll) + cleanup | site/site.css:72-75; site/style.css (unused) | On phones, "How it works" scrolls sideways. Support and Privacy are hidden from the top nav under 820 px. There are no `:focus-visible` styles. style.css is unused and duplicates the tokens. | Stack the three moves vertically on phones, keep the two nav links, add focus rings, delete style.css. | S | Later | No |
| GR-24 | Styling code | 1 | Opinion | Brand.swift:3-25; NextMeetingWidget.swift:56-57; SettingsView.swift:257; QuietMode.swift:45-72 | Tokens live only in the app target. Widgets redefine ink and secondary (#6B6B6B against the app's #4A4A4A). Seven corner radii, about a dozen minHeights, an inline ground color, and an unused `QuietBrightness`. | One `Shared/Tokens.swift` (see §5) used by the app and the widgets. Remove the dead code. | M | Later | No |
| GR-25 | Website (store listing) | 1 | Opinion | Live store page, "Accessibility: The developer has not yet indicated…" | The store's Accessibility section is empty. | After GR-1, declare Larger Text, VoiceOver, Reduce Motion and Sufficient Contrast in App Store Connect. That's an App Store Connect change, so it's a recommendation only. | S | Later | No |

## 3. Feature placement map

| Feature | Where now | Where I'd put it | Why |
|---|---|---|---|
| Next meeting card, countdown, "Rings…" line | Home card | Keep | Clear, honest, one job |
| Bubble (pop = join/clear) | Home, Now | Keep. Add a word fallback at accessibility sizes only | GR-1 |
| Not going | Home card link, Now pill | Keep. Add restore until start | GR-2 |
| Then / Later list | iPhone: "Then" pill. iPad: Later list | Keep. Show skipped meetings there with Undo | GR-2 |
| Settings | ⋯ menu → Settings | Gear button on Home | GR-5 |
| Add a reminder, your reminders list | ⋯ menu; the list is inside the Add sheet | Keep Add in ⋯. Also a "Your reminders" row in Settings › Meetings | You can find and delete them without opening "New reminder" |
| Pause alerts | ⋯ menu and Settings › Meetings | Keep both | Quick when needed, findable later |
| Pop for fun | ⋯ menu | Keep | Fun, out of the way |
| Test the alarm | Settings › Alarm (top row, pink) | Keep. Also offer it once on "You're covered" | Sets the expectation on day one |
| Sound, Lock Screen countdown, Heads-up buzzes | Settings › Alarm | Keep | |
| Buzz as it gets close | Settings › Bubble | Settings › Alarm | It's an alert, not a look |
| Keep screen on (Desk mode) | Settings › Bubble | Settings › Alarm on iPhone; first in its group on iPad | It's a display or desk feature, not bubble styling |
| Theme gallery, App icon row | Settings › Bubble › Theme | Keep. Optionally also ⋯ → Theme | GR-20 |
| Pop In Pro | Top of Settings, plus locked items | Keep | |
| Restore purchase | Pro sheet only | Keep, and add a "Restore purchase" row in Settings › Help | Easier to find for reinstalls |
| Tips | Bottom of Settings, Pro only (main) | Keep | |
| Per-calendar Smart/Always/Quiet | Settings › Calendars menu (also in first run) | Keep in Settings. In first run, show "Smart" as plain text with no Pro options | No upsell during first run |
| Diagnostics, Bubble/Steady switch | Version tapped 5 times | Keep hidden | The owner's rollback switch only |
| What's new themes | Home card, monthly | Keep | |
| Missed meetings | One footnote on the alarm screen | 1.1 story 1.3's "Also missed" row | GR-8 |
| Widgets | Home Screen and Lock Screen only. Not mentioned in the app | Add a line in Help ("Add the Pop In widget") | Discoverability, no new UI |

## 4. Workflow table (taps; iOS prompts counted)

| Workflow | Steps now | Steps proposed | Benchmark target |
|---|---|---|---|
| First run and calendar permission | 7: Get started, Allow calendar access, iOS Allow, Allow alarms, iOS Allow, Done (calendars), Done (covered) | 6 (merge Hello into the calendar screen, GR-21) | none |
| Join the next meeting (in app) | 1 (pop) | 1 | 1 ✓ |
| Join from the locked alarm | 1 (Open) plus unlock | 1 | none |
| Not going | 1; Undo 1 within 5 s, then impossible | 1; Undo 1 any time before the start | Skip 1 ✓ |
| Full-screen alarm (in app) | Pop 1 / Not going 1 / Snooze 1 | Same, with clearer labels (GR-4, GR-7) | Pop the late bubble 1 ✓ |
| Add a reminder | ⋯, Add a reminder, type, Add = 3 plus typing at the default +30 min. Custom time = 5 to 6 | ⋯, Add, type, chip, Add = 4 for any common time | none |
| Open Settings | 2 (⋯, Settings) | 1 (gear) | none |
| Settings › Ring before | From Home 4 (+ Done) | 3 | 3 (audit says 2 because it starts in Settings) |
| Settings › Calendars (find and turn off one) | From Home 5 plus typing | 4 plus typing | 3 |
| Turn off a whole account | From Home 4 | 3 | 1 (audit measured inside Calendars) |
| Settings › Early alarm / Work hours / Pause / Sound / Pop sound | From Home 4 each (⋯, Settings, row, choice) | 3 each | none |
| Settings toggles (Apple Reminders, Accepted only, Lock Screen countdown, Heads-up buzzes, Buzz as it gets close, Keep screen on) | From Home 3 each | 2 each | none |
| Theme gallery | 5 (⋯, Settings, Theme, tile, See it on Home) | 4 (gear), or 3 via ⋯ → Theme | none |
| Pro purchase | 5 (⋯, Settings, Pro row, Unlock, Apple confirm); from a locked tile 4 | 4 / 4 | none |
| Restore purchase | 4 (⋯, Settings, Pro row, Restore) | 3 (gear, Help › Restore) | none |
| iPad layout | Same counts as iPhone. Settings is a form sheet | Same counts, bigger desk-view type (GR-15) | same as iPhone |
| Widgets | Add: iOS flow, about 6. Tap the bubble: 1 (opens Pop In, pops, opens the link) | Same, plus a Help line about the widget | none |

## 5. Component and styling notes

**Native swaps**
- Settings: the custom `SettingsPage`/`SettingsGroup` card list (SettingsView.swift:250-300) imitates an inset-grouped `Form`. It's fine and deliberate (Scales and Shoebox style). A native `Form` with `.formStyle(.grouped)` would give free Dynamic Type layout, header traits and iPad sizing, but it would change the look. Opinion: keep it, and copy `LabeledContent`'s accessibility-size stacking into `SettingsLink` (UX-2 did this by hand).
- `ChoicePage` with check rows: use `Picker(...).pickerStyle(.inline)` inside a Form section to get selection traits for free. It already adds `.isSelected` by hand.
- Snooze and Not going pills: fine as glass buttons; only the word and layout need work (GR-4, GR-7).
- Home ⋯ `Menu`: native and good. Add a separate gear `Button` (GR-5).
- Calendars' search: `TextField` in a rounded rect. `.searchable` is the native choice, but it lives in the nav bar. Keep the inline field and use a `TextField` with a `.search` submit label.
- Add reminder: a native `Form` and `DatePicker`. Add `EditButton()` and quick chips (GR-10).
- Undo toast: custom glass capsule. Fine. No native equivalent on iOS.
- Widgets: add `widgetRenderingMode` support and `Button(intent:)` only if a no-launch action ever makes sense (today a tap opens the app to pop, which is right).

**How the tokens should be organized** (one file in `App/Shared/` for the app and the widgets):
- `Ink.primary #141414`, `Ink.secondary #4A4A4A`, `Line.hairline #EFEFEF`, `Ground.settings white 0.965`, plus `GumPalette.accent/accentText/accentLight/accentDark`. The palette-driven accent is already a good pattern.
- Radius: `card 24`, `group 20`, `pill .capsule`, `tile 14` (today 14/18/20/22/24/28/3 are all used).
- Space: 4/8/12/16/20/24/28 (today 2/4/6/7/8/10/12/14/16/18/20/22/24/28/32/40/48/56/60 appear).
- Target: `min 44`, `row 52`, `primary 56` (today 32/36/40/44/48/52/56/60/64/68).
- Type roles: `title` (@ScaledMetric 32, largeTitle), `countdown` (60), `unit` (22), and everything else on text styles. Most of the app already uses text styles (UX-11 held).

**Fixed sizes found** (`.system(size:)`)
- App: Brand.swift:16, used by `Wordmark` (22, deliberate) and the HomeView.swift:408 permission title (30, GR-18); BubbleView.swift:695 fortune words (15 to 30 by width).
- ScaledMetric-backed (fine): HomeView.swift:280,288,296,363; ProView.swift:38; CalendarsView.swift:14; WelcomeView.swift:30,35; NowView.swift:58.
- Emoji and decoration, fine: BubbleView.swift:303; PopPlayground.swift:533; ThemeDecor.swift:187,489,731,1036-1121,1203.
- Widgets, about 40 fixed sizes from 9 to 40 pt: NextMeetingWidget.swift:71-156,213,226,273-289; MeetingCountdownActivity.swift:34-89 (GR-11).

**Dark mode and themes**
- The app is forced light (`PromptlyApp.swift:42 .preferredColorScheme(.light)`), as the roadmap says. That's coherent with "calm white." The playbook asks the audit doc to say why (ux-audit.md "Configs" only says "light only").
- Widgets and the Live Activity are the places dark, tinted and clear modes matter (GR-11). The white widget will be the brightest tile on a dark Home Screen.
- Themes: on the pictures that are valid (Bubblegum, Unicorn, Fortune, Moon, Grenade), the glass card keeps words readable. Fortune's violet accent and Moon's "Next transmission" (clipped at big text) read fine at default size. The 40 held themes couldn't be judged (J12 problem above).
- Reduce Transparency: the app uses system `.glassEffect`, which falls back on its own. Reduce Motion: every TimelineView and the pop check `accessibilityReduceMotion` (BubbleView.swift:38-168, DiscoLights.swift:7-15).

## 6. What I couldn't judge (please check on your phone)

- Alarm sounds: Gum pops and Popcorn, the quiet-to-loud ramp, whether the sound loops, and loudness through Silent and Focus.
- Haptics: the 10-minute buzz ramp (HapticRamp.swift), the heads-up buzzes at 5 and 2 minutes, and the pop haptic.
- The locked-phone AlarmKit full screen: Open joins and stops the alarm, Stop silences it, and the 1-minute backup alarm. Also the banner when unlocked: does a tap bring the bubble?
- Live Activity and Dynamic Island countdown; widgets in light, dark, tinted and clear Home Screen modes; the theme app icon switching.
- Animation feel: the inflate, tremble, tear and pop timing (UX-5), late buds, Unicorn confetti, Fortune mist, quiet mode going still after 2 minutes.
- Reduce Motion, Bold Text, Increase Contrast, VoiceOver order and actions (Join and Not going as actions on the card).
- All 40 held themes and their pops (J12 pictures are all Fortune).
- iPad portrait and Split View (the audit's iPad pictures are landscape only).
- Real purchase and Restore in the sandbox, and the Pop for fun target game on main (the pictures predate #35).

## 7. No changes

- `git status` in /workspace/popin-eval (697ba47) and /workspace/popin-eval-audit (ci-audit 4ac3934): "nothing to commit, working tree clean" at the check. This REPORT.md is now an untracked local file in that clone, never committed.
- No commits, branches, tags, pushes, PRs, issues, comments or reviews in any repo.
- No workflow run or workflow_dispatch. `gh run list` (read only) shows the newest run on grahamdeno/popin is "build", Nov 16 10:06 PM ET, before this work.
- Nothing opened or changed in App Store Connect, and no purchases. The store page was read with curl only.
- The playbook was read with `gh api` (read only).
