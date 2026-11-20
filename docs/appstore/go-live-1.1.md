# Go-live assessment: Pop In 1.1 at cdd049a

Assessed 2026-11-20 by the reviewer helper in the Pop In Product chat (Fable's role; see the note at the end), against
playbook standards/go-live.md. Gathered by Opus.

## Verdict

**Ready after the open items.** The app at cdd049a is the second 1.1 test build, which Graham passed on his phone
(2026-11-20). No purchase, price, permission, data collection or storefront changes. Open before Submit: a green test
run on cdd049a, a decision on the Plate/Glass card switch, Graham's ship go, and Grok's store steps below.

## Checklist (1.1 changes only; everything else as 1.0)

| Item | State | Evidence or who closes it |
|---|---|---|
| Purchases, prices, Product IDs | Unchanged | No change in 1.1 |
| Permissions and purpose strings | Unchanged | Calendar, Reminders, alarms as 1.0 |
| App Privacy answers | Unchanged: Data Not Collected | Read-only guard in CI; no network, analytics or SDKs |
| Stored data | Additive only | New keys clashDroppedIDs, poppedMeetingIDs, snoozeRings, dismissedMeetingIDs, repeatAlarmIDs; older data lacks them |
| Compiled-in dates | Unchanged | GumPalette.releaseDays identical to 1.0 (next: 2026-11-30) |
| Version | 1.1 | project.yml at cdd049a |
| Tests and guard on cdd049a | **Open** | build.yml re-run on cdd049a (run 44704005583); result recorded here when done |
| UX audit | Passed for the app | Walk on 518d89e (same app code as build 1); #100 and #101 reviewed after; walk-only items in #96 and #99 |
| Plate/Glass card switch (7.1) | **Open: Graham** | Still reachable in Diagnostics (five taps on the version). Remove (third build) or waive in writing |
| Phone checks | Passed (Graham) | Graham: nothing in 1.1 needs correction (2026-11-20). The 15-minute repeat and Lock Screen Dismiss were in his checks |
| What's New, description, review notes | Ready | docs/app-store-listing.md "1.1 draft" (#94); Grok enters them |
| Screenshots | **Open: Grok** | Retake from the shipping commit; captions five words or fewer (caption 1, "Lose track of time, not calls", matches the subtitle and stays) |
| Accessibility labels | **Open: Grok** | Larger Text, Reduce Motion, Sufficient Contrast. VoiceOver only after a hands-on pass |
| Manual release | **Open: Grok** | Select manual release so approval doesn't release on its own |
| Crash reports | **Open: Grok** | Check both test builds |
| Submit for Review | **Open** | One-time exception: Grok presses it after reading it back to Graham and getting his yes |
| Release | Graham | Not delegated |
| Site (#87) | At Release | Merge when 1.1 goes live; deploys at once. Refresh pictures first (scripts/site_shots.py) |

## Note on the assessor

This verdict came from a reviewer started inside the Product chat, not the standing Pop In Review chat. Graham can ask
the Review chat (Fable) to confirm it.
