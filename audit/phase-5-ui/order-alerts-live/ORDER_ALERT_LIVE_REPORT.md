# Merchant new-order alerts — live report

**Fixture:** Dar El Bahja (`+213550000071`) on iPhone 16e.  
**Preserved:** Finjan / Customer / Driver sessions (Finjan simulator untouched).  
**Date:** 2026-09-25, foreground modes re-run 2026-09-28 after the Native Push changes  
**Status:** `implementer_reviewed` (pending visual acceptance)  
**Transport:** foreground poll every **8 seconds** (unchanged) plus the durable inbox. Native Push is a separate layer: see `../native-push/NATIVE_PUSH_REPORT.md`.

Layers are kept separate. Native Push delivery is **not** claimed from this evidence.

---

## Result matrix

| Layer | Check | Result | Evidence type |
| --- | --- | --- | --- |
| **Inbox (HTTP)** | Order create → `MERCHANT_ORDER_CREATED` for merchant members | **PASS** | **Executed**: `ORDER_ALERT_HTTP_EVIDENCE.json` (2026-09-25) |
| **Isolation (HTTP)** | Finjan inbox/GET must not return the Dar order | **PASS** | **Executed**: `ORDER_ALERT_ISOLATION_HTTP.json` (Finjan matchCount 0, GET 404) (2026-09-25) |
| **DeviceToken** | Scoped deactivate: peer token stays active; foreign delete is a no-op | **PASS** | **Executed + DB** (2026-09-25); reassignment after release: `../native-push/NATIVE_PUSH_BACKEND_DISABLED.json` |
| **Foreground** | Alert while foregrounded / tap opens / dedupe | **PASS** | **Executed**: reconnect pair (2026-09-28) |
| **Offline→reconnect** | Harness-injected offline gate → create online → recover one alert | **PASS** | **Executed** 2026-09-28: `ORDER_ALERT_GAP_PROVENANCE_reconnect.json` (not a native radio disconnect) |
| **Resume / stale** | Accepted order not shown as awaiting acceptance | **PASS** | **Executed** 2026-09-28: `ORDER_ALERT_GAP_PROVENANCE_resume_stale.json` |
| **Multi between polls** | Burst not silently lost | **PASS** | **Executed** 2026-09-28: `ORDER_ALERT_GAP_PROVENANCE_multi.json` |
| **Failure / offline** | No overlapping polls / no dialog spam | **PASS** | **Executed** (reconnect gate) + **code** `_tickInFlight` |
| **Logout / session** | Stop polling, clear queue, epoch blocks in-flight UI; token deactivated | **PASS** | **Code**: `OrderAlertController.stop()`; logout token deactivation **executed** in `../native-push/NATIVE_PUSH_SIM_HARNESS_PROVENANCE.json` |
| **Prefs UI** | "Alertes" title readable at 1.35; OS permission copy distinguishes *not yet authorized* from *refused*; hors-app unavailable copy; FG sound/vibration usable | **PASS** | **Executed** 2026-09-28: shots assert + `alert-preferences.png` / `-a11y` |
| **Inbox UI** | Full "Notifications" title; mark-all on own row; white check on selected filter; compact refs | **PASS** | **Executed** 2026-09-28: `alert-inbox.png` / `-a11y` |
| **Incoming UI** | Compact summary; sticky actions; matching opened-order ref | **PASS** | **Executed** 2026-09-28: `alert-incoming.png` + `alert-opened-order.png` both show compact ref `sgo_01a0e8…7eab6c` = reconnect order `01a0e8db-b7c5-7f8d-8091-f5fd0f2608e3` (step `reconnect_one_alert` in `ORDER_ALERT_GAP_PROVENANCE_reconnect.json`) |
| **Unit** | Parse / poll interval / stillIncoming | **PASS** | **Executed**: `test/features/order_alert_test.dart` |
| **Native Push** | APNs/FCM background / terminated delivery | **BLOCKED** (credentials) | See `../native-push/NATIVE_PUSH_REPORT.md` |
| **Commit / push** | — | **NOT DONE** | — |

---

## Screenshot provenance (2026-09-28 re-run)

| File | Scenario | Order ref |
| --- | --- | --- |
| `alert-incoming.png` | reconnect (harness offline gate) | `sgo_01a0e8…7eab6c` (`01a0e8db-…08e3`) |
| `alert-opened-order.png` | same reconnect, "Voir les détails" | **same order** |
| `alert-inbox.png` | shots @ 1.0 text | inbox list |
| `alert-preferences.png` | shots @ 1.0 text | prefs: "Alertes", permission not yet authorized, Push unavailable in this build |
| `alert-inbox-a11y.png` | shots @ **1.35** text | inbox |
| `alert-preferences-a11y.png` | shots @ **1.35** text | prefs |

Multi and resume-stale screenshots from the re-run went to a scratch folder so they could not overwrite the reconnect pair above.

Offline recovery uses **`ALERT_OFFLINE_GATE` file injection**, shared with the poller. It is not a simulator or native network disconnect.

---

## UI corrections

- Preferences:
  - Title shortened to "Alertes".
  - The OS banner distinguishes *not yet authorized* from *refused*. iOS `permission_handler` reports `denied` before the first prompt; only `permanentlyDenied` means refused.
  - Hors-application unavailable message when the build has no Push configuration.
  - Switch note replaces the red "cannot silence" warning.
- Inbox: mark-all on its own row; the selected filter uses a white label and checkmark on primary blue; compact public refs with a full-copy sheet.
- Incoming alert: content-sized summary card (scrollable), sticky bottom actions, compact secondary reference.
- Opening an order from an alert or a push drops any cached detail state, so an order handled elsewhere is shown with its fresh server status.

Review package: `order_alerts_review.zip`
