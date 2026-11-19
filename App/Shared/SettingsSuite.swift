import Foundation

/// Where Pop In keeps its settings: the App Group suite, or in demo mode (screenshots and the audit walk, launched
/// with `-screenshots`) a separate throwaway suite, so a demo never reads or changes the owner's settings (item 11).
/// Shared with the widget extension, which never runs in demo mode.
enum SettingsSuite {
    static let real = "group.com.grahamdeno.promptly"
    static let demo = "com.grahamdeno.promptly.demo"
    static let isDemo = ProcessInfo.processInfo.arguments.contains("-screenshots")
    static var name: String { isDemo ? demo : real }
    static var defaults: UserDefaults? { UserDefaults(suiteName: name) }
}
