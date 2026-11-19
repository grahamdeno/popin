import SwiftUI

/// Settings, laid out like Scales and Shoebox: short groups under small quiet titles, each row showing its answer,
/// and a row opens one screen with its choices. Toggles sit right in the list.
struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var versionTaps = 0
    /// Debug card switch (Diagnostics): "plate" or "glass". Home reads the same key through `CardStyle.current`.
    @AppStorage(CardStyle.key, store: Prefs.current.defaults) private var cardStyleRaw = CardStyle.plate.rawValue

    var body: some View {
        NavigationStack {
            SettingsPage {
                proRow

                SettingsGroup("Meetings", note: "Meetings with a video link ring full screen. Other events get a quiet notification.") {
                    SettingsLink("Calendars", value: CalendarGroups.summary(model.calendars, disabled: model.disabledCalendarIDs)) {
                        CalendarsPage()
                    }
                    SettingsLink("Ring before", value: "\(model.leadMinutes) min") {
                        ChoicePage(title: "Ring before", note: "How early the alarm rings. The bubble keeps growing until the meeting starts.",
                                   options: [1, 2, 5, 10], selected: model.leadMinutes, label: { "\($0) minute\($0 == 1 ? "" : "s")" },
                                   locked: { $0 > 5 && !model.store.isPro }) { model.leadMinutes = $0 }
                    }
                    SettingsLink("Early alarm", value: model.earlyMinutes > model.leadMinutes ? "\(model.earlyMinutes) min" : "Off") {
                        ChoicePage(title: "Early alarm", note: "A second alarm before the main one, so you can wrap up. It rings like the main alarm.",
                                   options: [0, 5, 10, 15, 30].filter { $0 == 0 || $0 > model.leadMinutes }, selected: model.earlyMinutes > model.leadMinutes ? model.earlyMinutes : 0,
                                   label: { $0 == 0 ? "Off" : "\($0) minutes before" },
                                   locked: { _ in false }) { model.earlyMinutes = $0 }
                    }
                    SettingsLink("Work hours", value: model.workHours.summary()) {
                        WorkHoursPage()
                    }
                    SettingsLink("Pause alerts", value: (model.pausedUntil ?? .distantPast) > .now ? "Until \(model.pausedUntil!.formatted(date: .omitted, time: .shortened))" : "Off") {
                        ChoicePage(title: "Pause alerts", note: "No alarms or notifications until then. You can also pause from the menu on Home.",
                                   options: [0, 1, 2, 99], selected: (model.pausedUntil ?? .distantPast) > .now ? 1 : 0,
                                   label: { [0: "Off", 1: "1 hour", 2: "2 hours", 99: "Rest of today"][$0] ?? "" }) { v in
                            switch v {
                            case 0: model.resume()
                            case 99: model.pause(until: PauseRule.endOfDay(from: .now))
                            default: model.pause(until: .now.addingTimeInterval(Double(v) * 3600))
                            }
                        }
                    }
                    SettingsToggle("Apple Reminders", detail: model.appleReminders
                                   ? "Reminders with a time ring like a meeting"
                                   : "Ring for reminders with a time, like ones you ask Siri for",
                                   isOn: Binding(get: { model.appleReminders }, set: { on in
                                       if on { Task { await model.enableAppleReminders() } } else { model.appleReminders = false }
                                   }))
                    SettingsToggle("Accepted meetings only", detail: "Skip meetings you haven't accepted yet",
                                   isOn: Binding(get: { model.acceptedOnly }, set: { model.acceptedOnly = $0 }))
                }

                SettingsGroup("Alarm", note: model.testMessage) {
                    Button {
                        Task { await model.testAlarm(withCountdown: false) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Test the alarm").font(.body).foregroundStyle(Brand.accentText)
                                Text("Rings in 20 seconds, the same way a meeting would")
                                    .font(.footnote).foregroundStyle(Brand.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            Image(systemName: "bell.badge").foregroundStyle(Brand.accentText)
                        }
                        .padding(.vertical, 10)
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    SettingsLink("Sound", value: model.alarmSound.label) {
                        ChoicePage(title: "Alarm sound",
                                   note: "Tap one to hear it. It rings at one steady volume. Apple plays Apple's alarm beep here and while Pop In is open, and Apple's default alarm on the Lock Screen.",
                                   options: AlarmSoundChoice.available, selected: model.alarmSound, label: \.label,
                                   locked: { $0.isPro && !model.store.isPro }) { choice in
                            model.alarmSound = choice
                            AlarmLoop.preview(choice)
                        }
                    }
                    SettingsToggle("Lock Screen countdown", detail: "The bubble on your Lock Screen before it rings",
                                   isOn: Binding(get: { model.countdownCard }, set: { model.countdownCard = $0 }))
                    SettingsToggle("Heads-up buzzes", detail: "One buzz at 5 and at 2 minutes, even when locked",
                                   isOn: Binding(get: { model.nudges }, set: { model.nudges = $0 }))
                }

                SettingsGroup("Bubble") {
                    SettingsLink("Theme", value: model.surprise ? "Surprise me" : model.gumColor.label) {
                        ThemeGalleryPage()
                    }
                    SettingsLink("Pop sound", value: model.popChoice.label) {
                        ChoicePage(title: "Pop sound", note: "What you hear when a bubble pops. Quiet when your phone is on silent.",
                                   options: PopChoice.available, selected: model.popChoice, label: \.label,
                                   locked: { $0.isPro && !model.store.isPro }) { choice in
                            model.popChoice = choice
                            PopSound.play()
                        }
                    }
                    if model.gumColor == .fortune {
                        SettingsToggle("Meeting fortunes", detail: "A light one-liner inside the ball in the last fifteen minutes and when it rings",
                                       isOn: Binding(get: { model.fortunes }, set: { model.fortunes = $0 }))
                    }
                    SettingsToggle("Buzz as it gets close", detail: "Builds over the last ten minutes while Pop In is open",
                                   isOn: Binding(get: { model.buzz }, set: { model.buzz = $0 }))
                    SettingsToggle("Keep screen on",
                                   detail: "Like a desk clock while Pop In is open", pro: !model.store.isPro,
                                   isOn: Binding(get: { model.keepAwake }, set: { on in
                                       if on && !model.store.isPro { model.showPro = true } else { model.keepAwake = on }
                                   }))
                }

                // Tips only for people who already have Pro, so a tip never competes with the one purchase.
                if model.store.isPro {
                    SettingsGroup("Support Pop In", note: model.store.thanked ? "Thank you. It means a lot."
                                   : model.store.message ?? "Thanks for getting Pro. If Pop In earns more, a tip helps keep it going.") {
                        HStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { i in
                                Button {
                                    Task {
                                        await model.store.tip(i)
                                        if model.store.thanked { PopSound.play() }
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: ["cup.and.saucer", "birthday.cake", "gift"][i]).font(.title3)
                                        Text(model.store.tipPrice(i)).font(.subheadline.weight(.semibold))
                                    }
                                    .foregroundStyle(Brand.accentText)
                                    .frame(maxWidth: .infinity, minHeight: 64)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(Brand.accentText.opacity(0.08)))
                                }
                                .buttonStyle(.plain)
                                // One purchase at a time, so a second tap can't stack on an open App Store sheet.
                                .disabled(model.store.purchasing)
                                .opacity(model.store.purchasing ? 0.5 : 1)
                                .accessibilityLabel("Tip \(model.store.tipPrice(i))")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                SettingsGroup("Help") {
                    SettingsExternal("Help and support", url: "https://popin.tangomike.app/support.html")
                    SettingsExternal("Privacy", url: "https://popin.tangomike.app/privacy.html")
                }

                if versionTaps >= 5 { diagnostics }

                VStack(spacing: 6) {
                    Wordmark()
                    Text("Reads your calendar. Never changes it.\nNothing leaves your phone.")
                        .font(.footnote)
                        .foregroundStyle(Brand.secondary)
                        .multilineTextAlignment(.center)
                    Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                        .font(.footnote)
                        .foregroundStyle(Brand.secondary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .onTapGesture { versionTaps += 1 }
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold).foregroundStyle(Brand.ink)
                }
            }
        }
        .task { await model.refresh() }
        .sheet(isPresented: Binding(get: { model.showPro }, set: { model.showPro = $0 })) {
            ProView().environment(model)
        }
    }

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Story 8.1 (M3): three theme balls, two lines, and a black capsule with the App Store price (never written into
    /// the app). Once Pro is owned the capsule goes.
    private var proRow: some View {
        Button { model.showPro = true } label: {
            HStack(spacing: 14) {
                if !typeSize.isAccessibilitySize { trio }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pop In Pro").font(.body.weight(.semibold)).foregroundStyle(Brand.ink)
                    Text(model.store.isPro ? "Unlocked. Thank you." : "Unicorn mode, more sounds, desk mode")
                        .font(.footnote).foregroundStyle(Brand.secondary)
                    if typeSize.isAccessibilitySize && !model.store.isPro { priceCapsule }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if !model.store.isPro && !typeSize.isAccessibilitySize { priceCapsule }
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .frame(minHeight: 68)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white))
        }
        .buttonStyle(.plain)
        .modifier(TestingProMenu(store: model.store))
    }

    /// Bubblegum, Water balloon and Fortune, overlapping.
    private var trio: some View {
        HStack(spacing: -12) {
            ForEach([GumPalette.bubblegum, .waterBalloon, .fortune], id: \.self) { palette in
                SwatchBall(palette: palette).frame(width: 30, height: 30)
            }
        }
        .accessibilityHidden(true)
    }

    private var priceCapsule: some View {
        Text(model.store.price)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Brand.ink))
            .fixedSize()
            .accessibilityLabel("\(model.store.price), one-time purchase")
    }

    /// For the owner and for support: alarm count, test alarms, and the bubble rollback switch.
    private var diagnostics: some View {
        SettingsGroup("Diagnostics", note: alarmStatus) {
            Button("Ring in 20 s") { Task { await model.testAlarm(withCountdown: false) } }
                .foregroundStyle(Brand.ink).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            Button("Card, then ring") { Task { await model.testAlarm(withCountdown: true) } }
                .foregroundStyle(Brand.ink).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            Picker("Ball", selection: Binding(get: { model.ballStyle }, set: { model.ballStyle = $0 })) {
                Text("Bubble").tag(BallStyle.bubble)
                Text("Steady ball").tag(BallStyle.steady)
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 10)
            // Debug switch for the phone check: the card as the white plate (default) or as glass.
            Picker("Card", selection: $cardStyleRaw) {
                Text("Plate").tag(CardStyle.plate.rawValue)
                Text("Glass").tag(CardStyle.glass.rawValue)
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 10)
            if let message = model.testMessage {
                Text(message).font(.subheadline).foregroundStyle(Brand.ink).padding(.vertical, 8)
            }
        }
    }

    private var alarmStatus: String {
        if !model.alarmsAuthorized { return "Alarms are off for Pop In. Turn them on in Settings." }
        if !model.calendarAuthorized { return "Calendar access is off." }
        let count = "\(model.scheduledAlarms) alarm\(model.scheduledAlarms == 1 ? "" : "s") set"
        guard let next = model.nextAlarm else { return "\(count). No meetings in the next two days." }
        let f = DateFormatter()
        f.dateStyle = Calendar.current.isDateInToday(next) ? .none : .short
        f.timeStyle = .short
        return "\(count). Next rings at \(f.string(from: next))."
    }
}

