import Foundation

/// Pop for fun's rules (owner, 2026-11-14), kept apart from the view so they can be unit tested.
///
/// Three ways to play:
/// - `free`: the original toy. Pop anything; the count goes up.
/// - `target`: a 30-second round. One theme is the target and changes every 5 seconds; only it scores.
///   Popping anything else breaks the combo and costs a point. Personal best is kept on the device.
/// - `waitingRoom`: pop until the next meeting. Bubbles come faster as it nears; in the last seconds the meeting's
///   own bubble appears (or Pop In's alarm takes over), and popping it joins.
///
/// Everywhere: a golden bubble now and then is worth 5, and quick pops in a row build a combo worth an extra point each.
struct PopGame {
    enum Mode: Equatable, Sendable { case free, target, waitingRoom }

    static let roundLength: TimeInterval = 30
    static let targetSwap: TimeInterval = 5
    static let comboWindow: TimeInterval = 0.9
    static let comboFrom = 3
    static let goldenPoints = 5
    static let goldenChance = 0.06
    /// Waiting room: the meeting's bubble takes over for the last 10 seconds.
    static let finaleLead: TimeInterval = 10
    /// Waiting room is offered for a meeting starting within 15 minutes.
    static let waitingRoomReach: TimeInterval = 15 * 60

    let mode: Mode
    let started: Date
    private(set) var score = 0
    private(set) var combo = 0
    private(set) var lastPop: Date?

    init(mode: Mode, started: Date) {
        self.mode = mode
        self.started = started
    }

    /// Scores one pop and returns the points it earned (negative for a wrong pop in a target round).
    @discardableResult
    mutating func pop(isTarget: Bool, golden: Bool, at now: Date) -> Int {
        if golden {
            bump(now)
            score += Self.goldenPoints
            return Self.goldenPoints
        }
        if mode == .target && !isTarget {
            combo = 0
            lastPop = nil
            let lost = score > 0 ? 1 : 0
            score -= lost
            return -lost
        }
        bump(now)
        let points = 1 + (combo >= Self.comboFrom ? 1 : 0)
        score += points
        return points
    }

    private mutating func bump(_ now: Date) {
        if let last = lastPop, now.timeIntervalSince(last) <= Self.comboWindow { combo += 1 } else { combo = 1 }
        lastPop = now
    }

    /// Seconds left in a target round.
    func remaining(at now: Date) -> TimeInterval { max(0, Self.roundLength - now.timeIntervalSince(started)) }
    func isOver(at now: Date) -> Bool { mode == .target && remaining(at: now) <= 0 }

    /// Which target slot a moment falls in; a new slot means a new target.
    func targetSlot(at now: Date) -> Int { Int(max(0, now.timeIntervalSince(started)) / Self.targetSwap) }

    /// Waiting room pace: 1 when the meeting is 5 or more minutes away, rising to 1.8 in the last minute.
    static func pace(secondsLeft: TimeInterval) -> Double {
        let x = min(1, max(0, (300 - secondsLeft) / 240))
        return 1 + 0.8 * x
    }

    /// The waiting room's final stretch, when only the meeting's bubble is on screen.
    static func isFinale(secondsLeft: TimeInterval) -> Bool { secondsLeft <= finaleLead }

    /// Picks the next target from the round's themes, never the same one twice in a row.
    static func nextTarget(from pool: [GumPalette], after current: GumPalette?, roll: Int) -> GumPalette? {
        let choices = pool.filter { $0 != current }
        guard !choices.isEmpty else { return pool.first }
        return choices[abs(roll) % choices.count]
    }
}
