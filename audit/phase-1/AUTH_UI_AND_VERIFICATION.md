# Merchant auth UI alignment + verification cleanup

## Customer files inspected (read-only)

| File | SHA-256 before == after |
| --- | --- |
| `lib/features/auth/presentation/phone_screen.dart` | unchanged |
| `lib/features/auth/presentation/otp_screen.dart` | unchanged |
| `lib/core/widgets/sg_primary_button.dart` | unchanged |
| `lib/app/theme/app_theme.dart` | unchanged |
| `lib/core/constants/app_strings.dart` | unchanged |

No Customer files were modified.

## Visual match (Merchant ← Customer)

- Centered brand header, title + subtitle, +213 prefix + flag field, SMS note
- Bottom blurred CTA bar with primary button + “Besoin d’aide ?”
- OTP digit boxes, autofill, resend countdown clock, “Modifier” change-number
- Back affordances; `resizeToAvoidBottomInset` + SafeArea
- Intentional Merchant wording: app title **SpeedyGo Merchant**; SMS “vérification” (not Customer “confirmation”)

## Merchant behavior preserved

- Merchant session/storage keys, refresh, splash/language fixes
- Post-login Merchant access / verification / branch routing (not Customer profile)
- OTP platform `ios`, cooldown, duplicate-submit guards
- Change-number stays in `awaitingOtp` without forced re-login

## Verification screen (before → after)

**Before:** raw `PENDING_REVIEW`, `BUSINESS_IDENTITY`, `required=true present=false complete=false`, implementation gap prose, “Réessayer” for refresh.

**After:** human status (“En vérification”), document titles from SpeedyGo evidence categories (not statutory assumptions), Obligatoire/Facultatif, Manquant/Fourni/En examen/Validé, “Actualiser le statut”, no fake upload. `PENDING_REVIEW` with missing required pieces = registered commerce awaiting completion, not a claimed submitted dossier.

Document upload remains unfinished (no upload UI).

## Mocked captures

`audit/phase-1/captures/auth-ui/`: phone 375 / keyboard / OTP 375 / 402 / text 1.3 / verification missing.

## Tests

```bash
flutter test test/ --concurrency=1   # all passed
```

Live Finjan dossier was not modified for screenshots.