// MARK: Building blocks

/// The settings ground: a soft off-white with white cards one step above it.
struct SettingsPage<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) { content }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 40)
        }
        .background(Color(white: 0.965).ignoresSafeArea())
    }
}

/// A small quiet title, a white card of rows, and at most one quiet line under it.
struct SettingsGroup<Content: View>: View {
    let title: String?
    var note: String?
    @ViewBuilder var content: Content

    init(_ title: String?, note: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.note = note
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.secondary)
                    .padding(.leading, 18)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(alignment: .leading, spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        row
                        if index < rows.count - 1 { Divider().overlay(Brand.hairline) }
                    }
                }
            }
            .padding(.horizontal, 18)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white))
            if let note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(Brand.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 18)
            }
        }
    }
}

/// A row that opens its own screen and shows its current answer.
struct SettingsLink<Destination: View>: View {
    let title: String
    let value: String
    @ViewBuilder var destination: () -> Destination

    init(_ title: String, value: String, @ViewBuilder destination: @escaping () -> Destination) {
        self.title = title
        self.value = value
        self.destination = destination
    }

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 10) {
                // Large text: the answer goes under the title, so neither breaks mid-word.
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.body).foregroundStyle(Brand.ink)
                        Text(value).font(.body).foregroundStyle(Brand.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                } else {
                    Text(title).font(.body).foregroundStyle(Brand.ink).layoutPriority(1)
                    Spacer(minLength: 12)
                    Text(value).font(.body).foregroundStyle(Brand.secondary).lineLimit(1).fixedSize()
                }
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.secondary.opacity(0.6))
            }
            .padding(.vertical, 8)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The one way Pop In marks something that needs Pro: a small pill with the word (story 8.4). White on the theme's
