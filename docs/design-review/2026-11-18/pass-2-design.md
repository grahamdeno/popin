# Pop In: design-quality pass 2 (read only)

Sources: ci-audit pictures at 4ac3934 (mostly pro-light), code on main at 697ba47 (App/Promptly/Design, Features, App/PromptlyWidgets, App/Shared), the live store listing and popin.tangomike.app. Pass 1 findings are referenced as GR-n and not repeated here.

## Summary

**Grade: B+.** The concept and the bubble art are premium already. What holds it back is component craft: the type hierarchy is flat on the screens that matter most, and the surfaces around the bubble feel assembled rather than designed as one system.

**Strengths**
1. **The bubble.** BubbleView.swift:452-540 layers a 3-stop radial gradient, a blurred edge falloff, a crisp gloss streak, a window reflection, a glint and a rim light. It reads as a real, wet, tactile object, and it is unlike anything else in the category.
2. **Restraint.** There is one ink colour, one secondary grey, one accent per palette (GumColors), plain words and lots of air. The white reads as intentional wherever the bubble is on screen (Home, alarm).
3. **A small, consistent kit.** There is one GlassCard (r24), one capsule button pair and one wordmark. `monospacedDigit` and `contentTransition(.numericText())` are already on the Home countdown.

**The 5 highest-impact refinements**
1. **D-1. The countdown shrinks as the meeting gets close.** At 1 h it renders at about 60 pt (J2/02-popping). At 8 min it renders at about 30 pt (J2/01-home: the "8" glyph is 64 px tall at 3x). The cause is probably `.minimumScaleFactor(0.5)` (HomeView.swift:293) giving way once the "Pop the bubble to join" row is added. The number people most need gets smaller just when they need it.
2. **D-4. The alarm screen has no countdown, and its pills hang off the card** (NowView.swift:68-82). Put a hero numeral at the top of the card and move the two pills inside it.
3. **D-9. The Pro sheet has no price moment.** Today it is a flat ball, a left-aligned title, an 8-row list, and a price that appears only inside the black button. Replace that with a theme-trio hero, a two-column feature grid and a sticky price bar.
4. **D-12. Make the widgets look like the app.** The countdown is a ticking m:ss where the app says "8 min". The ball uses the simpler swatch light. There is no tinted or clear rendering art.
5. **D-14/D-15. Motion and feedback polish with native APIs.** None of `sensoryFeedback`, `symbolEffect`, `GlassEffectContainer`/`glassEffectID`, `matchedGeometryEffect` or `ContentUnavailableView` is used anywhere in the target (I grepped all *.swift).

## Findings

