# Merchant media persistence & remote display — verification report

**Status:** `implementer_reviewed` (awaiting visual acceptance)  
**At:** 2026-09-24T15:20:00Z  

## Verdict

Authenticated Merchant remote media read works end-to-end (JWT stream → Dio bytes → `Image.memory`). The earlier **product Image paint FAIL** was a **test harness defect** (list tap hit FAB → create editor / wrong product), not an app decode failure. Opening Couscous by route paints the remote fixture. Cold relaunch via `flutter run` (terminate + relaunch, no uninstall) shows product + cover after reopen and after replace.

## Diagnosis (product editor paint)

| Layer | Result |
| --- | --- |
| HTTP Merchant GET `…/products/:id/image` | **PASS** — PNG 1391 B, `image/png` |
| Dio `ResponseType.bytes` → `Uint8List` | **PASS** — hardened `_bytesFromResponse` |
| Editor state `_localImageBytes` | **PASS** — `bytes=1391 expectRemote=true` on Couscous |
| Visible layout | **PASS** — solid blue fixture RGB≈(30,120,200) in screenshot |
| Prior harness `productRows.first` / FAB hit | **FAIL (harness)** — opened create or unbound row; `find.byType(Image)` empty |

App still hardened: `product.branchId` fallback when `selectedBranch` missing; non-silent image sync error; edit empty placeholder 4/3; `Image.memory` key / `gaplessPlayback` / `errorBuilder`.

## Checks

| Check | Result | Notes |
| --- | --- | --- |
| Trace metadata → Merchant GET streams | **PASS** | Product `…/image`, cover `…/cover` |
| Contract from routes/docs | **PASS** | Controllers + `MEDIA.md` |
| Merchant ownership on read | **PASS** | HTTP 401 / foreign 404 |
| Preserve Customer behavior | **PASS** | No Customer changes |
| Product upload→bind→save→reopen remote | **PASS** | HTTP + UI: `media-product-reopened.png` / `media-product-reopen.png`; `bytes=1391` |
| Cover upload→bind→reopen remote | **PASS** | `media-cover-reopened.png` / `media-cover-reopen.png` (green) |
| Cold relaunch remote visible | **PASS** | `flutter run` + `simctl terminate` (no uninstall); `media-product-cold.png` (blue) + `media-cover-cold.png` (green) |
| Replace image after relaunch | **PASS** | HTTP red bind then cold UI `media-product-replace.png` RGB≈(200,60,40) |
| Delete cover → fallback | **PASS** | HTTP only (prior); UI not re-run this pass |
| Unauthorized rejected | **PASS** | Prior HTTP |
| Loading / missing / retry | **PASS** | Prior |
| Save ≠ display failure | **PASS** | Prior |
| MerchantScreens proportions | **PASS** | Product 4/3; cover 16/9 |
| Finjan preserved | **PASS** | 16e / Dar El Bahja only; 17 Pro untouched |
| Backend jest e2e media GET asserts | **NOT RUN** | Suite bootstrap blocked (see below) — not a media-route verdict |

## Backend e2e blocker (NOT RUN)

Focused `product-images.e2e-spec.ts` / `commerce-verticals-and-covers.e2e-spec.ts` abort before media asserts can be trusted:

1. **OTP verify returns HTTP 500** during suite bootstrap (`expect(verified.status).toBe(200)` → Received `500`) — auth/env issue, not image routes.
2. **Prisma ESM teardown**: `require()` of `prisma/db` fails (`@prisma/orm-extension-postgis/runtime` ESM under Jest) on `PrismaService.onModuleDestroy`, plus post-teardown BullMQ workers still calling `getDb()`.

Scoped test-env correction alone is **not** sufficient in this workspace without broader Jest/Prisma ESM + OTP harness work. Do **not** treat the suite as passing or infer route correctness from this failure.

## Evidence

| Artifact | Role |
| --- | --- |
| `media-live/media-product-reopened.png` | Integration reopen (blue fixture visible) |
| `media-live/media-cover-reopened.png` | Integration cover reopen (green) |
| `media-live/media-product-reopen.png` | `flutter run` reopen |
| `media-live/media-cover-reopen.png` | `flutter run` cover reopen |
| `media-live/media-product-cold.png` | Cold relaunch product (blue) |
| `media-live/media-cover-cold.png` | Cold relaunch cover (green) |
| `media-live/media-product-replace.png` | After red replace + relaunch |
| `media-live/MEDIA_LIVE_PROVENANCE.json` | Integration steps |
| `media-live/MEDIA_COLD_PROVENANCE.json` | Cold/replace steps |
| `media-http/MEDIA_HTTP_EVIDENCE.json` | HTTP streams |

**Fixture:** Dar El Bahja `+213550000071`  
**IDs:** merchant `0d00c071-…0001`, branch `…011001`, product Couscous `…030101`  
**Device:** iPhone 16e `8DB9007A-B816-4EC5-86ED-C627AC60F2C5`  
**Bundle:** `com.speedygo.speedygoMerchantApp`  
**Remote requests:** Merchant JWT `GET …/products/…/image` and `GET …/cover` (200, PNG)

## Changed this pass

- `lib/features/access/data/merchant_api.dart` — robust byte parsing for product/cover GET
- `lib/features/catalog/presentation/product_editor_screen.dart` — branchId fallback, sync error, Image keys, 4/3 empty
- `lib/features/catalog/presentation/merchant_product_thumb.dart` — branchId fallback
- `lib/main_media_cold_verify.dart` — cold-relaunch entrypoint
- `integration_test/media_remote_display_live_test.dart` — open Couscous by route; assert editor Image + bytes
- `audit/phase-5-ui/run_media_cold_relaunch.sh` — host terminate/relaunch + screenshots

Finjan, Customer app, sessions/Keychain preserved (no uninstall on cold path; isolated Dar El Bahja fixture writes only).
