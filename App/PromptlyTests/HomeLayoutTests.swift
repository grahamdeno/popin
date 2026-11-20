import SwiftUI
import UIKit
import XCTest
@testable import Promptly

/// Epic 7, item 7.1 (docs/roadmap.md): the contrast and card rules behind the new Home layout. Layout itself (header,
/// scrolling, countdown size) is checked by the walk in Journeys.swift.
final class HomeLayoutTests: XCTestCase {
    /// A SwiftUI color as sRGB components, read the way the roadmap says: `UIColor(color).getRed(...)`.
    private func srgb(_ color: Color) -> SRGB {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        XCTAssertTrue(UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a), "could not read a color")
        return SRGB(r: Double(r), g: Double(g), b: Double(b))
    }

    private let ink = SRGB(hex: 0x141414)
    private let secondary = SRGB(hex: 0x4A4A4A)

    // MARK: The contrast helper

    func testContrastHelperKnownValues() {
        XCTAssertEqual(Contrast.ratio(.black, .white), 21, accuracy: 0.001)
        XCTAssertEqual(Contrast.ratio(.white, .white), 1, accuracy: 0.001)
        // #767676 on white is the classic 4.54:1 (just over AA).
        XCTAssertEqual(Contrast.ratio(SRGB(hex: 0x767676), .white), 4.54, accuracy: 0.01)
        // The order of the two colors doesn't matter.
        XCTAssertEqual(Contrast.ratio(.white, SRGB(hex: 0x767676)), Contrast.ratio(SRGB(hex: 0x767676), .white), accuracy: 0.0001)
        // 90% white over black is 229.5 of 255 on every channel.
        let plate = Contrast.over(.white, opacity: 0.9, on: .black)
        XCTAssertEqual(plate.r, 0.9, accuracy: 0.0001)
    }

    // MARK: Plate contrast, every theme

    func testPlateOpacityIsAtLeastNinetyPercent() {
        XCTAssertGreaterThanOrEqual(Brand.plateOpacity, 0.90)
    }

    /// Given any theme and any bubble size, words that can have the bubble behind them use ink, secondary or the
    /// theme's accent text on the plate. For every theme, each measures 4.5:1 on 90% white over the theme's light,
    /// base and dark colors and over black.
    func testPlateContrastEveryTheme() {
        for palette in GumPalette.allCases {
            let backs = [("light", srgb(palette.light)), ("base", srgb(palette.base)), ("dark", srgb(palette.dark)), ("black", SRGB.black)]
            let words = [("ink", ink), ("secondary", secondary), ("accent text", srgb(palette.accentText))]
            for (backName, back) in backs {
                let plate = Contrast.over(.white, opacity: 0.90, on: back)
                for (wordName, word) in words {
                    let r = Contrast.ratio(word, plate)
                    XCTAssertGreaterThanOrEqual(r, Contrast.minimumForWords,
                                                "\(palette.rawValue): \(wordName) on the plate over \(backName) is \(r):1")
                }
            }
        }
    }

    /// Given any theme, its accent text measures at least 4.5:1 on white.
    func testAccentTextOnWhiteEveryTheme() {
        XCTAssertEqual(GumPalette.allCases.count, 46)
        for palette in GumPalette.allCases {
            let r = Contrast.ratio(srgb(palette.accentText), .white)
            XCTAssertGreaterThanOrEqual(r, Contrast.minimumForWords, "\(palette.rawValue) accent text on white is \(r):1")
        }
    }

    /// The ten accent text values the roadmap lists are the ones in the code.
    func testTenAccentTextValues() {
        let expected: [GumPalette: UInt32] = [
            .fishbowl: 0x0B6D97, .gumball: 0x1E6B97, .orange: 0xA14E0F, .macaron: 0xA3446C, .sun: 0x9B5309,
            .dandelion: 0x546D34, .marble: 0x1E6B97, .duck: 0x816004, .easterEgg: 0x3A689E, .beachBall: 0xB83729,
        ]
        for (palette, hex) in expected {
            let got = srgb(palette.accentText)
            let want = SRGB(hex: hex)
            XCTAssertEqual(got.r, want.r, accuracy: 0.003, "\(palette.rawValue) red")
            XCTAssertEqual(got.g, want.g, accuracy: 0.003, "\(palette.rawValue) green")
            XCTAssertEqual(got.b, want.b, accuracy: 0.003, "\(palette.rawValue) blue")
        }
    }

    // MARK: No words on the gum

    /// Given any text size, no words are drawn on the gum, except Fortune's fortune. BubbleView.swift may draw only
    /// two kinds of `Text`: the fortune's words and the unicorn sprinkle emoji (decoration, hidden from VoiceOver).
    func testBubbleDrawsNoTextExceptFortuneWords() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Promptly/Design/BubbleView.swift")
        let source = try String(contentsOf: url, encoding: .utf8)
        let allowed = ["Text(text)", "Text(\"🦄\")"]
        var found: [String] = []
        var rest = source[...]
        while let r = rest.range(of: "Text(") {
            // Skip names that end in "Text(" such as "fortuneText(".
            let before = rest[..<r.lowerBound].last
            let isCall = before.map { !($0.isLetter || $0.isNumber || $0 == "_" || $0 == ".") } ?? true
            if isCall {
                let tail = rest[r.lowerBound...]
                if let close = tail.firstIndex(of: ")") { found.append(String(tail[..<tail.index(after: close)])) }
            }
            rest = rest[r.upperBound...]
        }
        XCTAssertFalse(found.isEmpty, "the scan found no Text at all, so it is not reading BubbleView.swift")
        for text in found {
            XCTAssertTrue(allowed.contains(text), "BubbleView draws words on the gum: \(text)")
        }
    }

}
