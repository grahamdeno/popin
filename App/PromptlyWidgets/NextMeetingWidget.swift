import SwiftUI
import WidgetKit

/// Home Screen widget: the next meeting, a live countdown, and the bubble growing in steps over the last hour.
/// Tapping the bubble opens Pop In and pops it there (with the full gum animation), then opens the meeting link.
struct NextMeetingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: NextMeetingKind.kind, provider: NextMeetingProvider()) { entry in
            NextMeetingView(entry: entry)
                .containerBackground(for: .widget) { WidgetFill() }
        }
        .configurationDisplayName("Next meeting")
        .description("The next meeting and its bubble. Tap the bubble to pop it.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

struct NextMeetingEntry: TimelineEntry {
    let date: Date
    let next: WidgetSnapshot.Item?
    let then: [WidgetSnapshot.Item]
}

struct NextMeetingProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextMeetingEntry {
        NextMeetingEntry(date: .now,
                         next: .init(id: "p", title: "Sprint review", start: .now.addingTimeInterval(720),
                                     end: .now.addingTimeInterval(2520), service: "Teams", hasLink: true),
                         then: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (NextMeetingEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry(at: .now, snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextMeetingEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let now = Date.now
        let first = snapshot.upcoming(at: now).first
        let dates = WidgetTimeline.entryDates(now: now, start: first?.start, end: first?.end)
        let entries = dates.map { entry(at: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(at date: Date, snapshot: WidgetSnapshot) -> NextMeetingEntry {
        let upcoming = snapshot.upcoming(at: date)
        return NextMeetingEntry(date: date, next: upcoming.first, then: Array(upcoming.dropFirst().prefix(4)))
    }
}

/// Story 9.2: white on a full-color Home Screen; on a tinted or clear one the white fill goes and the system's own
/// background shows.
struct WidgetFill: View {
    @Environment(\.widgetRenderingMode) private var mode
    var body: some View { mode == .fullColor ? Color.white : Color.clear }
}

/// Story 9.1: the count as the app writes it, "8 min", with the unit in secondary. It changes on each minute's
/// timeline entry, so there are no ticking seconds. Takes the tint on tinted Home Screens (9.2).
struct WidgetCount: View {
    let now: Date
    let start: Date
    var big: Font = .title.weight(.medium)
    var unit: Font = .subheadline.weight(.medium)
    @Environment(\.widgetRenderingMode) private var mode

    var body: some View {
        let parts = CountText.parts(now: now, start: start)
        let ink = parts.unit.isEmpty ? (mode == .fullColor ? GumColors.dark : Color.primary) : (mode == .fullColor ? Tokens.ink : Color.primary)
        let bigText = Text(parts.big).font(big.monospacedDigit()).foregroundStyle(ink)
        let unitText = Text(parts.unit.isEmpty ? "" : " \(parts.unit)").font(unit)
            .foregroundStyle(mode == .fullColor ? Tokens.secondary : Color.secondary)
        Text("\(bigText)\(unitText)")
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .widgetAccentable()
            .accessibilityLabel(parts.big == "Now" ? "Now" : "in \(parts.big) \(parts.unit)")
    }
}

/// Story 9.2: the gum ball on a full-color Home Screen; an outline that takes the tint on a tinted or clear one.
struct WidgetBall: View {
    @Environment(\.widgetRenderingMode) private var mode
    var body: some View {
        if mode == .fullColor {
            GumBall()
        } else {
            Circle().strokeBorder(Color.primary, lineWidth: 2)
                .aspectRatio(1, contentMode: .fit)
                .widgetAccentable()
                .accessibilityHidden(true)
        }
    }
}

struct NextMeetingView: View {
    let entry: NextMeetingEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var mode

    private var ink: Color { mode == .fullColor ? Tokens.ink : .primary }
    private var secondary: Color { mode == .fullColor ? Tokens.secondary : .secondary }
    private var timeColor: Color { mode == .fullColor ? GumColors.accentText : .primary }
    /// Words over the gum: ink on their white plate, plain on the outline.
    private var onBall: Color { mode == .fullColor ? Tokens.ink : .primary }

    var body: some View {
        if family == .accessoryRectangular || family == .accessoryCircular || family == .accessoryInline {
            LockScreenNext(entry: entry, family: family)
        } else if let next = entry.next {
            let progress = WidgetTimeline.progress(now: entry.date, start: next.start)
            switch family {
            case .systemMedium: medium(next, progress: progress)
            case .systemLarge: large(next, progress: progress)
            default: small(next, progress: progress)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nothing coming up").font(.subheadline.weight(.semibold)).foregroundStyle(ink)
                Text("Next two days are clear").font(.caption).foregroundStyle(secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
            .overlay(alignment: .bottomTrailing) { bubble(progress: 0, base: 70).offset(x: 24, y: 28) }
        }
    }

    private func small(_ next: WidgetSnapshot.Item, progress: Double) -> some View {
        ZStack(alignment: .bottomTrailing) {
            bubble(progress: progress, base: 96).offset(x: 30, y: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(next.start <= entry.date ? "Now" : "Next")
                    .font(.caption.weight(.medium)).foregroundStyle(secondary)
                Text(next.title)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(ink).lineLimit(2)
                WidgetCount(now: entry.date, start: next.start).padding(.top, 4)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
        }
        .widgetURL(WidgetTimeline.popURL(meetingID: next.id))
    }

    private func medium(_ next: WidgetSnapshot.Item, progress: Double) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(next.start <= entry.date ? "Now" : "Next")
                    .font(.caption.weight(.medium)).foregroundStyle(secondary)
                Text(next.title)
                    .font(.headline).foregroundStyle(ink).lineLimit(2)
                Text(subtitle(next)).font(.caption).foregroundStyle(secondary).lineLimit(1)
                WidgetCount(now: entry.date, start: next.start).padding(.top, 4)
                Spacer(minLength: 4)
                ForEach(entry.then.prefix(2), id: \.id) { item in
                    HStack(spacing: 6) {
                        Text(time(item.start)).font(.caption2.weight(.semibold)).foregroundStyle(timeColor)
                        Text(item.title).font(.caption2).foregroundStyle(ink).lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)

            Link(destination: WidgetTimeline.popURL(meetingID: next.id) ?? URL(string: "promptly://")!) {
                ZStack(alignment: .bottom) {
                    bubble(progress: progress, base: 120).offset(y: 40)
                    Text(next.hasLink ? "Pop to join" : "Pop")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(onBall)
                        // Words never sit on the gum (docs/brand.md): a small white plate keeps them at 4.5:1 or
                        // better on every theme. On tinted screens the plate is clear and the words take the tint.
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(mode == .fullColor ? Color.white.opacity(0.92) : Color.clear))
                        .padding(.bottom, 24 + 40 * progress)
                }
                .frame(width: 140)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private func large(_ next: WidgetSnapshot.Item, progress: Double) -> some View {
        ZStack(alignment: .bottom) {
            Link(destination: WidgetTimeline.popURL(meetingID: next.id) ?? URL(string: "promptly://")!) {
                ZStack(alignment: .bottom) {
                    bubble(progress: progress, base: 170).offset(y: 70)
                    Text(next.hasLink ? "Pop to join" : "Pop")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(onBall)
                        // Words never sit on the gum (docs/brand.md): a small white plate keeps them at 4.5:1 or
                        // better on every theme. On tinted screens the plate is clear and the words take the tint.
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(mode == .fullColor ? Color.white.opacity(0.92) : Color.clear))
                        .padding(.bottom, 36 + 60 * progress)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(next.start <= entry.date ? "Now" : "Next")
                    .font(.footnote.weight(.medium)).foregroundStyle(secondary)
                Text(next.title)
                    .font(.title3.weight(.semibold)).foregroundStyle(ink).lineLimit(2)
                Text(subtitle(next)).font(.footnote).foregroundStyle(secondary).lineLimit(1)
                WidgetCount(now: entry.date, start: next.start, big: .largeTitle.weight(.medium), unit: .headline.weight(.medium))
                    .padding(.top, 4)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.then, id: \.id) { item in
                        HStack(spacing: 8) {
                            Text(time(item.start)).font(.footnote.weight(.semibold)).foregroundStyle(timeColor)
                            Text(item.title).font(.footnote).foregroundStyle(ink).lineLimit(1)
                        }
                    }
                }
                .padding(.top, 10)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(18)
        }
    }

    /// Grows from `base` up to 1.8 times as the meeting nears, easing between redraws.
    private func bubble(progress: Double, base: CGFloat) -> some View {
        let size = base * (1 + 0.8 * CGFloat(progress))
        return WidgetBall()
            .frame(width: size, height: size * (1 + 0.08 * CGFloat(progress)))
            .shadow(color: mode == .fullColor ? GumColors.accent.opacity(0.25) : .clear, radius: 10, y: -4)
            .animation(.easeOut(duration: 1.5), value: progress)
    }

    private func subtitle(_ item: WidgetSnapshot.Item) -> String {
        [time(item.start), item.service.isEmpty ? nil : item.service].compactMap { $0 }.joined(separator: " · ")
    }

    private func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}


/// Lock Screen widgets: the next meeting and its countdown, in the system's tinted style.
private struct LockScreenNext: View {
    let entry: NextMeetingEntry
    let family: WidgetFamily

    var body: some View {
        Group {
            if let next = entry.next {
                switch family {
                case .accessoryCircular:
                    ZStack {
                        AccessoryWidgetBackground()
                        VStack(spacing: 0) {
                            Image(systemName: "circle.fill").font(.caption2)
                            Text(CountText.short(now: entry.date, start: next.start))
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .multilineTextAlignment(.center).minimumScaleFactor(0.6)
                        }
                        .padding(4)
                    }
                case .accessoryInline:
                    Text(next.start > entry.date ? "\(next.title) at \(next.start.formatted(date: .omitted, time: .shortened))" : "\(next.title) now")
                default:
                    VStack(alignment: .leading, spacing: 1) {
                        Text(next.title).font(.headline).lineLimit(1)
                        Text(next.start.formatted(date: .omitted, time: .shortened) + (next.service.isEmpty ? "" : " · \(next.service)"))
                            .font(.caption).lineLimit(1)
                        WidgetCount(now: entry.date, start: next.start, big: .headline, unit: .caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                switch family {
                case .accessoryCircular: ZStack { AccessoryWidgetBackground(); Image(systemName: "checkmark") }
                case .accessoryInline: Text("No meetings coming up")
                default: Text("Nothing coming up").font(.headline)
                }
            }
        }
        .widgetURL(entry.next.flatMap { WidgetTimeline.popURL(meetingID: $0.id) })
    }

}

/// Home Screen widget: today's coming meetings as a list, the next one marked.
struct UpcomingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UpcomingMeetings", provider: NextMeetingProvider()) { entry in
            UpcomingView(entry: entry)
                .containerBackground(for: .widget) { WidgetFill() }
        }
        .configurationDisplayName("Coming up")
        .description("Your next few meetings at a glance.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct UpcomingView: View {
    let entry: NextMeetingEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var mode
    private var ink: Color { mode == .fullColor ? Tokens.ink : .primary }
    private var secondary: Color { mode == .fullColor ? Tokens.secondary : .secondary }

    var body: some View {
        let items = ([entry.next].compactMap { $0 } + entry.then).prefix(family == .systemLarge ? 6 : 3)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                WidgetBall().frame(width: 16, height: 16)
                Text("Coming up").font(.footnote.weight(.semibold)).foregroundStyle(secondary)
            }
            if items.isEmpty {
                Text("Nothing in the next two days").font(.subheadline.weight(.semibold)).foregroundStyle(ink)
            }
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(item.start.formatted(date: .omitted, time: .shortened))
                        .font(.footnote.weight(.semibold).monospacedDigit())
                        .foregroundStyle(mode == .fullColor ? GumColors.accentText : .primary)
                        .frame(minWidth: 72, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title).font(i == 0 ? .subheadline.weight(.semibold) : .footnote)
                            .foregroundStyle(ink).lineLimit(1)
                        if i == 0, item.start > entry.date {
                            WidgetCount(now: entry.date, start: item.start, big: .caption.weight(.semibold), unit: .caption)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .widgetURL(entry.next.flatMap { WidgetTimeline.popURL(meetingID: $0.id) })
    }
}
