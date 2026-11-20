import SwiftUI
import UIKit

enum Brand {
    /// Accent colors follow the bubble color (violet for Fortune).
    static var coral: Color { GumColors.accent }
    static var coralLight: Color { GumPalette.current.accentLight }
    static var coralDark: Color { GumPalette.current.accentDark }
    static let ink = Tokens.ink
    /// 8:1 on white; stays readable on the glass pane over the bubble.
    static let secondary = Tokens.secondary
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

/// A card: keeps text readable when the bubble rises behind it. Always the white plate (7.1; the glass option was
/// removed before 1.1 shipped).
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .plate(cornerRadius: 24)
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

/// How a pressed button looks (story 8.6): slightly smaller and dimmer. With Reduce Motion it only dims.
enum PressedLook {
    static func scale(pressed: Bool, reduceMotion: Bool) -> CGFloat { pressed && !reduceMotion ? 0.97 : 1 }
    static func opacity(pressed: Bool) -> Double { pressed ? 0.9 : 1 }
}

/// Applies the pressed look. A view (not the ButtonStyle) reads Reduce Motion, so it always gets the live value.
private struct PressedLookView<Content: View>: View {
    let isPressed: Bool
    let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .scaleEffect(PressedLook.scale(pressed: isPressed, reduceMotion: reduceMotion))
            .opacity(PressedLook.opacity(pressed: isPressed))
            .animation(.snappy(duration: 0.2), value: isPressed)
    }
}

extension View {
    /// The pressed look for button styles (story 8.6).
    func pressedLook(_ isPressed: Bool) -> some View { PressedLookView(isPressed: isPressed, content: self) }
}

/// Taps you can feel (story 8.6). They follow the iPhone's own System Haptics setting; the alarm's buzz is separate.
enum Feedback {
    @MainActor static func undo() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    @MainActor static func pick() { UISelectionFeedbackGenerator().selectionChanged() }
    @MainActor static func unlocked() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
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
            .pressedLook(configuration.isPressed)
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
            .background(Capsule().fill(Brand.ink.opacity(0.06)))
            .pressedLook(configuration.isPressed)
    }
}
