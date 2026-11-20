import SwiftUI

/// The meeting that just rang, full screen: the bubble has risen. Pop it to join, or say you're not going.
struct NowView: View {
    let meeting: Meeting
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var pops = 0
    @State private var skips = 0
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 40
    /// The countdown: 96 pt at the default size, growing with text size up to `countdownCap`.
    @ScaledMetric(relativeTo: .largeTitle) private var countSize: CGFloat = 96
    @ScaledMetric(relativeTo: .title2) private var unitSize: CGFloat = 22
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The card's own height, so its scroll area is only as tall as its content and the bubble below stays tappable.
    @State private var cardHeight: CGFloat = .infinity

    /// Same cap as Home's countdown: "23 h 59" stays on one line on the smallest supported iPhone.
    private static let countdownCap: CGFloat = 112

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            ZStack {
                Color.white.ignoresSafeArea()

                BubbleView(
                    progress: 1,
                    overdue: model.sinceRing(meeting, now: now),
                    style: model.ballStyle,
                    popCount: pops,
                    skipCount: skips,
                    accessibilityTitle: (meeting.joinURL == nil ? "Pop the bubble to clear " : "Pop the bubble to join ") + meeting.title,
                    minSize: 920, maxSize: 920, steadySize: 560,
                    onPop: {
                        let url = model.join(meeting)
                        leave { if let url { openURL(url) } }
                    }
                )
                .environment(\.themeStill, PowerWatch.shared.strained)
                .environment(\.fortuneText, model.gumColor == .fortune && model.fortunes ? Fortunes.fortune(for: meeting.id) : nil)
                .ignoresSafeArea()

                DiscoLights().ignoresSafeArea()
                    .environment(\.themeStill, PowerWatch.shared.strained)

                // The card scrolls when it's taller than the space (large text). Like Home, it never reaches below
                // three quarters of the screen, so the bubble can always be tapped in the bottom quarter.
                GeometryReader { geo in
                    let full = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
                    let reach = max(0, full * 0.75 - geo.safeAreaInsets.top - 24)
                    ScrollView {
                        card(now: now)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardHeight = $0 }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(maxWidth: 680, maxHeight: min(cardHeight, reach), alignment: .top)
                    .accessibilityIdentifier("alarm-scroll")
                    .padding(.horizontal, 12)
                    .padding(.top, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .hapticRamp(until: meeting.start, enabled: model.buzz)
        .onDisappear { AlarmLoop.stop() }
    }

    /// Mockup M2: "Starts in", the big countdown, the title, the span and service, any missed meetings, the hint,
    /// then Not going and "Snooze 2 min" inside the card. All on the plate; no words on the gum.
    private func card(now: Date) -> some View {
        let parts = Countdown.parts(now: now, start: meeting.start)
        return VStack(alignment: .leading, spacing: 0) {
            if meeting.start > now {
                Text("Starts in")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.accentText)
            }
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel(meeting.start > now ? "Starts in \(parts.big) \(parts.unit)" : "Starting now")
            .accessibilityIdentifier("alarm-countdown")

            Text(meeting.title)
                .font(.system(size: titleSize, weight: .semibold))
                .tracking(-1)
                .foregroundStyle(Brand.ink)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            Text([Countdown.span(meeting), meeting.service?.rawValue].compactMap { $0 }.joined(separator: " · "))
                .font(.callout)
                .foregroundStyle(Brand.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .accessibilityIdentifier("alarm-span")

            ForEach(model.missed(before: meeting)) { old in missedRow(old) }
                .padding(.top, 10)
            // Story 1.3: meetings in the same minute share this alarm, each with its own Join.
            ForEach(model.sameMinute(as: meeting)) { other in
                missedRow(other, words: "Also at \(other.start.formatted(date: .omitted, time: .shortened)): \(other.title)",
                          icon: "calendar")
            }
            .padding(.top, 10)

            Label(meeting.joinURL == nil ? "Pop the bubble when ready" : "Pop the bubble to join", systemImage: "hand.tap")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.accentText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)

            buttons
                .padding(.top, 14)
        }
        .glassCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("alarm-card")
    }

    /// "Also missed: 1:00 PM Standup", wrapping, at least 44 pt, with its own Join while it has a link.
    private func missedRow(_ old: Meeting, words text: String? = nil, icon: String = "clock.badge.exclamationmark") -> some View {
        let words = Label {
            Text(text ?? "Also missed: \(old.start.formatted(date: .omitted, time: .shortened)) \(old.title)")
        } icon: {
            Image(systemName: icon).accessibilityHidden(true)
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(Brand.secondary)
        .fixedSize(horizontal: false, vertical: true)
        return HStack(alignment: .center, spacing: 10) {
            words
            Spacer(minLength: 4)
            if let url = old.joinURL {
                Button { openURL(url) } label: {
                    Text("Join")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.ink)
                        .padding(.horizontal, 14)
                        .frame(minWidth: 44, minHeight: 44)
                        .background(Capsule().fill(Brand.ink.opacity(0.07)))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Join \(old.title)")
            }
        }
        .frame(minHeight: 44)
    }

    /// Not going and "Snooze 2 min", side by side; full width and stacked at accessibility sizes. Each at least 44 pt.
    @ViewBuilder
    private var buttons: some View {
        let stacked = typeSize.isAccessibilitySize
        let notGoing = Button {
            skips += 1
            model.clear(meeting)
            leave {}
        } label: { Text(SkipRule.skipWord(reminder: SkipRule.isReminder(meeting))) }
            .buttonStyle(SecondaryButtonStyle(height: 44, fill: stacked))
        let snooze = Button {
            model.snooze(meeting)
            dismiss()
        } label: { Label("Snooze 2 min", systemImage: "zzz") }
            .buttonStyle(SecondaryButtonStyle(height: 44, fill: stacked))
            .accessibilityLabel("Snooze 2 min")
        if stacked {
            VStack(alignment: .leading, spacing: 10) { notGoing; snooze }
        } else {
            HStack(spacing: 10) { notGoing; snooze; Spacer(minLength: 0) }
        }
    }

    /// Let the pop play, then leave.
    private func leave(_ then: @escaping () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1000))
            dismiss()
            then()
        }
    }
}
