import XCTest
import SwiftUI
import UIKit
@testable import Promptly

/// Story 8.4: the "Pro" pill's word measures at least 4.5:1 on its own background, on every theme.
final class ProPillTests: XCTestCase {
    private func srgb(_ color: Color) -> SRGB {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        XCTAssertTrue(UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a), "could not read a color")
        return SRGB(r: Double(r), g: Double(g), b: Double(b))
    }

    func testPillWordPassesOnEveryTheme() {
        XCTAssertEqual(GumPalette.allCases.count, 46)
        for palette in GumPalette.allCases {
            let r = Contrast.ratio(srgb(ProPill.word), srgb(ProPill.fill(palette)))
            XCTAssertGreaterThanOrEqual(r, Contrast.minimumForWords, "\(palette.rawValue): the Pro pill is \(r):1")
        }
    }
}
