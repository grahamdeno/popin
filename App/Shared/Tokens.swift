import SwiftUI

/// GR-24: the colors the app and the widgets share, in one place. Brand (app) and the widgets read these.
enum Tokens {
    /// #141414: titles and body on white.
    static let ink = Color(red: 0x14 / 255, green: 0x14 / 255, blue: 0x14 / 255)
    /// #4A4A4A: second lines, 8:1 on white.
    static let secondary = Color(red: 0x4A / 255, green: 0x4A / 255, blue: 0x4A / 255)
}
