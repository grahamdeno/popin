#!/usr/bin/env python3
"""Fails CI if app code could change the calendar, reach the network, or save settings around demo mode.

Promptly reads the calendar and keeps everything on the iPhone. This guard keeps it that way:
no EventKit writes (calendar or reminders), no URLSession or other network clients, no analytics SDKs.
Settings are read and written only through Prefs.current or SettingsSuite, so demo mode saves nothing (item 11).
Usage: read_only_guard.py check | selftest
"""
import re
import sys
from pathlib import Path

FORBIDDEN = [
    (r"\.save\s*\(\s*\w*[Ee]vent", "EventKit save"),
    (r"\.remove\s*\(\s*\w*[Ee]vent", "EventKit remove"),
    (r"\bstore\.(save|remove|commit|reset)\b", "EventKit store write"),
    (r"\bEKEvent\s*\(\s*eventStore", "creating an event"),
    # Reminders are read (timed ones ring like meetings) but never created, completed or changed.
    (r"\.save\s*\(\s*\w*[Rr]eminder", "Reminders save"),
    (r"\.remove\s*\(\s*\w*[Rr]eminder", "Reminders remove"),
    (r"\bEKReminder\s*\(\s*eventStore", "creating a reminder"),
    (r"\.isCompleted\s*=(?!=)", "completing a reminder"),
    (r"\.completionDate\s*=(?!=)", "completing a reminder"),
    (r"\bURLSession\b", "network (URLSession)"),
    (r"\bNWConnection\b", "network (Network.framework)"),
    (r"\bURLRequest\b", "network request"),
    (r"import\s+(Firebase\w*|Mixpanel|Amplitude|Segment|Sentry)", "analytics or crash SDK"),
]


# Settings stores outside the demo-aware ones. Allowed only where listed (path relative to App/).
SETTINGS = [
    (r"UserDefaults\.standard", "UserDefaults.standard"),
    (r"UserDefaults\s*\(\s*suiteName", "a UserDefaults suite"),
    (r"\bPrefs\s*\(\s*\)", "Prefs() (use Prefs.current)"),
    (r"@AppStorage\s*\((?![^)]*store:)", "@AppStorage without a store"),
    (r"\bUserDefaults\s*\(\s*\)", "UserDefaults()"),
    (r"\?\?\s*\.standard\b", "a fallback to UserDefaults.standard"),
]
SETTINGS_ALLOWED = {
    ("Shared/SettingsSuite.swift", "a UserDefaults suite"),
    ("Model/Prefs.swift", "a UserDefaults suite"),
    ("Model/Prefs.swift", "Prefs() (use Prefs.current)"),
    ("Model/Prefs.swift", "UserDefaults()"),
    ("Model/Prefs.swift", "a fallback to UserDefaults.standard"),
    # Saved alarm IDs; demo mode never syncs alarms and cancelOwned returns early in demo mode.
    ("Services/AlarmService.swift", "UserDefaults.standard"),
    # The widget's snapshot; AppModel never writes it in demo mode.
    ("Shared/WidgetSnapshot.swift", "a UserDefaults suite"),
    # 1.0 kept the playground's best score in standard defaults; demo mode uses the throwaway store.
    ("Play/PopPlayground.swift", "UserDefaults.standard"),
}


def scan_settings(text: str, rel: str):
    hits = []
    for pattern, why in SETTINGS:
        if any(rel.endswith(f) and why == w for f, w in SETTINGS_ALLOWED):
            continue
        for m in re.finditer(pattern, text):
            line = text.count("\n", 0, m.start()) + 1
            hits.append((line, why))
    return hits


def scan(text: str):
    hits = []
    for pattern, why in FORBIDDEN:
        for m in re.finditer(pattern, text):
            line = text.count("\n", 0, m.start()) + 1
            hits.append((line, why))
    return hits


def check(root: Path) -> int:
    failures = 0
    for path in sorted(p for d in ("Promptly", "Shared", "PromptlyWidgets") for p in (root / "App" / d).rglob("*.swift")):
        text = path.read_text(encoding="utf-8")
        for line, why in scan(text):
            print(f"::error file={path},line={line}::{why} is not allowed in Promptly")
            failures += 1
        if "PromptlyWidgets" not in path.parts:
            rel = path.relative_to(root / "App").as_posix()
            for line, why in scan_settings(text, rel):
                print(f"::error file={path},line={line}::{why}: read and write settings through Prefs.current (item 11)")
                failures += 1
    if failures == 0:
        print("Read-only guard: no calendar writes, network use or settings outside Prefs.current found.")
    return 1 if failures else 0


def selftest() -> int:
    assert scan("try store.save(event, span: .thisEvent)")
    assert scan("let s = URLSession.shared")
    assert scan("store.remove(ev, span: .thisEvent)")
    assert scan("import FirebaseAnalytics")
    assert scan("try store.save(reminder, commit: true)")
    assert scan("let r = EKReminder(eventStore: store)")
    assert scan("reminder.isCompleted = true")
    assert not scan("if reminder.isCompleted == false {}")
    assert not scan("store.fetchReminders(matching: predicate) { _ in }")
    assert not scan("let events = store.events(matching: predicate)")
    assert not scan("prefs.clearedMeetingIDs = cleared")
    assert scan_settings("let d = UserDefaults.standard", "Promptly/Features/Home/HomeView.swift")
    assert scan_settings('let d = UserDefaults(suiteName: "x")', "Promptly/App/AppModel.swift")
    assert scan_settings("let p = Prefs()", "Promptly/Design/HapticRamp.swift")
    assert scan_settings('@AppStorage("k") private var k = 0', "Promptly/Features/Home/HomeView.swift")
    assert not scan_settings('@AppStorage("k", store: Prefs.current.defaults) private var k = 0', "Promptly/Features/Home/HomeView.swift")
    assert not scan_settings("let p = Prefs.current", "Promptly/App/AppModel.swift")
    assert scan_settings("let d = UserDefaults()", "Promptly/Services/ProStore.swift")
    assert scan_settings('let d = UserDefaults(suiteName: "x") ?? .standard', "Promptly/Services/ProStore.swift")
    assert scan_settings("let d = Prefs.current.defaults ?? .standard", "Promptly/Services/ProStore.swift")
    assert not scan_settings('UserDefaults(suiteName: name)', "Shared/SettingsSuite.swift")
    print("Read-only guard self-test passed.")
    return 0


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "check"
    sys.exit(selftest() if cmd == "selftest" else check(Path(__file__).resolve().parent.parent))
