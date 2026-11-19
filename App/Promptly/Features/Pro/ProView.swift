import SwiftUI

/// The Pop In Pro sheet: what it adds, one price, buy or restore. No timers, no tricks.
struct ProView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 32

    private let features: [(String, String)] = [
        ("sparkles", "Unicorn mode: a rainbow bubble that bursts into confetti"),
        ("moon.stars", "Fortune: black glass, a violet glow and a meeting fortune"),
        ("circle.hexagongrid", "Gumball, Planet, Lava lamp, Disco and six more, each with its own pop"),
        ("calendar.badge.plus", "Every new theme through the year, included"),
        ("bell.and.waves.left.and.right", "Six more alarm sounds, including Tick-tock and Groove"),
        ("calendar.badge.clock", "Per calendar: always ring, link or not, or keep it quiet"),
        ("clock", "Ring up to 10 minutes early"),
        ("ipad.landscape", "Desk mode: keep the screen on while Pop In is open"),
    ]

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Story 8.2 (M4): a centred trio of theme balls, a centred title and one line, the features in two columns (one at
    /// accessibility sizes), and a bar fixed at the bottom on the plate with the App Store price, Unlock Pro and
    /// Restore purchase. Feature icons are hidden from VoiceOver; each feature reads as its words.
    var body: some View {
        let store = model.store
        ZStack {
            Color.white.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark").font(.body.weight(.semibold)).foregroundStyle(Brand.ink)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Close")
                    }
                    HStack(spacing: -18) {
                        ForEach([GumPalette.bubblegum, .waterBalloon, .fortune], id: \.self) { palette in
                            SwatchBall(palette: palette).frame(width: 64, height: 64)
                        }
                    }
                    .accessibilityHidden(true)
                    VStack(spacing: 8) {
                        Text(store.isPro ? "You have Pop In Pro" : "Pop In Pro")
                            .font(.system(size: titleSize, weight: .semibold))
                            .tracking(-0.8)
                            .foregroundStyle(Brand.ink)
                        Text(store.betaAccess && !store.purchased
                             ? "Unlocked for TestFlight testing. In the App Store version this is a one-time \(store.price) purchase."
                             : store.isPro ? "Thanks for supporting Pop In. Everything below is unlocked, and new themes arrive on their own. There's a tip jar at the bottom of Settings if you ever want to give more."
                                           : "One purchase, yours for good. The free app keeps every alarm, the bubble and the widgets.")
                            .font(.callout)
                            .foregroundStyle(Brand.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .multilineTextAlignment(.center)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
                                             count: typeSize.isAccessibilitySize ? 1 : 2),
                              alignment: .leading, spacing: 16) {
                        ForEach(features, id: \.1) { item in feature(icon: item.0, words: item.1) }
                    }
                    // Owners still see a result message (a restore that found nothing new, say) here.
                    if store.isPro, let message = store.message {
                        Text(message).font(.subheadline).foregroundStyle(Brand.ink)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !store.isPro { buyBar(store) }   // also shown in the TestFlight free preview
        }
        .task { await store.load() }
    }

    private func feature(icon: String, words: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.accentText)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Brand.coralLight.opacity(0.45)))
                .accessibilityHidden(true)
            Text(words)
                .font(.subheadline)
                .foregroundStyle(Brand.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// "$6.99 One time · no subscription", Unlock Pro and Restore purchase, fixed at the bottom on the plate.
    private func buyBar(_ store: ProStore) -> some View {
        VStack(spacing: 10) {
            // A failed buy or restore says so here, beside the buttons, not below the fold.
            if let message = store.message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Brand.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("\(Text(store.price).fontWeight(.semibold).foregroundStyle(Brand.ink))  \(Text("One time · no subscription").foregroundStyle(Brand.secondary))")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button(store.purchasing ? "One moment…" : store.betaAccess ? "Test the purchase (free in TestFlight)" : "Unlock Pro") {
                Task { await store.buy() }
            }
            .buttonStyle(PrimaryButtonStyle(height: 56))
            .disabled(store.purchasing)
            Button { Task { await store.restore() } } label: {
                Text("Restore purchase")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.accentText)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .plate(cornerRadius: 28)
        .padding(.horizontal, 12)
    }
}
