import Observation
import StoreKit

/// Pop In Pro: a one-time, non-consumable unlock bought through the App Store (StoreKit 2). Nothing about the
/// purchase passes through Pop In: Apple handles payment, receipts and restore.
@MainActor
@Observable
final class ProStore {
    static let productID = "com.grahamdeno.promptly.pro"
    /// Theme packs: each unlocks one group of themes (Pro unlocks everything, packs included).
    static let packIDs: [String] = ThemeGroup.allCases.compactMap(\.packID)
    /// Tip jar: consumable tips, shown only to Pro owners. Tips unlock nothing.
    static let tipIDs = ["com.grahamdeno.promptly.tip.small", "com.grahamdeno.promptly.tip.medium", "com.grahamdeno.promptly.tip.large"]
    static let tipFallbackPrices = ["$1.99", "$4.99", "$9.99"]

    /// True when Pro is unlocked: bought, or a TestFlight / development build (beta access).
    var isPro: Bool { (purchased && !previewFree) || betaAccess }
    /// TestFlight only: show the free version even though Pro was bought with the free test purchase, so the locked
    /// app, the Pro sheet and the hidden tip jar can be checked again. Never on in the App Store; not saved.
    var previewFree = false
    /// True for TestFlight and App Review installs (Apple's sandbox), where the preview switch is offered.
    private(set) var isSandbox = false
    /// Bought through the App Store.
    private(set) var purchased: Bool
    /// Xcode (debug) builds and screenshot mode only. TestFlight and App Review now see the real locked app and buy
    /// Pro through Apple's sandbox, which is free, so the purchase itself is what gets tested (owner, 2026-11-14).
    private(set) var betaAccess: Bool
    private(set) var product: Product?
    /// Theme packs the buyer owns (product IDs).
    private(set) var ownedPacks: Set<String>
    private(set) var packProducts: [String: Product] = [:]
    private(set) var tipProducts: [String: Product] = [:]
    /// Set for a moment after a tip goes through, so Settings can say thank you.
    var thanked = false
    private(set) var purchasing = false
    var message: String?

    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored private let defaults = Prefs.current.defaults
    /// Called when Pro turns off (for example after a refund), so Pro-only choices fall back to free ones.
    @ObservationIgnored var onLost: (() -> Void)?

