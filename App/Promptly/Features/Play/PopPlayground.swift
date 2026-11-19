import SwiftUI

/// Pop for fun. Every theme's bubble drifts around the screen; tap one and it pops the way that theme does.
/// Three ways to play (rules in `PopGame`): Just pop (the toy), a 30-second Target round (only the named theme
/// scores, and it changes every 5 seconds), and the Waiting room (pop until the next meeting, then pop its bubble
/// to join). Golden bubbles are worth 5; quick pops in a row build a combo.
struct PopPlayground: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppModel.self) private var model
    /// Kept in standard defaults as in 1.0; in demo mode, in the throwaway store (item 11).
    @AppStorage("popBestTarget", store: SettingsSuite.isDemo ? Prefs.current.defaults : UserDefaults.standard) private var bestTarget = 0
    @State private var bubbles: [PlayBubble] = []
    @State private var bursts: [PlayBurst] = []
    @State private var floaters: [PlayFloater] = []
    @State private var game: PopGame?
    @State private var choosing = true
    @State private var over = false
    @State private var newBest = false
    @State private var meeting: Meeting?
    @State private var finale = false
    @State private var target: GumPalette?
    @State private var targetSlot = -1
    @State private var pool: [GumPalette] = []
    @State private var area: CGSize = .zero
    @State private var now = Date.now
    private let count = 10

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Color.white.ignoresSafeArea()
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { tl in
                    let t = tl.date
                    ZStack {
                        ForEach(bubbles) { b in
                            let p = b.position(at: t, in: size, still: reduceMotion)
                            ball(b)
                                .frame(width: b.size, height: b.size)
                                .scaleEffect(b.scale(at: t))
                                .position(p)
                                .onTapGesture { pop(b, at: p, in: size) }
                                .accessibilityElement()
                                .accessibilityLabel((b.golden ? "Golden " : "") + "\(b.palette.label) bubble")
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAction { pop(b, at: p, in: size) }
                        }
                    }
                }
                ForEach(bursts) { burst in
                    PlayBurstView(burst: burst).allowsHitTesting(false)
                }
                ForEach(floaters) { f in
                    PlayFloaterView(floater: f).allowsHitTesting(false)
                }
                if finale, let meeting { finaleBubble(meeting, in: size) }
                VStack(spacing: 10) {
                    topBar
                    if game?.mode == .target, let target, !over { targetCard(target) }
                    Spacer()
                    if choosing { menu } else if over { results }
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .onAppear {
                area = size
                meeting = model.upcoming(at: .now).first { $0.start > .now && $0.start.timeIntervalSinceNow <= PopGame.waitingRoomReach }
                if bubbles.isEmpty { bubbles = (0..<count).map { _ in PlayBubble.random(in: size, entering: false) } }
            }
            .onChange(of: size) { _, s in area = s }
        }
        .statusBarHidden()
        .task { await tick() }
        // Pop In's own alarm screen is the real meeting bubble: step aside for it.
        .onChange(of: model.arrived) { _, m in if m != nil { dismiss() } }
    }

    // MARK: Pieces

    @ViewBuilder
    private func ball(_ b: PlayBubble) -> some View {
        PlayBall(palette: b.palette)
            .overlay {
                if b.golden {
                    Circle().strokeBorder(LinearGradient(colors: [Color(red: 1, green: 0.84, blue: 0.3), Color(red: 0.85, green: 0.6, blue: 0.1)],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing),
                                          lineWidth: max(4, b.size * 0.07))
                    FourPointStar().fill(Color(red: 1, green: 0.84, blue: 0.3))
                        .frame(width: b.size * 0.22, height: b.size * 0.22)
                        .offset(x: b.size * 0.3, y: -b.size * 0.3)
                }
            }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Text(statusText)
                .font(.subheadline.weight(.medium).monospacedDigit())
                .foregroundStyle(Brand.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .glassEffect(.regular, in: .capsule)
                .accessibilityAddTraits(.updatesFrequently)
            if let game, game.combo >= PopGame.comboFrom, !over {
                Text("×\(game.combo)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(Brand.accentText)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 36)
                    .glassEffect(.regular, in: .capsule)
                    .accessibilityLabel("Combo \(game.combo)")
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                    .frame(width: 44, height: 44)
            }
            .glassEffect(.regular, in: .circle)
            .accessibilityLabel("Done")
        }
        .padding(.horizontal, 20)
    }

    private var statusText: String {
        let score = game?.score ?? 0
        switch game?.mode {
        case .target?:
            let left = Int((game?.remaining(at: now) ?? 0).rounded(.up))
            return "\(score) points · 0:\(String(format: "%02d", left))"
        case .waitingRoom?:
            guard let meeting else { return "\(score) points" }
            return "\(score) points · \(Self.clock(meeting.start.timeIntervalSince(now))) to \(meeting.title)"
        default:
            return score == 1 ? "1 popped" : "\(score) popped"
        }
    }

    private func targetCard(_ target: GumPalette) -> some View {
        HStack(spacing: 10) {
            PlayBall(palette: target).frame(width: 34, height: 34)
            Text("Pop only \(target.label)").font(.headline).foregroundStyle(Brand.ink)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .glassEffect(.regular, in: .capsule)
        .id(target)
        .transition(.scale.combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var menu: some View {
        VStack(spacing: 10) {
            Text("Pop for fun").font(.title3.weight(.semibold)).foregroundStyle(Brand.ink)
            if let meeting {
                menuButton("Pop until \(meeting.title)", detail: "Starts in \(Self.clock(meeting.start.timeIntervalSinceNow)). Pop its bubble to join.", primary: true) {
                    start(.waitingRoom)
                }
            }
            menuButton("Target round", detail: "30 seconds. Pop only the theme shown." + (bestTarget > 0 ? " Best: \(bestTarget)" : ""), primary: meeting == nil) {
                start(.target)
            }
            menuButton("Just pop", detail: "No timer, nothing to lose.", primary: false) { start(.free) }
        }
        .padding(18)
        .frame(maxWidth: 420)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .padding(.horizontal, 16)
    }

    private func menuButton(_ title: String, detail: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold)).lineLimit(2)
                Text(detail).font(.footnote).opacity(0.8).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .frame(minHeight: 56)
            .foregroundStyle(primary ? Color.white : Brand.ink)
            .background(RoundedRectangle(cornerRadius: 18).fill(primary ? Brand.ink : Color.white))
        }
        .buttonStyle(.plain)
    }

    private var results: some View {
        VStack(spacing: 10) {
            Text(newBest ? "New best!" : "Time!").font(.title2.weight(.semibold)).foregroundStyle(Brand.ink)
            Text("\(game?.score ?? 0) points" + (newBest ? "" : " · Best \(bestTarget)"))
                .font(.body.monospacedDigit()).foregroundStyle(Brand.secondary)
            HStack(spacing: 10) {
                Button("Again") { start(.target) }.buttonStyle(PrimaryButtonStyle(height: 50))
                Button("Done") { dismiss() }.buttonStyle(SecondaryButtonStyle(height: 50, fill: true))
            }
        }
        .padding(18)
        .frame(maxWidth: 420)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .padding(.horizontal, 16)
    }

    private func finaleBubble(_ meeting: Meeting, in size: CGSize) -> some View {
        let side = min(size.width, size.height) * 0.55
        return VStack(spacing: 14) {
            Button { joinFromFinale(meeting) } label: {
                PlayBall(palette: model.gumColor).frame(width: side, height: side)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(meeting.joinURL == nil ? "Pop to clear \(meeting.title)" : "Pop to join \(meeting.title)")
            Text(meeting.title).font(.title3.weight(.semibold)).foregroundStyle(Brand.ink).multilineTextAlignment(.center)
            Text(meeting.joinURL == nil ? "Pop it. You're on time." : "Pop it to join.")
                .font(.body).foregroundStyle(Brand.secondary)
        }
        .padding(.horizontal, 24)
        .transition(.scale.combined(with: .opacity))
    }

    static func clock(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded(.up)))
        return "\(s / 60):" + String(format: "%02d", s % 60)
    }

    // MARK: Play

    private func start(_ mode: PopGame.Mode) {
        game = PopGame(mode: mode, started: .now)
        choosing = false
        over = false
        newBest = false
        finale = false
        target = nil
        targetSlot = -1
        if mode == .target {
            // A handful of themes per round so the target is easy to spot; Coral sits out (close to Bubblegum).
            pool = Array(GumPalette.available.filter { $0 != .coral }.shuffled().prefix(6))
            bubbles = (0..<count).map { _ in PlayBubble.random(in: area, entering: false, from: pool) }
        }
        now = .now
        advanceTarget(at: now)
    }

    /// Four times a second: the clock, target swaps, the end of a round, the waiting room's finale.
    private func tick() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(250))
            now = .now
            guard let game, !over else { continue }
            switch game.mode {
            case .target:
                if game.isOver(at: now) { finishRound() } else { advanceTarget(at: now) }
            case .waitingRoom:
                guard let meeting else { continue }
                if PopGame.isFinale(secondsLeft: meeting.start.timeIntervalSince(now)) && !finale {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        bubbles.removeAll()
                        finale = true
                    }
                }
            case .free:
                break
            }
        }
    }

    private func advanceTarget(at now: Date) {
        guard let game, game.mode == .target else { return }
        let slot = game.targetSlot(at: now)
        guard slot != targetSlot else { return }
        targetSlot = slot
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            target = PopGame.nextTarget(from: pool, after: target, roll: Int.random(in: 0..<1000))
        }
        // Make sure the new target is on screen at least twice.
        if let target {
            // (A Range like 3..<2 traps, so only top up when there are fewer than two: this crashed build 1050.)
            let missing = max(0, 2 - bubbles.filter { $0.palette == target }.count)
            for _ in 0..<missing { bubbles.append(PlayBubble.random(in: area, entering: true, palette: target)) }
            // Keep the screen from filling up: drop the oldest non-target bubbles beyond a couple extra.
            while bubbles.count > count + 2, let i = bubbles.firstIndex(where: { $0.palette != target }) { bubbles.remove(at: i) }
        }
        PopHaptics.tap()
    }

    private func finishRound() {
        guard let game else { return }
        newBest = game.score > bestTarget
        if newBest { bestTarget = game.score }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { over = true }
    }

    private func pop(_ b: PlayBubble, at p: CGPoint, in size: CGSize) {
        guard bubbles.contains(where: { $0.id == b.id }), !finale else { return }
        bubbles.removeAll { $0.id == b.id }
        var points = 1
        if game != nil && !over {
            points = game!.pop(isTarget: b.palette == target, golden: b.golden, at: .now)
            if game!.mode != .free { floaters.append(PlayFloater(text: points > 0 ? "+\(points)" : (points < 0 ? "−1" : "0"), at: p, good: points > 0)) }
        }
        if points < 0 {
            PopHaptics.prepare()
        } else {
            PopSound.play(file: b.palette.popFile)
            PopHaptics.tap()
        }
        let burst = PlayBurst(palette: b.palette, center: p, size: b.size)
        bursts.append(burst)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1100))
            bursts.removeAll { $0.id == burst.id }
            floaters.removeAll { Date.now.timeIntervalSince($0.born) > 0.9 }
        }
        let pace = game?.mode == .waitingRoom ? PopGame.pace(secondsLeft: meeting?.start.timeIntervalSinceNow ?? 600) : 1
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(500 / pace)))
            guard !finale else { return }
            let palette: GumPalette? = game?.mode == .target
                ? (Double.random(in: 0..<1) < 0.35 ? target : pool.randomElement())
                : nil
            bubbles.append(PlayBubble.random(in: size, entering: true, palette: palette, speed: CGFloat(pace),
                                             golden: game != nil && game?.mode != .free && Double.random(in: 0..<1) < PopGame.goldenChance))
        }
    }

    private func joinFromFinale(_ meeting: Meeting) {
        PopSound.play(file: model.gumColor.popFile)
        PopHaptics.tap()
        if let url = model.join(meeting) { model.linkToOpen = url }
        dismiss()
    }
}