| ID | Area | Where | Now | Refinement | Native API / technique | Effort | Version | Product-rule conflict |
|---|---|---|---|---|---|---|---|---|
| D-1 | Home type | HomeView.swift:286-299; J2/01-home vs 02-popping | Count drops from about 60 to about 30 pt when the hint row appears | Fix the numeral at 76–88 pt (ScaledMetric). Let the title wrap or scale instead. Remove minimumScaleFactor from the count, or set `.layoutPriority(1)` | `layoutPriority`, `ViewThatFits` for the XXXL case (see GR-1) | S | 1.2 | None |
| D-2 | Home composition | HomeView.swift:262-335 | The card stacks 7 loose lines: label, "Rings", title, count, span, hint, underlined "Not going" | Put label and "Rings 2 min before" on one meta row (leading/trailing). Order: title, then hero count, then span. Add a hairline footer with the hint on the leading side and a "Not going" capsule on the trailing side (M1) | `Grid`/HStack + `Divider().overlay(Brand.hairline)` | S | 1.2 | None. "Not going" stays visible, and gains a target (GR-14) |
| D-3 | Home "Then" | HomeView.swift:338-353 | A floating glass pill sitting on the bubble competes with the card | A plain text line under the card: "Then **5:30 PM** · Lunch with Sam" in subheadline, secondary, time in ink semibold | none | S | 1.2 | None |
| D-4 | Alarm screen | NowView.swift:55-82, :120; J5/01-ringing | "Starts in 2 min" is a status line, the title is the hero, and the pills are offset y:60 half outside the card | "Starts in" eyebrow (accentText), then a 96 pt monospaced numeral, then the title (30 semibold), then span · service. Put two equal-width pills inside the card, and "Pop to join" on the bubble (M2) | `contentTransition(.numericText(countsDown: true))`, `TimelineView(.periodic(by: 1))`, `GlassEffectContainer` for the pills | M | 1.2 | None. Bubble is still the main button and "Not going" stays visible. Pairs with GR-4 and GR-7 |
| D-5 | Card material | Brand.swift GlassCard; J2/01-home | Over the bubble the glass picks up a pink wash, and on white it reads as a grey slab with a soft shadow | On white, use a near-opaque surface: white at 0.82, hairline 0.5 pt white at 0.9 inner stroke, shadow y10 r30 at 0.07. Keep real `.glassEffect` only for controls that float over the bubble | `.glassEffect(.regular.tint(.white.opacity(0.6)))`, `.glassEffect(.clear)` for the pills | S | 1.2 | None |
| D-6 | Header | HomeView.swift:214-247 | Wordmark plus a bare `ellipsis.circle` (title2) | Two 40 pt glass circles (⋯ and gear, per GR-5) in one `GlassEffectContainer`. Wordmark unchanged | `GlassEffectContainer`, `.buttonStyle(.glass)`, `.symbolEffect(.bounce, value:)` | S | 1.2 | None |
| D-7 | Settings rows | SettingsView.swift:257-333 | Rows show labels only, so you must open each one to learn its value. The Pro row is a lone 36 pt ball with "$X once" | Put a trailing value in secondary on every ChoicePage row ("2 min", "Pop", "Bubblegum"). Pro row: three overlapping theme balls, two lines of text and a black "$6.99" capsule (M3). Use a 30 pt squircle icon only on the first row of each group, or none at all | `LabeledContent`, `.monospacedDigit()` for values | M | Later | None |
| D-8 | Settings ground | SettingsView.swift:257 | Custom page at white 0.965 with r20 cards that imitate inset-grouped | Either commit to native `Form` + `.formStyle(.grouped)` + `.scrollContentBackground(.hidden)` on #F5F5F7, or keep custom but match the system metrics: r22 cards, 52 pt rows, separator inset 56 | `Form`, `.listRowSeparatorTint(Brand.hairline)` | M | Later | None |
| D-9 | Pro sheet | ProView.swift:25-73; J6/07 | GumBall 96 is flat (swatch light). Title left-aligned, 8 body rows in a glass card, price only in the button label | Trio hero (Bubblegum, Water balloon, Fortune) centred. Centred title and one line of copy. 2-column features with 28 pt tinted squircles. A sticky bottom glass bar with "**$6.99** One time · no subscription", "Unlock Pro" 56 pt, and a "Restore purchase" text link (M4) | `.safeAreaInset(edge: .bottom)`, `.presentationBackground(.thinMaterial)`, `.sensoryFeedback(.success, trigger: store.isPro)` | M | 1.2 | None |
| D-10 | Theme gallery | ThemeGalleryPage.swift:129-148; J6/06 | Square tiles with hairline borders around round balls, a "✦" glyph on locked tiles, a 2 pt ink box for the selected one | Drop the tile box. Make the balls 64 pt with a 2 pt ink ring for the selected one and a small "PRO" capsule (one Pro marker everywhere, per GR-13) (M6) | `.scrollTransition { $0.scaleEffect(phase.isIdentity ? 1 : 0.92) }`, `matchedGeometryEffect` from tile to Home bubble | S | 1.2 | None |
| D-11 | Swatch vs bubble light | GumColors.swift:477-503 vs BubbleView.swift:516-540 | GumBall has one soft blob highlight. The big bubble has a streak, window and glint | Share one light model: give GumBall the same trimmed gloss streak plus window, scaled to size. This affects Settings, the Pro sheet, the gallery and the widgets | Shared `GumHighlights(w:h:)` view; `.drawingGroup()` | S | 1.2 | None |
| D-12 | Widgets | NextMeetingWidget.swift:80-156, 213-221 | Count is `Text(timerInterval:)` (ticking m:ss, 28/30/40 pt) where the app says "8 min". The ball is a swatch. Container is always white | Show "8 min" with the unit in secondary, refreshed per minute. Use big-bubble light. In accented mode, draw the ball as an outline (M5). Fixed sizes are covered by GR-11 | Timeline entries every 60 s, or `Text(start, format: .offset(to: .now, allowedFields: [.hour, .minute]))` (iOS 18, verify). `@Environment(\.widgetRenderingMode)`, `.widgetAccentable()`, `.widgetAccentedRenderingMode(.desaturated)` | M | Later | Light only: rendering modes are system-driven, so this is not an app dark mode. Graham to confirm |
| D-13 | Live Activity | MeetingCountdownActivity.swift:22-89 | White 0.92 tint, RingedBall, fixed sizes. The Dynamic Island compact view uses a 15 pt timer | Lock Screen: title 17 semibold, a 34 pt monospaced count, a 6 pt progress capsule in accent. Compact island: a 14 pt ball plus "8m" | `ProgressView(timerInterval:)`, `.contentTransition(.numericText(countsDown: true))`, `.activitySystemActionForegroundColor` | M | Later | None |
| D-14 | Haptics / feedback | HapticRamp.swift; ThemeGalleryPage.swift:129 | UIKit generators in the ramp. Theme pick, toggles, undo and purchase give no feedback | Use `.sensoryFeedback(.selection, trigger: palette)` in the gallery, `.impact(weight: .light)` on Undo and `.success` on unlock. Keep HapticRamp for the alarm | `sensoryFeedback` | S | 1.2 | None |
| D-15 | Motion | HomeView.swift:377-401; NowView | The toast appears with no physical link to the card. The card and pills never morph | Toast: `.transition(.move(edge: .bottom).combined(with: .opacity))` using `.snappy`. Pills ↔ card: `glassEffectID` in a container. Symbols: `.symbolEffect(.wiggle)` on the bell when an alarm is armed, once only | `GlassEffectContainer` + `glassEffectID`, `symbolEffect`, `.animation(.snappy(duration: 0.3))` | M | Later | None. Reduce Motion paths must stay |
| D-16 | Empty state | HomeView.swift:360-373; J8/01-empty | A card titled "Nothing coming up" plus a grey button, with a lone bubble far below | `ContentUnavailableView` styling, centred: a small 72 pt bubble, a 22 semibold title, one line of copy, "Try a pop" as a text button. The bubble stays tappable | `ContentUnavailableView { } description: { } actions: { }` | S | 1.2 | None |
| D-17 | Calendars | CalendarsPage.swift:144; J7/01 | Every row repeats "Smart ⌃⌄" in accent under the name, which makes 15 pink labels | Show the mode as a trailing secondary value only when it isn't the default, or as a `Menu` behind the row. Use a 10 pt calendar dot. Make the toggle tint ink (not coralDark) so pink means "actionable" | `Menu`, `Picker(.menu)`, `.tint(Brand.ink)` | S | Later | None. Still read only |
| D-18 | First run | Welcome (J1/01-hello) | The card floats mid-screen over a lot of empty white, and the bubble is clipped by the button tray | Anchor the card to the top third (title 34) and let the bubble sit fully visible above the tray at 0.2–0.8 growth, so the white is framed by the object. Merging screens is covered by GR-21 | `.safeAreaInset(edge: .bottom)`, `.scrollTransition` | S | Later | None |
| D-19 | Buttons | Brand.swift:58-88 | Pressed state is opacity only (0.8 / 0.7) | Pressed state: `scaleEffect(0.97)` + opacity 0.9 with `.snappy`. Secondary fill ink 0.06 | `ButtonStyle` + `.animation(.snappy, value: configuration.isPressed)`; or `.buttonStyle(.glassProminent)` tinted ink | S | 1.2 | None |
| D-20 | Brand coherence | site, store, icon | The app is white with Inter-like SF; the site is a dark #1E1620 panel in Geist (GR-22). Store iPad shots are sideways (GR-3) | A one-page brand sheet: white ground, ink #141414, the bubble as the only colour mass, SF Pro / Geist as the web stand-in at matching tracking. Use the hero numeral style (D-1) in the store shots | none | S | Later | None |

