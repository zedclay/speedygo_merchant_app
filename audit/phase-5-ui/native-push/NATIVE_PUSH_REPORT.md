# Native Push — Merchant new orders — report

**Date:** 2026-09-28  
**Status:** `implementer_reviewed`. Not committed, not pushed, not deployed.  
**Scope:** `MERCHANT_ORDER_CREATED` only. Backend (`apps/backend`) + Merchant app (`apps/merchant_app`). No Customer or Driver changes.  
**Fixture:** Dar El Bahja (`+213550000071`, owner account `0d00c071-…0001`) on the isolated iPhone 16e simulator. Finjan's simulator, the Customer, and the Driver were not touched.

## Bottom line

- **Implementation: done and tested.** It covers the FCM HTTP v1 adapter, the queued send with bounded retry, invalid-token cleanup, stale and eligibility checks at send time, and token registration, refresh, account change and logout. It also covers foreground dedupe with the 8s poll, tap routing after auth and navigation are ready, and permission and opt-out handling.
- **Provider delivery: BLOCKED.** No Firebase project or credentials exist on this machine. The provider contract was verified against a local FCM HTTP v1 **stub**, which proves request shape and error handling only, not delivery.
- **Device receipt: BLOCKED.** No real token can be minted without Firebase options, and there is no UI driver for the system permission prompt or banner taps. App-side push handling was verified on the simulator with **injected hints** through the same gateway seam Firebase uses. That is not native delivery evidence.
- Verification found and fixed **three app/backend bugs** plus one copy issue (see [Defects found during verification](#defects-found-during-verification)).

Setup checklist: [`docs/architecture/NATIVE_PUSH_SETUP.md`](../../../../../docs/architecture/NATIVE_PUSH_SETUP.md). Contract: [`NOTIFICATIONS_FOUNDATION.md` → Native Push v1.1](../../../../../docs/architecture/NOTIFICATIONS_FOUNDATION.md#native-push-v11-merchant_order_created).

---

## 1. Implementation matrix (automated tests)

| Area | Result | Evidence |
| --- | --- | --- |
| Backend notification + queue suites | **PASS** 50/50 | `jest src/modules/notifications src/infrastructure/queue` (includes new `push-dispatch.service.spec`, `push.policy.spec`, `fcm-push.gateway.spec` (JWT signature verified with a throwaway key), `notification-queue.service.spec` (isolated Redis prefix)) |
| Backend full unit suite | **PASS** 985/985 (123 suites) | `npx jest` |
| Backend build | **PASS** | `nest build` |
| Merchant push controller | **PASS** 14/14 | `test/features/merchant_push_test.dart`: registration, denial, opt-out, account-change rotation, refresh, 409 rotate-once, logout, expired session, cold-start and background tap, re-sign-in, **no session↔push provider cycle** |
| Merchant settings permission banner | **PASS** 6/6 | `test/features/notification_settings_banner_test.dart`: not yet authorized vs refused vs allowed, with and without Push configured |
| Merchant analyzer | **PASS** (no errors) | `flutter analyze`. The remaining warnings are in unrelated pre-existing tests. |
| Merchant full unit suite | 181 pass, **9 FAIL (pre-existing, unrelated)** | `test/audit/*` capture tests and two `phase5_forms_test` store-address cases. None involve notifications. Correction: the phase-3 "Ouvert" failures were not time-dependent (stale assertion vs. the server-driven availability badge); all 9 were diagnosed and closed in `docs/audit/RELIABILITY_GAP_CLOSE_REPORT.md`. |
| iOS config | **PASS** (build) | `Runner.entitlements` `aps-environment=development` embedded in the simulator binary; `UIBackgroundModes=remote-notification` |
| Android config | **PASS** (build + merged manifest, §4) | `POST_NOTIFICATIONS`, channel `merchant_new_orders` (IMPORTANCE_HIGH) |

## 2. Provider matrix (live local backend)

| Check | Result | Evidence |
| --- | --- | --- |
| `PUSH_PROVIDER=disabled` (real `.env`): order and inbox persist; Push logged `SKIPPED_NOT_CONFIGURED`; zero provider calls | **PASS** | `NATIVE_PUSH_BACKEND_DISABLED.json` |
| Token released by logout is re-registrable by the next Account; a token still active for another Account returns `409` and stays with its owner | **PASS** (HTTP 200, 200, 200, 409) | `NATIVE_PUSH_BACKEND_DISABLED.json` |
| **Stub** accepted → `PROVIDER_ACCEPTED`, `providerReference=fcm:projects/…/messages/…` (never `SENT`/`DELIVERED`) | **PASS** (contract only) | `NATIVE_PUSH_BACKEND_STUB.json` |
| **Stub** `UNREGISTERED` → token deactivated by id; healthy token stays active | **PASS** | same |
| **Stub** payload: `data{type, orderId, merchantId, branchId, notificationId}`, collapse key and `apns-collapse-id` = order id, Android channel `merchant_new_orders`, OAuth bearer | **PASS** | same |
| **Stub** 503, 503, 200 → retried with backoff, then accepted | **PASS** | same |
| **Stub** always 503 with `PUSH_SEND_MAX_ATTEMPTS=3` → exactly 3 sends, `FAILED push:retry_exhausted:UNAVAILABLE`; order still `PENDING_ACCEPTANCE`, IN_APP still `SENT`, token kept | **PASS** | same |
| Order cancelled during backoff → `SKIPPED_STALE_SOURCE`, no further send | **PASS** | same |
| No active token → `SKIPPED_NO_ACTIVE_TOKEN` | **PASS** | same |
| Stranded `PENDING` log → recovery sweep re-enqueues → `PROVIDER_ACCEPTED` | **PASS** (after the scheduler fix below) | same |
| OAuth endpoint unreachable → transient, retried, then `FAILED push:retry_exhausted:OAUTH_UNAVAILABLE`; order and inbox intact | **PASS** (observed) | First stub attempt, when the stub process was not running. Not kept as a separate artifact. |
| **Real FCM acceptance** (`PROVIDER_ACCEPTED` from Google) | **BLOCKED** | No service account / Firebase project |
| **Real APNs via FCM** | **BLOCKED** | No APNs key uploaded to Firebase |

After the stub runs, the backend was restored to the real `.env` (`PUSH_PROVIDER=disabled`).

## 3. Device matrix (iPhone 16e simulator)

`harness` = hint injected through `PushMessagingGateway` (the Firebase implementation feeds the same streams) against the live backend with a real device-token API. It involves no APNs/FCM message, no OS banner and no native tap. Provenance: `NATIVE_PUSH_SIM_HARNESS_PROVENANCE.json` and `NATIVE_PUSH_SIM_HARNESS_HOST_LOG.json`.

| Check | Result | Layer | Evidence |
| --- | --- | --- | --- |
| Token registered for Dar only after session is ready | **PASS** | harness + real API/DB | row `active=true`, `account=Dar` |
| Foreground push hint + 8s poll for the same order → exactly **one** alert, no OS banner | **PASS** (1 appearance) | harness | `push-harness-foreground-alert.png` |
| Tap on a pending order → correct order detail with actions | **PASS** | harness | `push-harness-tap-open.png` |
| Tap after the order was accepted elsewhere → stale snackbar; detail shows **Acceptée**, no Accept/Refuse | **PASS** (after the stale-cache fix) | harness + real server state | `push-harness-tap-stale.png` |
| Tap on an unknown order / foreign-merchant hint → "not accessible" snackbar, no navigation | **PASS** | harness | `push-harness-tap-inaccessible.png` |
| Token refresh → old row inactive, new row active (Dar) | **PASS** | harness + DB | provenance |
| Permission denied → token deactivated; settings say "refusée" with Push copy | **PASS** | harness-simulated OS state | `push-harness-permission-denied.png` |
| Permission re-granted → re-registered | **PASS** | harness + DB | provenance |
| Cold start from a tap → held during boot, opened only at `ready/home` | **PASS** (`boot/loading/held=true` → `ready/home/held=false` → `detail=true`) | harness | `push-harness-cold-start-open.png` (captured mid-transition) |
| Logout → this install's token deactivated before `/auth/logout`; provider token deleted | **PASS** | harness + DB | provenance |
| Foreground regression (reconnect, resume-stale, multi, shots) | **PASS** (re-run on final code) | automated integration | `../order-alerts-live/ORDER_ALERT_LIVE_REPORT.md` |
| **Native permission prompt** (iOS system dialog allow/deny) | **NOT RUN** | — | No UI driver: `simctl privacy` has no notifications service; idb/XCUITest not present |
| **Background receipt** (OS banner while backgrounded) | **BLOCKED** | — | Needs real FCM/APNs delivery |
| **Terminated receipt + native banner tap** | **BLOCKED** | — | Same, plus manual/UI-driver tap |
| **Real token registration from Firebase** | **BLOCKED** | — | No `config/push.local.json` |
| Physical iOS / Android device | **NOT RUN** | — | Requires credentials first |

## 4. Android

| Check | Result | Evidence |
| --- | --- | --- |
| `flutter build apk --debug` with `firebase_messaging` | **PASS** | `✓ Built build/app/outputs/flutter-apk/app-debug.apk` |
| Merged manifest contains `POST_NOTIFICATIONS`, `FlutterFirebaseMessagingService` (`MESSAGING_EVENT`), `default_notification_channel_id` = `merchant_new_orders` | **PASS** | `build/app/intermediates/merged_manifest/debug/…/AndroidManifest.xml` |
| Android emulator/device run (permission prompt, receipt, tap) | **NOT RUN** | No Firebase Android app id; no emulator run in this pass |

Build warning, not fixed: `permission_handler_android` compiles against SDK 37 while the app uses Flutter's default `compileSdk` (36). The build still succeeds. Setting `compileSdk = 37` is a separate toolchain decision.

---

## Defects found during verification

| # | Defect | Impact | Fix |
| --- | --- | --- | --- |
| 1 | BullMQ 6 ignores `repeat` on `Queue.add`: the `notifications-recovery` job ran **once per boot** and never again (pre-existing). | Missing inbox rows were not repaired periodically; stranded `PENDING` Push logs would never be retried. | `NotificationQueueService` now uses `upsertJobScheduler`. New spec shows it keeps firing. Live: `repeat:notifications-recovery` key present. Recovery now runs every 30s as documented, and remains idempotent (0 duplicate notifications or delivery logs in the last 24h). |
| 1b | **Same pre-existing bug in `MatchingQueueService`** (`matching-recovery`). | Matching recovery only runs at boot. | **NOT fixed** (outside Push scope; it touches driver offer timing). Needs its own change and review. |
| 2 | Riverpod cycle: the push controller `ref.listen`ed to the session, and `SessionController.logout()` reads the push controller. In debug builds that read throws `CircularDependencyError`: the token DELETE **and** `POST /auth/logout` were swallowed by `try/catch`, then `invalidateLocalSession` crashed. | Logout broken in debug; wrong dependency direction in all builds. | The push controller no longer listens to the session. `MerchantAlertHost` forwards session changes via `onSessionChanged`. There is a regression unit test, and the live harness logout step passes. |
| 3 | `orderDetailControllerProvider` is a non-auto-dispose family. Reopening an order (push tap or in-app alert) showed cached "Nouvelle commande" with actions after it had been accepted elsewhere. | Violated "handled orders never shown as awaiting acceptance". | `_openOrder` invalidates that order's detail state before navigating. Live harness stale step passes. |
| 4 | The settings banner said "Permission iOS : refusée" when permission had never been requested (iOS `permission_handler` returns `denied` before the first prompt). | Misleading copy. | Three states: allowed / refused / "pas encore autorisée". Widget tests added. |
| — | Harness only: the OTP verify was tapped before the rebuild that enables the button. Also fixed in the gap test. | Harness logins silently failed. Earlier gap runs had relied on a persisted session. | `pump` before tap. |

---

## Credential blockers (user steps, no secrets in chat)

Full steps: [`NATIVE_PUSH_SETUP.md`](../../../../../docs/architecture/NATIVE_PUSH_SETUP.md).

1. Create a Firebase project and enable **FCM API (V1)**.
2. Add the iOS app `com.speedygo.speedygoMerchantApp`. In Apple Developer (team `HVDAQ6R4SW`), enable Push, create an **APNs auth key (.p8)**, and upload it in Firebase → Cloud Messaging. Regenerate the profiles.
3. Add the Android app `com.speedygo.speedygo_merchant_app`. No `google-services.json` is needed.
4. Generate a service-account JSON and store it outside the repo (e.g. `~/.speedygo/dev/fcm-service-account.json`, `chmod 600`).
5. In `apps/backend/.env`, set `PUSH_PROVIDER=fcm`, `FCM_PROJECT_ID=<project id>` and `FCM_SERVICE_ACCOUNT_FILE=<absolute path>`. Restart the backend.
6. Create `apps/merchant_app/config/push.local.json` (gitignored) from `config/push.example.json` with the `SGO_FIREBASE_*` keys. Run with `--dart-define-from-file=config/push.local.json`.
7. Use a physical iPhone (and an Android device) for receipt evidence.

**Unblocked by these steps:** real token registration, real `PROVIDER_ACCEPTED`, background receipt, terminated receipt and tap, native permission prompt, physical devices.

## Files changed for native push

The backend worktree also holds earlier uncommitted phases. Only Push-related files are listed here. The Merchant repo has no commits yet, so git cannot diff it; its files are listed by path.

**Backend (`apps/backend`)**
- New: `src/modules/notifications/application/push-dispatch.service.ts` (+spec), `domain/push.policy.ts` (+spec), `domain/push.types.ts`, `infrastructure/fcm-push.gateway.ts` (+spec), `infrastructure/notification-queue.service.spec.ts`
- Modified: `notification.service.ts` (+spec), `notification-recovery.service.ts` (+spec), `notification.jobs.ts`, `notification.policy.ts`, `notification.types.ts`, `notification-queue.service.ts` (Job Scheduler), `notification-recovery.repository.ts`, `notification.processor.ts`, `notification.repository.ts` (token reassignment/deactivation), `notifications.module.ts`, `src/config/configuration.ts`, `src/app.module.ts`, `.env.example` (placeholders only)
- No Prisma contract or migration change. Uses the existing `DeviceToken` and `NotificationDeliveryLog` tables.

**Merchant app (`apps/merchant_app`)**
- `pubspec.yaml`: `firebase_core`, `firebase_messaging`
- New: `lib/features/notifications/data/{push_config,push_messaging_gateway,push_registration}.dart`, `lib/features/notifications/application/merchant_push_controller.dart`
- Modified: `lib/main.dart`, `lib/features/auth/application/session_controller.dart` (logout deactivation), `lib/features/notifications/application/order_alert_controller.dart` (push hint → same dedupe path), `lib/features/notifications/presentation/{merchant_alert_host,notification_settings_screen}.dart`, `lib/core/constants/app_strings.dart`
- Platform: `ios/Runner/Runner.entitlements`, `ios/Runner/Info.plist` (`remote-notification`), `ios/Runner.xcodeproj/project.pbxproj` (`CODE_SIGN_ENTITLEMENTS`), `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/…/MainActivity.kt` (channel)
- Config: `config/push.example.json` (placeholders); `.gitignore` ignores `/config/push.local.json`
- Tests: `test/features/merchant_push_test.dart`, `test/features/notification_settings_banner_test.dart`, `integration_test/native_push_harness_test.dart`, `integration_test/order_alert_gap_close_test.dart` (provenance wording + OTP pump)

**Docs**
- `docs/architecture/NOTIFICATIONS_FOUNDATION.md` (v1.1 amendment), new `docs/architecture/NATIVE_PUSH_SETUP.md`

## Sanitized provenance

- All tokens in the evidence are synthetic (`sim-harness-*`, `stub-*`). No device tokens, OTPs, keys or bearer values are recorded.
- The stub service account used a throwaway RSA key under `/tmp` (not in any repo), with `token_uri` pointing to the local stub. `FCM_API_BASE_URL` is ignored when `NODE_ENV=production`.
- Host drivers (`/tmp/push_verify.py`, `/tmp/push_stub/fcm_stub.py`, `/tmp/push_harness_host.py`) are outside the repos. The Flutter side is `integration_test/native_push_harness_test.dart`.

| File | Content |
| --- | --- |
| `NATIVE_PUSH_BACKEND_DISABLED.json` | Real `.env`, provider disabled + token reassignment |
| `NATIVE_PUSH_BACKEND_STUB.json` | Local FCM contract stub: acceptance, invalid token, retry, bounded failure, stale, no token, recovery |
| `NATIVE_PUSH_SIM_HARNESS_PROVENANCE.json` | 10 simulator steps (harness layer) |
| `NATIVE_PUSH_SIM_HARNESS_HOST_LOG.json` | Host operations: order create/accept/reject, token row reads |
| `push-harness-*.png` | Simulator screenshots for the harness steps |
