import AlarmKit
import AppIntents
import Foundation

/// Runs when a meeting alarm's Dismiss is used on the Lock Screen (story 1.2): that meeting gets no more repeats.
/// The meeting itself stays on Home; this isn't Not going.
struct DismissMeetingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Dismiss meeting alarm"
    static var description = IntentDescription("Stops a meeting's alarm and its repeats.")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false

    @Parameter(title: "Meeting")
    var meetingID: String

    @Parameter(title: "Alarm")
    var alarmID: String

    init() {}

    init(meetingID: String, alarmID: String) {
        self.meetingID = meetingID
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) { try? AlarmManager.shared.stop(id: id) }
        let prefs = Prefs.current
        prefs.dismissedMeetingIDs.insert(meetingID)
        var map = prefs.repeatAlarmIDs
        for raw in map[meetingID] ?? [] {
            if let id = UUID(uuidString: raw), id.uuidString != alarmID { try? AlarmManager.shared.cancel(id: id) }
        }
        map[meetingID] = nil
        prefs.repeatAlarmIDs = map
        return .result()
    }
}