## Type, colour and motion spec

**Type** (SF Pro, everything scaled with `@ScaledMetric(relativeTo:)` per GR-18)

| Role | Size / weight | Tracking | Use |
|---|---|---|---|
| Hero numeral | 88 pt medium (Home), 96 (alarm); `.monospacedDigit()` | −3.5 / −4 | Countdown only. Unit in 24–26 medium secondary, baseline-aligned, 8 pt gap |
| Display title | 28–30 semibold, 1.12 line height | −0.6 / −0.8 | Meeting title, Pro title (30) |
| Screen title | 34 bold | −0.8 | Settings, Themes |
| Wordmark | 22 semibold | −0.4 | Unchanged, with a 7 pt dot |
| Body | 17 regular | 0 | Rows. Line length max about 34 em on iPad (text column 480 pt) |
| Meta | 14–15 medium | 0 | "Next · Zoom", "Rings…", span (16 regular) |
| Caption / tag | 10–12 semibold | +0.3 | "PRO" capsule |

**Colour**
- Ground: #FFFFFF; grouped ground: #F5F5F7.
- Ink: #141414. Secondary: #4A4A4A for text, #6E6E73 for values and headers. Hairline: #EFEFEF.
- Accent: the palette's accentText (#C8146A for Bubblegum), used only for actionable text and the "Rings" bell. Toggles and selection use ink.
- Tag fill: the palette's accentLight (#FFE6F0) with accentText.
- Card on white: white at 0.82, inner stroke 0.5 pt white at 0.9, shadow #141414 at 0.07 (r30, y10) plus 0.05 (r3, y1). Card radius 28, row card radius 22, pills fully round.
- Bubble glow: palette accent at 0.30, r30, y−12 (as now).