/// "+1", "+5" or "−1" rising from a pop.
struct PlayFloater: Identifiable {
    let id = UUID()
    let text: String
    let at: CGPoint
    let good: Bool
    let born = Date.now
}

struct PlayFloaterView: View {
    let floater: PlayFloater
    @State private var up = false
    var body: some View {
        Text(floater.text)
            .font(.title3.weight(.bold).monospacedDigit())
            .foregroundStyle(floater.good ? Brand.ink : Brand.secondary)
            .position(x: floater.at.x, y: floater.at.y - (up ? 60 : 10))
            .opacity(up ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: 0.8)) { up = true } }
            .accessibilityHidden(true)
    }
}

/// One drifting bubble. Its path is worked out from when it was born, so nothing is stored between frames.
struct PlayBubble: Identifiable {
    let id = UUID()
    let palette: GumPalette
    let size: CGFloat
    let start: CGPoint
    let velocity: CGVector
    let born: Date
    let phase: Double
    var golden = false

    static func random(in area: CGSize, entering: Bool, from pool: [GumPalette] = [], palette chosen: GumPalette? = nil,
                       speed pace: CGFloat = 1, golden: Bool = false) -> PlayBubble {
        var b = make(in: area, entering: entering, palette: chosen ?? (pool.isEmpty ? GumPalette.available : pool).randomElement() ?? .bubblegum, pace: pace)
        b.golden = golden
        return b
    }

