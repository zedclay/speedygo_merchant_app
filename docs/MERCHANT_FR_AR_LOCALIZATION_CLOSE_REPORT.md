# Merchant FR/AR Localization Close — rows 45 & 61

**Date:** 2026-10-04 (Africa/Algiers) · closed 2026-10-05  
**Branch:** `feat/merchant-fr-ar-localization-v1` (from `main` / `fd4e50e`)  
**Scope:** Merchant app only — no backend / Customer / Driver / Admin changes  
**Acceptance:** `implementer_reviewed` (not `user_accepted`)  
**Bottom Navigation Concept V1:** unchanged (`user_accepted` dock chrome)

## Decisions applied

| ID | Decision |
| --- | --- |
| **D-G3** | Ship full French + Arabic string set (ARB) and an in-app language screen. Arabic is offered because Arabic copy exists. |
| **D-C6** | Arabic add-product is the same `/app/catalog/products/new` route in the `ar` locale (localized FR form + RTL). The Stitch root Arabic alternate layout is **not** shipped as a separate UI. |

Rows **23** and **51** stay open (partial). Target count: **75/77 closed**.

## What shipped

| Area | Detail |
| --- | --- |
| ARB | `lib/l10n/app_fr.arb` + `app_ar.arb` (~1181 keys); `flutter gen-l10n` → `AppLocalizations` |
| Facade | `AppStrings` binds to `AppLocalizations` + bilingual Dart helpers for plurals / parameterized copy |
| Locale | `locale_support.dart`, Riverpod `setLocale`, secure persist via launch store, RTL `Directionality` |
| Language UI | `LanguageSettingsScreen` at `/app/profile/settings/language`; Preférences → Langue row |
| Pre-auth | Existing `/language` `LanguageScreen` retained |
| Bottom nav | Labels localized; Concept V1 meaning / chrome unchanged |

## Evidence

| Check | Result |
| --- | --- |
| `flutter analyze lib` | **0 errors** (infos remain) |
| `test/features/localization_fr_ar_test.dart` | **PASS** (locale resolve, ARB parity, switch + persist, RTL) |
| `test/audit/localization_fr_ar_capture_test.dart` | **PASS** |
| Feature suite (incl. reports capture) after string-helper fixes | **PASS** |
| Live device / simulator Merchant↔API | **NOT RUN** |
| Commit / push | **NOT RUN** (refused by brief) |

### Mocked captures

`audit/parity/captures/l10n_fr_ar_2026-10-04/`

| File | Row |
| --- | --- |
| `row45_add_product_fr.png` | 45 FR |
| `row45_add_product_ar.png` | 45 AR |
| `row45_add_product_ar_scale13.png` | 45 AR @ text scale 1.3 |
| `row61_language_settings_fr.png` | 61 FR |
| `row61_language_settings_ar.png` | 61 AR |

## Tracker updates

- `audit/parity/matrix/progress.json` — rows 45 & 61 → done (`implementer_reviewed`)
- `audit/parity/matrix/MERCHANT_SCREEN_PARITY_MATRIX.md` (+ `docs/` copy) — D-C6 / D-G3 decided; remaining **2 of 77 open · 75/77 closed (97.4%)**

## Remaining open rows (unchanged)

| # | Status | Blocker |
| --- | --- | --- |
| 23 | partial | Driver enter-code / confirm-pickup UI |
| 51 | partial | Map search (D-D7), pickup hint, owner footer |

## Explicit non-claims

- Not visually `user_accepted`
- Not live-compared on device
- Not a separate Arabic add-product design system (D-C6 = same route + locale)
- No production deploy, secrets, or cross-app contract changes
