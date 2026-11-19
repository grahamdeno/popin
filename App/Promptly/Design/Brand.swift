import SwiftUI

enum Brand {
    /// Accent colors follow the bubble color (violet for Fortune).
    static var coral: Color { GumColors.accent }
    static var coralLight: Color { GumPalette.current.accentLight }
    static var coralDark: Color { GumPalette.current.accentDark }
    static let ink = Color(red: 0x14 / 255, green: 0x14 / 255, blue: 0x14 / 255)
    /// 8:1 on white; stays readable on the glass pane over the bubble.
    static let secondary = Color(red: 0x4A / 255, green: 0x4A / 255, blue: 0x4A / 255)
    /// Pink for small words on white (links, labels): the bubble pinks are too light to read at small sizes.
    static var accentText: Color { GumPalette.current.accentText }
    static let hairline = Color(red: 0xEF / 255, green: 0xEF / 255, blue: 0xEF / 255)

    static func display(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func color(hex: String) -> Color {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return .gray }
        return Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255,
                     blue: Double(v & 0xFF) / 255)
    }
}

/// How opaque the white plate is. Never below 0.90: ink, secondary and every accent text measure 4.5:1 on it over any
/// bubble color, the darkest theme art included (HomeLayoutTests).
extension Brand {
    static let plateOpacity: Double = 0.92
}

/// A white plate for any words the bubble can pass behind. Used by every card on Home and by `GlassCard`.
struct Plate: ViewModifier {
    var cornerRadius: CGFloat = 24
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(Brand.plateOpacity))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Brand.hairline, lineWidth: 1))
        )
    }
}

/// A card: keeps text readable when the bubble rises behind it. The white plate by default; glass only when the
/// debug switch in Settings, Diagnostics asks for it (Graham's phone check).
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        let padded = content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        if CardStyle.current == .glass {
            padded.glassEffect(.regular, in: .rect(cornerRadius: 24))
        } else {
            padded.plate(cornerRadius: 24)
        }
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
    /// The white plate behind words the bubble can pass behind.
    func plate(cornerRadius: CGFloat = 24) -> some View { modifier(Plate(cornerRadius: cornerRadius)) }
}

/// The lowercase wordmark with its coral dot.
struct Wordmark: View {
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text("pop in")
                .font(Brand.display(22))
                .tracking(-0.4)
                .foregroundStyle(Brand.ink)
            Circle().fill(Brand.coral).frame(width: 7, height: 7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pop In")
    }
}

/// Black pill, the main action.
struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = 50
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .frame(minHeight: height)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(Brand.ink))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Quiet pill, the second action.
struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = 50
    var fill = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .foregroundStyle(Brand.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .frame(minHeight: height)
            .frame(maxWidth: fill ? .infinity : nil)
            .background(Capsule().fill(Brand.ink.opacity(0.07)))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