    private static func make(in area: CGSize, entering: Bool, palette: GumPalette, pace: CGFloat) -> PlayBubble {
        let s = CGFloat.random(in: 64...150)
        let speed = CGFloat.random(in: 18...42) * pace
        let maxX = max(s + 1, area.width - s / 2)
        let maxY = max(141, area.height - s / 2)
        guard entering else {
            // The first set starts scattered, drifting any way.
            let angle = Double.random(in: 0..<(2 * .pi))
            return PlayBubble(palette: palette, size: s,
                              start: CGPoint(x: CGFloat.random(in: s / 2...maxX), y: CGFloat.random(in: 140...maxY)),
                              velocity: CGVector(dx: CGFloat(cos(angle)) * speed, dy: CGFloat(sin(angle)) * speed),
                              born: .now, phase: Double.random(in: 0..<10))
        }
        // Newcomers float in from any side, heading inward at a slant.
        let slant = CGFloat.random(in: -0.6...0.6)
        let start: CGPoint
        let v: CGVector
        switch Int.random(in: 0..<4) {
        case 0:  // left
            start = CGPoint(x: -s * 0.6, y: CGFloat.random(in: 140...maxY))
            v = CGVector(dx: speed + 12, dy: speed * slant)
        case 1:  // right
            start = CGPoint(x: area.width + s * 0.6, y: CGFloat.random(in: 140...maxY))
            v = CGVector(dx: -speed - 12, dy: speed * slant)
        case 2:  // top
            start = CGPoint(x: CGFloat.random(in: s / 2...maxX), y: -s * 0.6)
            v = CGVector(dx: speed * slant, dy: speed + 12)
        default: // bottom
            start = CGPoint(x: CGFloat.random(in: s / 2...maxX), y: area.height + s * 0.6)
            v = CGVector(dx: speed * slant, dy: -speed - 12)
        }
        return PlayBubble(palette: palette, size: s, start: start, velocity: v, born: .now, phase: Double.random(in: 0..<10))
    }