    init() {
        purchased = defaults.bool(forKey: "isPro")
        ownedPacks = Set(defaults.stringArray(forKey: "ownedPacks") ?? [])
        betaAccess = Self.receiptLooksLikeBeta
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlement()
                }
            }
        }
    }

    /// True when a theme can be used: free, Pro, or its pack is owned.
    func unlocks(_ palette: GumPalette) -> Bool {
        if !palette.isPro || isPro { return true }
        guard let pack = palette.group.packID else { return false }
        return ownedPacks.contains(pack)
    }

    func owns(_ group: ThemeGroup) -> Bool {
        isPro || group.packID.map { ownedPacks.contains($0) } ?? false
    }

    func packPrice(_ group: ThemeGroup) -> String {
        group.packID.flatMap { packProducts[$0]?.displayPrice } ?? "$1.99"
    }

    /// The displayed price, from the App Store, in the buyer's currency.
    var price: String { product?.displayPrice ?? "$6.99" }

    /// Debug builds start unlocked; TestFlight, App Review and the App Store start locked.
    private static var receiptLooksLikeBeta: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// Ask the App Store how this copy was installed. TestFlight reports the sandbox environment.
    func checkBetaAccess() async {
        if let demoAccess { betaAccess = demoAccess; return }
        #if DEBUG
        betaAccess = true
        #else
        betaAccess = false
        if case .verified(let app) = try? await AppTransaction.shared { isSandbox = app.environment == .sandbox }
        #endif
    }

    /// Screenshot and audit mode only: show every Pro feature (true) or the App Store version (false), without StoreKit.
    func setDemoAccess(_ on: Bool) {
        demoAccess = on
        betaAccess = on
    }
    /// Set only in screenshot and audit mode; then nothing else changes beta access (the Pro sheet's own load included).
    @ObservationIgnored private var demoAccess: Bool?

    func load() async {
        await checkBetaAccess()
        if product == nil || tipProducts.isEmpty {
            let all = (try? await Product.products(for: [Self.productID] + Self.packIDs + Self.tipIDs)) ?? []
            product = all.first { $0.id == Self.productID }
            packProducts = Dictionary(uniqueKeysWithValues: all.filter { Self.packIDs.contains($0.id) }.map { ($0.id, $0) })
            tipProducts = Dictionary(uniqueKeysWithValues: all.filter { Self.tipIDs.contains($0.id) }.map { ($0.id, $0) })
        }
        await refreshEntitlement()
    }

    func refreshEntitlement() async {
        var owned = false
        var packs: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result, t.revocationDate == nil else { continue }
            if t.productID == Self.productID { owned = true }
            if Self.packIDs.contains(t.productID) { packs.insert(t.productID) }
        }
        let lostPack = !ownedPacks.subtracting(packs).isEmpty && !betaAccess
        ownedPacks = packs
        defaults.set(Array(packs), forKey: "ownedPacks")
        setPro(owned)
        if lostPack { onLost?() }
        // Testers whose old builds unlocked Pro for free: drop Pro-only choices they never bought (no-op otherwise).
        else if !isPro && demoAccess == nil { onLost?() }
    }

    func tipPrice(_ i: Int) -> String {
        tipProducts[Self.tipIDs[i]]?.displayPrice ?? Self.tipFallbackPrices[i]
    }

    /// Leaves a tip. Consumable: it can be given again any time and unlocks nothing.
    func tip(_ i: Int) async {
        let id = Self.tipIDs[i]
        if tipProducts[id] == nil { await load() }
        guard let product = tipProducts[id] else {
            message = "Tips aren't available yet. Try again later."
            return
        }
        purchasing = true
        defer { purchasing = false }
        do {
            if case .success(let result) = try await product.purchase(), case .verified(let t) = result {
                await t.finish()
                message = nil
                thanked = true
            }
        } catch {
            message = "The tip didn't go through: \(error.localizedDescription)"
        }
    }

    /// Buys one theme pack.
    func buy(pack group: ThemeGroup) async {
        guard let id = group.packID else { return }
        if packProducts[id] == nil { await load() }
        guard let product = packProducts[id] else {
            message = "The App Store isn't reachable right now. Try again in a moment."
            return
        }
        purchasing = true
        defer { purchasing = false }
        do {
            if case .success(let result) = try await product.purchase(), case .verified(let t) = result {
                await t.finish()
                ownedPacks.insert(id)
                defaults.set(Array(ownedPacks), forKey: "ownedPacks")
                message = nil
            }
        } catch {
            message = "Purchase didn't go through: \(error.localizedDescription)"
        }
    }

    func buy() async {
        if product == nil { await load() }
        guard let product else {
            message = "The App Store isn't reachable right now. Try again in a moment."
            return
        }
        purchasing = true
        defer { purchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                if case .verified(let t) = result {
                    await t.finish()
                    previewFree = false
                    setPro(true)
                    message = nil
                } else {
                    message = "Apple couldn't confirm the purchase."
                }
            case .pending:
                message = "Waiting for approval. Pro unlocks as soon as it's approved."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "Purchase didn't go through: \(error.localizedDescription)"
        }
    }

    func restore() async {
        previewFree = false
        try? await AppStore.sync()
        await refreshEntitlement()
        message = purchased ? "Pro restored." : (ownedPacks.isEmpty ? "No purchases found for this Apple Account." : "Your theme packs are restored.")
    }

    private func setPro(_ value: Bool) {
        let lost = purchased && !value && !betaAccess
        purchased = value
        defaults.set(value, forKey: "isPro")
        if lost { onLost?() }
    }
}