**Motion**
- Default: `.snappy(duration: 0.3)`. Selection bounce: `.spring(response: 0.25, dampingFraction: 0.6)`. The current 0.45 damping feels toy-like on tiles.
- Numerals: `.contentTransition(.numericText(countsDown: true))` with `.animation(.snappy, value: minutes)`.
- Toast: move from bottom plus opacity, 0.3 s. Auto-hide per GR-2.
- Glass: morph controls within one `GlassEffectContainer(spacing: 12)`.
- Haptics: `.selection` on picks, `.impact(.light)` on undo, `.success` on unlock. The alarm keeps HapticRamp.
- Reduce Motion: no scale or morph, only opacity cross-fades of 0.2 s.

## Mockups (box only, every one labelled MOCKUP)

Each file is a side-by-side image: BEFORE is the real audit picture (or rebuilt from code where none exists) and AFTER is the mockup. The mockups are HTML rendered with headless Chrome, with Inter standing in for SF Pro. Sources are in docs/design-review/2026-11-18/html/.

- `docs/design-review/2026-11-18/M1_home-hierarchy.png`: Home with an 88 pt hero countdown, one meta row, and the hint plus "Not going" in a card footer.
- `docs/design-review/2026-11-18/M2_alarm-screen.png`: alarm with a "Starts in 2 min" numeral, both pills inside the card, and "Pop to join" on the bubble.
- `docs/design-review/2026-11-18/M3_settings-rows.png`: Settings with trailing values on each row and a Pro row showing three theme balls and a $6.99 capsule.
- `docs/design-review/2026-11-18/M4_pro-sheet.png`: Pro sheet with a theme-trio hero, a two-column feature grid, and a sticky "$6.99 One time" bar.
- `docs/design-review/2026-11-18/M5_widgets.png`: widgets showing "8 min" like the app, big-bubble lighting, and a tinted-mode outline ball. The before side is rebuilt from code because no widget picture exists.
- `docs/design-review/2026-11-18/M6_theme-gallery.png`: theme gallery with borderless 64 pt balls, an ink ring for the selected theme, and one "PRO" tag style.

Product rules checked: the bubble is still the main button, "Not going" is visible on Home and on the alarm, and Bubble/Steady is unaffected (the Steady look should take the same hero numeral). Nothing here uses the network, analytics or calendar writes, the UI stays light only, and the wording is plain. The release scope is frozen, so every row is 1.2 or Later. D-12 (widget rendering modes) is the only item that needs Graham's call against "light only".

## Notes and caveats
- The cause of D-1 is inferred from the layout (minimumScaleFactor under vertical pressure). Confirm it in Xcode before fixing.
- J12 theme pictures all show Fortune (pass 1), so I judged only Bubblegum, Fortune and the gallery swatches. Pumpkin, Moon and the other themes are unjudged at full size.
- There are no widget or Live Activity pictures in ci-audit. D-12 and D-13 are judged from code.

## No changes made
- /workspace/popin-eval at 697ba47: `git status --short` shows only the untracked `REPORT.md` and `REPORT-design.md`. No stash, no local branches, no commits.
- /workspace/popin-eval-audit (worktree of origin/ci-audit at 4ac3934): clean.
- Nothing was pushed. No workflows were run, no PRs, issues or comments were made, App Store Connect was not touched, nothing was bought, and nothing was uploaded or published. The mockups exist only on the box.