    /// Drifts in a straight line and bounces off the edges (a folded path), with a gentle bob. A newcomer glides
    /// in from off screen first, and only starts bouncing once it is fully inside.
    func position(at now: Date, in area: CGSize, still: Bool) -> CGPoint {
        let t: CGFloat = still ? 0 : CGFloat(now.timeIntervalSince(born))
        let r = size / 2
        let xLo = r, xHi = area.width - r
        let yLo = 110 + r, yHi = area.height - r
        let rawX = start.x + velocity.dx * t
        let rawY = start.y + velocity.dy * t
        let bob: CGFloat = still ? 0 : CGFloat(sin(Double(t) * 1.3 + phase)) * 4
        if t < entryTime(xLo, xHi, yLo, yHi) {
            return CGPoint(x: rawX, y: rawY + bob)
        }
        return CGPoint(x: Self.fold(rawX, xLo, xHi), y: Self.fold(rawY, yLo, yHi) + bob)
    }

    /// Seconds until the bubble is fully on screen on both axes (0 if it starts inside).
    private func entryTime(_ xLo: CGFloat, _ xHi: CGFloat, _ yLo: CGFloat, _ yHi: CGFloat) -> CGFloat {
        func axis(_ p: CGFloat, _ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
            if p < lo { return v > 0 ? (lo - p) / v : .infinity }
            if p > hi { return v < 0 ? (hi - p) / v : .infinity }
            return 0
        }
        return max(axis(start.x, velocity.dx, xLo, xHi), axis(start.y, velocity.dy, yLo, yHi))
    }