/// accent text color, which measures at least 4.5:1 on every theme (ProPillTests).
struct ProPill: View {
    static let word = Color.white
    static func fill(_ palette: GumPalette) -> Color { palette.accentText }

    var body: some View {
        Text("Pro")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Self.word)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Self.fill(GumPalette.current)))
            .accessibilityLabel("Pro")
    }
}

struct SettingsToggle: View {
    let title: String
    let detail: String
    let pro: Bool
    @Binding var isOn: Bool

    init(_ title: String, detail: String, pro: Bool = false, isOn: Binding<Bool>) {
        self.title = title
        self.detail = detail
        self.pro = pro
        self._isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title).font(.body).foregroundStyle(Brand.ink)
                    if pro { ProPill() }
                }
                Text(detail).font(.footnote).foregroundStyle(Brand.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(Brand.coralDark)
        .padding(.vertical, 10)
        .frame(minHeight: 52)
    }
}

/// Opens a page on the website in Safari (Pop In itself never uses the network).
struct SettingsExternal: View {
    let title: String
    let url: String

    init(_ title: String, url: String) {
        self.title = title
        self.url = url
    }

    var body: some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                HStack {
                    Text(title).font(.body).foregroundStyle(Brand.ink)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.secondary.opacity(0.6))
                }
                .frame(minHeight: 52)
                .contentShape(Rectangle())
            }
        }
    }
}

