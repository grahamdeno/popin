import Foundation

/// A color as sRGB components, 0 to 1. The contrast rules below work on these, so they need no UIKit and are unit tested.
struct SRGB: Equatable, Sendable {
    var r: Double
    var g: Double
    var b: Double

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    /// From a hex value such as 0x141414.
    init(hex: UInt32) {
        self.init(r: Double((hex >> 16) & 0xFF) / 255, g: Double((hex >> 8) & 0xFF) / 255, b: Double(hex & 0xFF) / 255)
    }

    static let white = SRGB(r: 1, g: 1, b: 1)
    static let black = SRGB(r: 0, g: 0, b: 0)
}

/// WCAG 2 contrast: relative luminance and the ratio between two colors.
enum Contrast {
    /// The ratio words need (WCAG AA, normal size).
    static let minimumForWords = 4.5

    /// One channel, linearized.
    static func linear(_ c: Double) -> Double {
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    /// Relative luminance, 0 (black) to 1 (white).
    static func luminance(_ c: SRGB) -> Double {
        0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
    }

    /// The contrast ratio, 1 to 21. The order of the two colors doesn't matter.
    static func ratio(_ a: SRGB, _ b: SRGB) -> Double {
        let la = luminance(a)
        let lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// `top` drawn at `opacity` over `back`: the color a person sees where a plate sits over the bubble.
    static func over(_ top: SRGB, opacity: Double, on back: SRGB) -> SRGB {
        SRGB(r: top.r * opacity + back.r * (1 - opacity),
             g: top.g * opacity + back.g * (1 - opacity),
             b: top.b * opacity + back.b * (1 - opacity))
    }
}