    static func fold(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        guard hi > lo else { return lo }
        let span = hi - lo
        var m = (v - lo).truncatingRemainder(dividingBy: 2 * span)
        if m < 0 { m += 2 * span }
        return lo + (m <= span ? m : 2 * span - m)
    }

    /// Springs into being when it arrives.
    func scale(at now: Date) -> CGFloat {
        let t = now.timeIntervalSince(born)
        guard t < 0.5 else { return 1 }
        let e = 1 - pow(1 - t / 0.5, 3)
        return CGFloat(0.6 + 0.4 * e)
    }
}

/// A theme's bubble, drawn for any palette (not only the chosen one), with its resting motion.
struct PlayBall: View {
    let palette: GumPalette

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Circle().fill(RadialGradient(colors: [palette.light, palette.base, palette.dark],
                                             center: UnitPoint(x: 0.38, y: 0.26), startRadius: 0, endRadius: w * 0.7))
                ThemeMarks(palette: palette, w: w, h: w)
                if palette == .fortune {
                    FortuneRim(lineWidth: max(2, w * 0.03))
                    FourPointStar().fill(Color.white.opacity(0.9))
                        .frame(width: w * 0.16, height: w * 0.16)
                        .offset(x: w * 0.08, y: -w * 0.14)
                }
                if palette == .unicorn {
                    UnicornSheen(phase: 0.5).clipShape(Circle())
                    Circle().strokeBorder(AngularGradient(colors: GumPalette.rainbow + [GumPalette.rainbow[0]], center: .center),
                                          lineWidth: max(2, w * 0.04))
                }
                BallLight(size: w, soft: palette == .fortune)
                ThemeTopper(palette: palette, w: w)
            }
            .frame(width: w, height: w)
        }
        .shadow(color: palette.accent.opacity(0.25), radius: 8, y: 4)
    }
}

struct PlayBurst: Identifiable {
    let id = UUID()
    let palette: GumPalette
    let center: CGPoint
    let size: CGFloat
}

/// The pieces a theme's pop throws: its own debris (emoji, sparks, sprinkles) or gum scraps in its colors.
struct PlayBurstView: View {
    let burst: PlayBurst
    @State private var out = false
    private static let n = 10

    var body: some View {
        ZStack {
            Circle().stroke(burst.palette.light, lineWidth: 3)
                .frame(width: burst.size, height: burst.size)
                .scaleEffect(out ? 1.5 : 0.9)
                .opacity(out ? 0 : 0.8)
            ForEach(0..<Self.n, id: \.self) { i in
                piece(i)
                    .rotationEffect(.degrees(out ? Double(i * 47 % 360) : 0))
                    .offset(offset(i))
                    .scaleEffect(out ? 0.7 : 1)
                    .opacity(out ? 0 : 1)
            }
        }
        .position(burst.center)
        .onAppear { withAnimation(.easeOut(duration: 0.9)) { out = true } }
    }

    private func offset(_ i: Int) -> CGSize {
        guard out else { return .zero }
        let a = Double(i) / Double(Self.n) * 2 * .pi + Double(i % 3) * 0.3
        let dist = burst.size * (0.7 + 0.25 * CGFloat(i % 4))
        return CGSize(width: CGFloat(cos(a)) * dist, height: CGFloat(sin(a)) * dist + burst.size * 0.35)
    }

    @ViewBuilder
    private func piece(_ i: Int) -> some View {
        let side = max(22, burst.size * 0.42)
        let p = burst.palette
        if ThemeDebris.handles(p) {
            ThemeDebris.piece(p, index: i, side: side)
        } else if p == .unicorn {
            if i % 4 == 0 {
                Text("🦄").font(.system(size: side * 0.7))
            } else {
                ConfettiPiece(index: i).frame(width: side * 0.45, height: side * 0.45)
            }
        } else if p == .fortune {
            if i % 3 == 0 {
                FourPointStar().fill(GumPalette.violetDeep).frame(width: side * 0.5, height: side * 0.5)
            } else {
                Circle().fill(GumPalette.violet.opacity(0.6)).frame(width: side * 0.6, height: side * 0.6).blur(radius: 4)
            }
        } else {
            Ellipse().fill([p.base, p.light, p.dark][i % 3]).frame(width: side * 0.5, height: side * 0.38)
        }
    }
}