/// One screen with a title, its choices as words, and a checkmark on the current one.
struct ChoicePage<T: Hashable>: View {
    let title: String
    var note: String?
    let options: [T]
    @State var selected: T
    let label: (T) -> String
    var locked: (T) -> Bool = { _ in false }
    let pick: (T) -> Void
    @Environment(AppModel.self) private var model

    init(title: String, note: String? = nil, options: [T], selected: T, label: @escaping (T) -> String,
         locked: @escaping (T) -> Bool = { _ in false }, pick: @escaping (T) -> Void) {
        self.title = title
        self.note = note
        self.options = options
        self._selected = State(initialValue: selected)
        self.label = label
        self.locked = locked
        self.pick = pick
    }

    var body: some View {
        SettingsPage {
            SettingsGroup(nil, note: note) {
                ForEach(options, id: \.self) { option in
                    let isLocked = locked(option)
                    Button {
                        if isLocked { model.showPro = true } else { selected = option; pick(option) }
                    } label: {
                        HStack {
                            Text(label(option)).font(.body).foregroundStyle(Brand.ink)
                            if isLocked { ProPill() }
                            Spacer()
                            if option == selected {
                                Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(Brand.ink)
                            }
                        }
                        .frame(minHeight: 52)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(option == selected ? .isSelected : [])
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { AlarmLoop.stop() }
    }
}

/// A small still ball in a given palette, for the color choice (GumBall follows the current palette).
struct SwatchBall: View {
    let palette: GumPalette

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(RadialGradient(colors: [palette.light, palette.base, palette.dark],
                                             center: UnitPoint(x: 0.38, y: 0.26), startRadius: 0, endRadius: w * 0.68))
                ThemeMarks(palette: palette, w: w, h: w)
                if palette == .fortune {
                    FortuneRim(lineWidth: max(1.5, w * 0.057))
                    FourPointStar().fill(.white.opacity(0.9)).frame(width: w * 0.23, height: w * 0.23)
                        .offset(x: w * 0.07, y: -w * 0.14)
                }
                if palette == .unicorn {
                    UnicornSheen(phase: 0.5).clipShape(Circle())
                    Circle().strokeBorder(AngularGradient(colors: GumPalette.rainbow + [GumPalette.rainbow[0]], center: .center),
                                          lineWidth: max(1.5, w * 0.045))
                }
                // Story 8.5: the same light as the big bubble, scaled.
                BallLight(size: w, soft: palette == .fortune)
                ThemeTopper(palette: palette, w: w)
            }
            .frame(width: w, height: w)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// TestFlight only: press and hold the Pop In Pro row to see the free version again after the free test purchase.
/// Absent everywhere else (the App Store build never has a sandbox purchase).
private struct TestingProMenu: ViewModifier {
    let store: ProStore
    @State private var upcoming = GumPalette.previewUpcoming
    func body(content: Content) -> some View {
        if store.isSandbox {
            content.contextMenu {
                if store.purchased {
                    Button(store.previewFree ? "Back to Pro (testing)" : "Preview the free version (testing)") {
                        store.previewFree.toggle()
                    }
                }
                Button(upcoming ? "Hide upcoming themes (testing)" : "Show upcoming themes (testing)") {
                    upcoming.toggle()
                    GumPalette.previewUpcoming = upcoming
                }
            }
        } else {
            content
        }
    }
}
