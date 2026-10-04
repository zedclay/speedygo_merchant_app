# Startup fix evidence (2026-09-17)

## Proven root causes

1. **Language screen stuck after tap** — `app_router.dart` signed-out redirect treated `/language` as a valid stay destination even when `languageSeen == true`:
   `if (path == phone || path == language) return null;`
   So `setLocale` persisted and updated state, but GoRouter never advanced to phone.

2. **Splash skipped / invisible** — `SplashScreen` ran `Future.wait([minDelay, restore()])` in parallel. `restore()` left `SessionPhase.boot` immediately → redirect away from splash before the brand hold could show. Cold launch now keeps `boot` until splash finishes its hold, then calls `restore()`.

## Fix

- Splash: sequential bootstrap (hold → then `restore()`); single-flight restore guard.
- Redirect: language allowed only while `!languageSeen`; otherwise signed-out target is phone/OTP.
- `setLocale`: busy + recoverable error if persistence fails.

## Live cold launch (iPhone 17 Pro, process terminate + simctl launch)

| Capture | Result |
| --- | --- |
| `01-cold-launch-early.png` | Brief white (pre-Flutter paint) |
| `02-cold-launch-splash.png` | Branded splash + loader |
| `03/04-*.png` | Phone login (saved language skipped picker; no session) |

Language-tap on device Keychain not re-exercised (would require clearing language keys). Isolated integration test covers Français → phone without touching real session storage.
