import SwiftUI
import UIKit

/// Home: the next meeting and how long until it. The gum bubble inflates underneath; tap it to pop it and join.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var addingReminder = false
    @State private var playing = false
    @State private var showGallery = false
    @State private var showCalendars = ScreenshotMode.scene.map { [ScreenshotScene.settings, .pro, .manycals].contains($0) } ?? false

    @Environment(\.horizontalSizeClass) private var sizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 32
    /// The countdown: 88 pt at the default size, growing with text size up to `countdownCap`.
    @ScaledMetric(relativeTo: .largeTitle) private var countSize: CGFloat = 88
    @ScaledMetric(relativeTo: .title2) private var unitSize: CGFloat = 22

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The column's own height, so its scroll area is only as tall as its content (the bubble stays tappable below).
    @State private var columnContentHeight: CGFloat = .infinity

    /// The largest the countdown grows. "23 h 59" has to stay on one line on the smallest supported iPhone (375 pt
    /// wide, a 303 pt card): at about 0.6 em a digit that is room for roughly 125 pt, so 112 keeps a margin. Checked
    /// by the small-phone big-text picture and Apple's textClipped audit.
    private static let countdownCap: CGFloat = 112
    /// On iPhone the column's bottom stops at this share of the screen height; the bottom quarter stays for the bubble.
    private static let columnReach: CGFloat = 0.75

    @State private var lastTouch = Date()
    @Environment(\.scenePhase) private var scenePhase
    @State private var quiet = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let upcoming = model.upcoming(at: now)
            let next = model.calendarAuthorized && model.alarmsAuthorized ? upcoming.first : nil
            let progress = next.map { Countdown.progress(now: now, start: $0.start) } ?? 0
            let overdue = next.map { model.sinceRing($0, now: now) } ?? 0
            let quietNow = QuietMode.isQuiet(now: now, lastTouch: lastTouch, nextStart: next?.start)

            Group {
            if sizeClass == .regular {
                // iPad: the header and the scrolling column on the left, the bubble on the right.
                ZStack {
                    Color.white.ignoresSafeArea()
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            header
                            scrollColumn(now: now, upcoming: upcoming, next: next, onPhone: false)
                        }
                        .frame(maxWidth: 480, alignment: .leading)
                        .padding(.horizontal, 32)
                        bubble(next: next, progress: progress, overdue: overdue, maxSize: 760)
                            .frame(maxWidth: .infinity)
                            .ignoresSafeArea()
                    }
                }
            } else {
                // iPhone: the bubble keeps its size underneath. The header is fixed on white; the column scrolls
                // over the bubble and its bottom stops at three quarters of the screen height.
                GeometryReader { geo in
                    let full = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
                    let columnHeight = max(0, full * Self.columnReach - geo.safeAreaInsets.top)
                    ZStack(alignment: .top) {
                        Color.white.ignoresSafeArea()
                        bubble(next: next, progress: progress, overdue: overdue, maxSize: 880)
                            .ignoresSafeArea()
                        VStack(spacing: 0) {
                            header
                            scrollColumn(now: now, upcoming: upcoming, next: next, onPhone: true)
                        }
                        .frame(height: columnHeight, alignment: .top)
                    }
                }
            }
            }
            .onChange(of: quietNow, initial: true) { _, q in quiet = q }
        }
        .environment(\.themeStill, quiet || PowerWatch.shared.strained)
        // Coming back to Pop In counts as a touch, so it never opens already in quiet mode.
        .onChange(of: scenePhase) { _, p in if p == .active { lastTouch = .now; quiet = false } }
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in
            lastTouch = .now
            quiet = false
        })
        .hapticRamp(until: model.upcoming(at: .now).first?.start, enabled: model.buzz && model.arrived == nil)
        .overlay { DiscoLights().ignoresSafeArea().environment(\.themeStill, quiet || PowerWatch.shared.strained) }
        .overlay(alignment: .bottom) { undoToast }
        .sheet(isPresented: $showGallery) {
            NavigationStack { ThemeGalleryPage() }
                .environment(model)
                .sheet(isPresented: Binding(get: { model.showPro }, set: { model.showPro = $0 })) {
                    ProView().environment(model)
                }
        }
        .fullScreenCover(isPresented: $playing) { PopPlayground().environment(model) }
        // If a meeting's alarm arrived while Pop for fun was up, show its screen once the game steps aside.
        .onChange(of: playing) { _, open in
            guard !open, let m = model.arrived else { return }
            model.arrived = nil
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(450))
                model.arrived = m
            }
        }
        .onAppear { if ScreenshotMode.scene == .playground { playing = true } }
        .sheet(isPresented: $addingReminder) {
            AddReminderSheet().environment(model)
        }
        .sheet(isPresented: $showCalendars, onDismiss: { model.applyPendingTheme() }) {
            SettingsView()
                .environment(model)
                .onAppear { model.settingsOpen = true }
                .onDisappear { model.settingsOpen = false }
        }
        .onChange(of: model.closeSettings) { _, close in
            if close { showCalendars = false; model.closeSettings = false }
        }
    }

    /// The Fortune ball's words: in the last fifteen minutes before a real meeting, and always on the Practice demo.
    private func fortune(for next: Meeting?, now: Date) -> String? {
        guard model.gumColor == .fortune, model.fortunes, let next else { return nil }
        guard isDemo(next) || Fortunes.shows(start: next.start, now: now) else { return nil }
        return Fortunes.fortune(for: next.id)
    }

    private func bubble(next: Meeting?, progress: Double, overdue: TimeInterval, maxSize: CGFloat) -> some View {
        let words = fortune(for: next, now: .now)
        return BubbleView(
            progress: progress,
            overdue: overdue,
            style: model.ballStyle,
            popCount: model.popCount,
            skipCount: model.skipCount,
            accessibilityTitle: next.map { ($0.joinURL == nil ? "Pop the bubble to clear " : "Pop the bubble to join ") + $0.title
                + (words.map { ". Fortune: " + $0 } ?? "") } ?? "",
            maxSize: maxSize,
            onPop: next.map { meeting -> () -> Void in
                { if let url = model.join(meeting), !ScreenshotMode.isOn { openURL(url) } }
            }
        )
        .environment(\.fortuneText, words)
    }

    /// The column scrolls under the fixed header. On iPhone it is only as tall as its content (up to the space the
    /// header leaves), so the bubble below it can still be tapped.
    private func scrollColumn(now: Date, upcoming: [Meeting], next: Meeting?, onPhone: Bool) -> some View {
        ScrollView {
            textColumn(now: now, upcoming: upcoming, next: next, showThen: onPhone, later: onPhone ? [] : Array(upcoming.dropFirst().prefix(5)))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { columnContentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: onPhone ? columnContentHeight : .infinity)
    }

    /// Everything the column holds, top to bottom: the paused line, the card, the "Then" strip, the new themes card.
    /// Each sits on the white plate, so words read over any bubble.
    private func textColumn(now: Date, upcoming: [Meeting], next: Meeting?, showThen: Bool, later: [Meeting]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let until = model.pausedUntil, until > now { pausedLine(until) }
            Group {
                if !model.calendarAuthorized || !model.alarmsAuthorized {
                    permissionNotice.glassCard()
                } else if let next {
                    meetingBlock(next, now: now)
                } else {
                    emptyBlock.glassCard()
                }
            }
            if model.calendarAuthorized && model.alarmsAuthorized {
                quietStrip(then: next != nil && showThen ? upcoming.dropFirst().first : nil,
                           skipped: model.skippedLines(at: now), now: now)
            }
            whatsNewCard
            if next != nil, !later.isEmpty { todayList(later) }
        }
    }

    /// "Paused until 3:00 PM · Resume": the first row of the column, at least 44 pt.
    private func pausedLine(_ until: Date) -> some View {
        Button { model.resume() } label: {
            Label("Paused until \(until.formatted(date: .omitted, time: .shortened)) · Resume", systemImage: "pause.fill")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Brand.accentText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .plate(cornerRadius: 22)
    }

    /// At most once a month: the themes that just arrived. Opening it or waving it away both count as seen.
    @ViewBuilder
    private var whatsNewCard: some View {
        let _ = model.whatsNewTick
        let fresh = model.whatsNew
        if !fresh.isEmpty {
            HStack(spacing: 12) {
                HStack(spacing: -10) {
                    ForEach(fresh.prefix(3), id: \.self) { SwatchBall(palette: $0).frame(width: 30, height: 30) }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("New this month").font(.footnote.weight(.medium)).foregroundStyle(Brand.secondary)
                    Text(fresh.map(\.label).formatted(.list(type: .and)))
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink).lineLimit(2)
                    Text(model.store.isPro ? "Included with Pro" : "Try one free for a day")
                        .font(.footnote).foregroundStyle(Brand.accentText)
                }
                Spacer(minLength: 4)
                Button { model.whatsNewDismissed(fresh) } label: {
                    Image(systemName: "xmark").font(.footnote.weight(.semibold)).foregroundStyle(Brand.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Dismiss")
            }
            .padding(.leading, 16)
            .contentShape(Rectangle())
            .onTapGesture { model.whatsNewOpened(fresh); showGallery = true }
            .plate(cornerRadius: 22)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
        }
    }

    private func todayList(_ items: [Meeting]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !items.isEmpty {
                Text("Later")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.secondary)
                    .padding(.top, 40)
            }
            ForEach(items) { item in
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text(Countdown.time(item.start))
                        .lineLimit(1)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.accentText)
                        .fixedSize()
                        .frame(minWidth: 72, alignment: .leading)
                    Text(item.title)
                        .font(.body)
                        .foregroundStyle(Brand.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Fixed at the top on white, at its normal size at every text size. ⋯ holds the actions; the gear opens Settings.
    /// A long press on either shows its name large (the large content viewer).
    private var header: some View {
        HStack(spacing: 8) {
            Wordmark()
            Spacer()
            Menu {
                Button("Add a reminder", systemImage: "plus") { addingReminder = true }
                Button("Pop for fun", systemImage: "circle.hexagongrid") { playing = true }
                if let until = model.pausedUntil, until > .now {
                    Button("Resume alerts", systemImage: "bell") { model.resume() }
                } else {
                    Menu("Pause alerts", systemImage: "pause") {
                        Button("For 1 hour") { model.pause(until: .now.addingTimeInterval(3600)) }
                        Button("For 2 hours") { model.pause(until: .now.addingTimeInterval(7200)) }
                        Button("For the rest of today") { model.pause(until: PauseRule.endOfDay(from: .now)) }
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Brand.ink.opacity(0.07)))
                    .contentShape(Circle())
            }
            .accessibilityLabel("More")
            .accessibilityIdentifier("home-more")
            .accessibilityShowsLargeContentViewer()
            Button { showCalendars = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Brand.ink)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("home-settings")
            .accessibilityShowsLargeContentViewer()
        }
        .dynamicTypeSize(.large)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color.white, ignoresSafeAreaEdges: .top)
    }

    /// One card holds the meeting and its countdown (mockup M1): the meta row, the title, the countdown, the time
    /// span, then the hint and Not going. What comes after is a quiet line below it.
    private func meetingBlock(_ meeting: Meeting, now: Date) -> some View {
        let parts = Countdown.parts(now: now, start: meeting.start)
        let started = meeting.start <= now
        let demo = isDemo(meeting)
        let nextWord = model.gumColor == .moon ? "Next transmission" : "Next"
        let label = demo ? "Practice" : meeting.calendarID == OwnReminder.calendarID || meeting.calendarID == CalendarService.remindersCalendarID ? "Reminder" : [started ? "Happening now" : nextWord, meeting.service?.rawValue].compactMap { $0 }.joined(separator: " · ")
        // How Pop In will alert, so a quiet one is never a surprise.
        let paused = model.isPaused(meeting, now: now)
        let rings = model.ringsFully(meeting) && !paused
        let how: String = paused ? "Paused until \(model.pausedUntil.map { $0.formatted(date: .omitted, time: .shortened) } ?? "later")"
            : rings ? (model.earlyMinutes > model.leadMinutes ? "Rings \(model.earlyMinutes) and \(model.leadMinutes) min before" : "Rings \(model.leadMinutes) min before")
            : model.workHours.contains(meeting.start) ? "Quiet notification only" : "Outside work hours, quiet notification"
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    metaRow(label: label, how: how, rings: rings, showsHow: !demo && !started)
                    Text(meeting.title)
                        .font(.system(size: titleSize, weight: .semibold))
                        .tracking(-0.8)
                        .foregroundStyle(Brand.ink)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAction(named: meeting.joinURL == nil ? "Clear" : "Join") {
                    if let url = model.join(meeting) { openURL(url) }
                }
                .accessibilityAction(named: "Not going") { model.clear(meeting) }
                if !demo { countdown(parts) }
                Text(demo ? "Practice: pop the bubble below." : Countdown.span(meeting, now: now))
                    .font(.callout)
                    .foregroundStyle(Brand.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, demo ? 12 : 4)
                footer(meeting, now: now, demo: demo)
                    .padding(.top, 18)
            }
            .glassCard()
        }
    }

    /// "Next · service" on the leading side and "Rings…" on the trailing side. At accessibility sizes they stack.
    @ViewBuilder
    private func metaRow(label: String, how: String, rings: Bool, showsHow: Bool) -> some View {
        let left = Text(label)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Brand.secondary)
            .fixedSize(horizontal: false, vertical: true)
        let right = Label(how, systemImage: rings ? "bell.fill" : "bell.slash")
            .font(.footnote.weight(.medium))
            .foregroundStyle(rings ? Brand.accentText : Brand.secondary)
            .fixedSize(horizontal: false, vertical: true)
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                left
                if showsHow { right }
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                left
                Spacer(minLength: 8)
                if showsHow { right.multilineTextAlignment(.trailing) }
            }
        }
    }

    /// The big countdown. It never shrinks to fit (no `minimumScaleFactor`), so it keeps its size when the hint
    /// line appears; the title wraps instead.
    private func countdown(_ parts: (big: String, unit: String)) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(parts.big)
                .font(.system(size: min(countSize, Self.countdownCap), weight: .medium))
                .tracking(-2.5)
                .monospacedDigit()
                .contentTransition(reduceMotion ? .identity : .numericText())
                .lineLimit(1)
            if !parts.unit.isEmpty {
                Text(parts.unit)
                    .font(.system(size: unitSize, weight: .medium))
                    .foregroundStyle(Brand.secondary)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(Brand.ink)
        .padding(.top, 14)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("countdown")
    }

    /// The hint and a Not going button at least 44 pt. At accessibility sizes the hint goes first and Not going
    /// follows, full width.
    @ViewBuilder
    private func footer(_ meeting: Meeting, now: Date, demo: Bool) -> some View {
        let hint = hintText(meeting, now: now, demo: demo)
        let notGoing = Button { model.clear(meeting) } label: {
            Text(demo ? "Skip" : "Not going")
        }
        .buttonStyle(SecondaryButtonStyle(height: 44, fill: typeSize.isAccessibilitySize))
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                if let hint { hintLabel(hint) }
                notGoing
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                if let hint { hintLabel(hint) }
                Spacer(minLength: 8)
                notGoing
            }
        }
    }

    /// The line that teaches the bubble: before the first pop, how to pop; after it, a reminder in the last ten
    /// minutes of a meeting with a link.
    private func hintText(_ meeting: Meeting, now: Date, demo: Bool) -> (words: String, accent: Bool)? {
        if !model.taughtPop { return ("Tap the bubble to pop it and join.", false) }
        if !demo, meeting.joinURL != nil, meeting.start.timeIntervalSince(now) < 10 * 60 {
            return ("Pop the bubble to join", true)
        }
        return nil
    }

    private func hintLabel(_ hint: (words: String, accent: Bool)) -> some View {
        Label(hint.words, systemImage: "hand.tap")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(hint.accent ? Brand.accentText : Brand.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The quiet strip under the card, on the plate: "Then 10:30 AM · Title", and a line for each skipped meeting that
    /// can still come back ("Not going: 3:00 PM Design review · Undo", item 7.2). Hidden when it has nothing to say.
    @ViewBuilder
    private func quietStrip(then: Meeting?, skipped: [Meeting], now: Date) -> some View {
        if then != nil || !skipped.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                if let then { thenRow(then, now: now).padding(.vertical, 12) }
                ForEach(skipped) { skippedRow($0, now: now) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .plate(cornerRadius: 18)
        }
    }

    /// "Then 10:30 AM · Title". At accessibility sizes the title goes under the time, two lines at most. The time is
    /// never split.
    private func thenRow(_ then: Meeting, now: Date) -> some View {
        let time = Countdown.time(then.start, now: now)
        return Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Then \(time)").fixedSize(horizontal: false, vertical: true)
                    Text(then.title).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Then \(time) ·").fixedSize()
                    Text(then.title).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Brand.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// "Not going: 3:00 PM Design review · Undo" until the meeting starts. Undo brings it back with its alarm.
    private func skippedRow(_ meeting: Meeting, now: Date) -> some View {
        let words = Text(SkipRule.line(title: meeting.title, time: Countdown.time(meeting.start, now: now)))
            .font(.subheadline)
            .foregroundStyle(Brand.secondary)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
        let undo = Button { model.restore(meeting) } label: {
            Text("Undo")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.ink)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Undo Not going, \(meeting.title)")
        .accessibilityIdentifier("undo-skip")
        return Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) { words.padding(.top, 8); undo }
            } else {
                HStack(alignment: .center, spacing: 12) { words; Spacer(minLength: 4); undo }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The "Try a pop" practice meeting: no countdown to wait for, just pop it.
    private func isDemo(_ meeting: Meeting) -> Bool { meeting.eventID == "demo" }

    private var emptyBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nothing coming up")
                .font(.system(size: titleSize, weight: .semibold))
                .tracking(-0.8)
                .foregroundStyle(Brand.ink)
            Text("Your next two days are clear on the calendars Pop In watches.")
                .font(.callout)
                .foregroundStyle(Brand.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try a pop") { model.startDemo() }
                .buttonStyle(SecondaryButtonStyle(height: 44))
        }
    }

    /// Five seconds to take back a pop or a "Not going", on the plate, low on the screen. At accessibility sizes the
    /// words wrap (three lines at most) and Undo takes its own row. After a skip, the quiet line takes over.
    @ViewBuilder
    private var undoToast: some View {
        if let last = model.lastCleared {
            let words = Text(SkipRule.toast(title: last.title, skipped: model.lastClearedSkipped))
                .font(.subheadline)
                .foregroundStyle(Brand.ink)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            // The tappable area is the full 44 pt height, not just the word (the iPad audit's taps missed it).
            let undo = Button { model.undoClear() } label: {
                Text("Undo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 0) { words.padding(.top, 10); undo }
                } else {
                    HStack(spacing: 12) { words; undo }
                }
            }
            .padding(.horizontal, 18)
            .plate(cornerRadius: 22)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: last.id) {
                try? await Task.sleep(for: .seconds(5))
                if model.lastCleared?.id == last.id { model.lastCleared = nil }
            }
        }
    }

    private var permissionNotice: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.calendarAuthorized ? "Alarms are off" : "Pop In can't see your calendar")
                .font(Brand.display(30))
                .tracking(-0.6)
                .foregroundStyle(Brand.ink)
            Text(model.calendarAuthorized
                 ? "Turn on Alarms for Pop In in Settings so it can ring before your meetings."
                 : "Allow Full Access to Calendars for Pop In in Settings. It only reads, and nothing leaves this iPhone.")
                .font(.callout)
                .foregroundStyle(Brand.secondary)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func subtitle(_ meeting: Meeting, now: Date) -> String {
        [Countdown.span(meeting, now: now), meeting.service?.rawValue].compactMap { $0 }.joined(separator: " · ")
    }
}
