import SwiftUI

/// Settings › Theme: every bubble theme, grouped (Classic, Pro favorites, Sports and games, Treats, Nature and space,
/// Fun objects, Seasons and holidays). Tapping a tile picks it and plays that theme's pop, and Settings stays open so
/// other pops can be tried (owner, 2026-11-14); the pick lands when Settings closes or on "See it on Home". Pro themes
/// open Pop In Pro for free users. "Surprise me" picks a different theme each day.
struct ThemeGalleryPage: View {
    @Environment(AppModel.self) private var model
    @State private var bounced: GumPalette?
    @State private var offer: GumPalette?

    var body: some View {
        SettingsPage {
            if GumPalette.previewUpcoming {
                Text("Testing: showing upcoming themes too. Press and hold Pop In Pro to hide them, or relaunch.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.accentText)
                    .padding(.horizontal, 18)
            }
            iconGroup
            SettingsGroup(nil, note: "A different theme each day, picked from the ones you have.") {
                SettingsToggle(model.store.isPro || !model.store.ownedPacks.isEmpty ? "Surprise me" : "Surprise me ✦", detail: "Changes once a day when you open Pop In",
                               isOn: Binding(get: { model.surprise }, set: { on in
                                   if on && !model.store.isPro && model.store.ownedPacks.isEmpty { model.showPro = true } else { model.surprise = on }
                               }))
            }
            ForEach(ThemeGroup.allCases, id: \.self) { group in
                let themes = GumPalette.available.filter { $0.group == group }
                if !themes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(group.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Brand.secondary)
                                .accessibilityAddTraits(.isHeader)
                            Spacer()
                            // Packs: buy one group without all of Pro.
                            if group.packID != nil && !model.store.owns(group) {
                                Button("Get the pack · \(model.store.packPrice(group))") {
                                    Task { await model.store.buy(pack: group) }
                                }
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Brand.accentText)
                                .frame(minHeight: 44)
                            }
                        }
                        .padding(.horizontal, 18)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(themes, id: \.self) { tile($0) }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 20).fill(.white))
                    }
                }
            }
        }
        .confirmationDialog(offer.map { "Try \($0.label)" } ?? "", isPresented: Binding(get: { offer != nil }, set: { if !$0 { offer = nil } }),
                            titleVisibility: .visible, presenting: offer) { palette in
            Button("Try it for today") { model.tryTheme(palette, apply: false); PopSound.play(file: palette.popFile) }
            Button("Get Pop In Pro") { model.showPro = true }
        } message: { _ in
            Text("Use it for the rest of today, free. Each theme can be tried once. Pro keeps every theme, now and later.")
        }
        .navigationTitle("Theme")
        .safeAreaInset(edge: .bottom) {
            if let message = model.store.message {
                Text(message).font(.footnote).foregroundStyle(Brand.ink).padding(12)
                    .glassEffect(.regular, in: .capsule).padding(.bottom, 8)
            } else if let picked = model.pendingTheme {
                // The pick waits until Settings closes; this says so and offers the quick way home.
                HStack(spacing: 12) {
                    Text("\(picked.label) picked. Tap others to hear them.")
                        .font(.footnote).foregroundStyle(Brand.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Button("See it on Home") {
                        model.applyPendingTheme()
                        model.closeSettings = true
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).frame(minHeight: 44)
                    .background(Capsule().fill(Brand.ink))
                }
                .padding(.leading, 16).padding(.trailing, 6).padding(.vertical, 4)
                .glassEffect(.regular, in: .capsule)
                .padding(.horizontal, 12).padding(.bottom, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    /// App icon: what the Home Screen shows now, and a button to match the theme if it doesn't (or iOS said no).
    private var iconGroup: some View {
        let showing = AppModel.theme(forIcon: model.currentIcon)
        let wanted = AppModel.theme(forIcon: model.wantedIcon)
        let matches = model.currentIcon == model.wantedIcon
        let note: String = model.iconError.map { "iOS didn't change the icon: \($0)" }
            ?? (model.surprise ? "Surprise me keeps the icon as it is, so iOS doesn't ask every morning." : "The icon follows your theme. iOS shows a short notice each time it changes.")
        return SettingsGroup("App icon", note: note) {
            HStack(spacing: 12) {
                Text("Home Screen").font(.body).foregroundStyle(Brand.ink)
                Spacer()
                Text(showing.label).font(.body).foregroundStyle(Brand.secondary)
            }
            .frame(minHeight: 44)
            .padding(.horizontal, 18)
            if !matches && !model.surprise {
                Button("Use the \(wanted.label) icon") { model.setIconNow() }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.accentText)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.horizontal, 18)
            }
        }
        .onAppear { model.currentIcon = UIApplication.shared.alternateIconName }
    }

    private func tile(_ palette: GumPalette) -> some View {
        let selected = model.pendingTheme.map { $0 == palette } ?? (model.gumColor == palette && !model.surprise)
        let locked = !model.canUse(palette)
        return Button {
            if locked {
                if model.canTry(palette) { offer = palette } else { model.showPro = true }
                return
            }
            model.pendingTheme = (palette == model.gumColor && !model.surprise) ? nil : palette
            Feedback.pick()
            PopSound.play(file: palette.popFile)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) { bounced = palette }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { if bounced == palette { bounced = nil } }
            }
        } label: {
            VStack(spacing: 8) {
                SwatchBall(palette: palette)
                    .frame(width: 52, height: 52)
                    .scaleEffect(bounced == palette ? 1.18 : 1)
                    .padding(.top, 10)
                Text(locked ? "\(palette.label) ✦" : palette.label)
                    .font(.footnote.weight(selected ? .semibold : .regular))
                    .foregroundStyle(Brand.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .top)
            .background(RoundedRectangle(cornerRadius: 14).stroke(selected ? Brand.ink : Brand.hairline, lineWidth: selected ? 2 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(locked ? "\(palette.label), Pro" : palette.label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
