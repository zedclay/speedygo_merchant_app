# Wilaya/Commune live Flutter verification

**Status:** `implementer_reviewed` (awaiting your screenshot review)  
**At:** 2026-09-21T01:52:00Z  

## App identity / devices / build

| Item | Value |
| --- | --- |
| Bundle | `com.speedygo.speedygoMerchantApp` |
| Finjan device | iPhone 17 Pro (`4A1C3481-8B8E-48BD-983D-03896884EF09`) |
| Fixture device | iPhone 16e (`8DB9007A-B816-4EC5-86ED-C627AC60F2C5`) |
| Finjan merchant | Finjan / branch Finjan Coffer — phone `+213549445167` |
| Fixture merchant | Geo Live Fixture Merchant / Live Geo Branch — account `+213555019998`, branch phone `+213555099888` |
| Entry points | `integration_test/wilaya_commune_finjan_readonly_test.dart`, `integration_test/wilaya_commune_fixture_live_test.dart` |
| Layout unit | `test/features/wilaya_commune_layout_test.dart` |

UI evidence: `apps/merchant_app/audit/wilaya-commune/live/`  
HTTP evidence (separate): `apps/merchant_app/audit/wilaya-commune/http/`

## Checks

| # | Check | Result | Evidence / notes |
| --- | --- | --- | --- |
| 1 | Full restart Merchant on iPhone 17 Pro; bundle `com.speedygo.speedygoMerchantApp`; preserve data/Keychain; no uninstall; not Customer | **PASS** | Bundle confirmed via `listapps` / `Info.plist`. Restart = `simctl terminate` + `simctl launch` after `simctl install` of built `Runner.app`. Customer terminated if present; never used for this flow. Note: `flutter test` tears down the app; final Pro state uses `simctl install` + terminate/launch (no uninstall in the restart step). |
| 2 | Finjan Profil → Adresse; Wilaya/Commune selectors visible; no save | **PASS** | `finjan-home.png`, `finjan-address-form.png`, `FINJAN_READONLY_PROVENANCE.json`. Form shows `22 — Sidi Bel Abbès` / `Sidi Bel-Abbes`. Save control present, not activated. Finjan DB unchanged (`22`/`824` / `made a center`). |
| 3a | Fixture: open Wilaya picker, search/select | **PASS** | `fixture-wilaya-search.png` (search “Alger” → `16 — Alger`). |
| 3b | Commune lists only that wilaya’s communes | **PASS** | `fixture-commune-search.png`; live assert Alger Centre present, Oran tile absent under Alger sheet. |
| 3c | Select commune | **PASS** | Provenance `commune_select`. |
| 3d | Change Wilaya → Commune clears | **PASS** | Provenance `wilaya_change_clears_commune` → `Sélectionner`. |
| 3e | Select valid pair, save, soft reopen | **PASS** | Soft reopen UI: `31 — Oran` / `Oran`. DB: `wilaya_code=31`, `commune_id=1131`. `fixture-saved-reopened.png`, `fixture-address-form.png` (post-save). Auto-dismiss after save required one back-nav fallback once; save path fixed to `pop` before `refreshInPlace`. |
| 3f | Cold relaunch; same IDs + displayed names | **PASS** | `WILAYA_FIXTURE_MODE=reopen` after `simctl terminate`; `fixture-reopened.png`; provenance `cold_reopen_restore`. |
| 3g | `addressText` + map coordinates unchanged | **PASS** | UI + DB: `12 Rue Didouche Mourad`, lat `36.753`, lng `3.058` (pre/post). HTTP: `http/FIXTURE_HTTP_EVIDENCE.json`. |
| 3h | Registration uses same selectors | **NOT RUN** | Fixture already has a branch; establishment step not reachable. Shared `AdminLocationSelectField` covered by store-address + layout unit test. |
| 4 | Loading / error / retry; small screen + enlarged text | **PASS** (layout/loading) / **NOT RUN** (live fault injection) | Layout unit PASS at SE-sized surface + text scale 1.6. Live commune load uses loading hint. Error/retry UI present in `store_address_screen.dart` (retry buttons); live API fault not injected. |
| 5 | UI captures + provenance; HTTP separate | **PASS** | Live PNGs + `*_PROVENANCE.json` under `live/`. HTTP under `http/` (`FIXTURE_HTTP_EVIDENCE.json`, `FINJAN_HTTP_READONLY.json`). |

## Defect fixed during verification

- **Store address save did not dismiss** when `refreshInPlace()` ran before `context.pop`. Fixed in `store_address_screen.dart`: pop first, then refresh. Soft reopen / cold reopen / DB persistence confirmed after fix.

## Isolation

- Finjan branch geo unchanged (`22` / `824` / `made a center` / coords unchanged).  
- Customer app not used for verification flows.  
- Fixture work only on Geo Live Fixture Merchant (activated locally for home-shell access).

## Screenshot review queue

Please review:

1. `live/finjan-address-form.png`  
2. `live/fixture-address-form.png`  
3. `live/fixture-wilaya-search.png`  
4. `live/fixture-commune-search.png`  
5. `live/fixture-saved-reopened.png`  
6. `live/fixture-reopened.png`  
