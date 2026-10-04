# Phase 5 — live evidence

## Layers (do not conflate)

| Layer | Artifact | Meaning |
| --- | --- | --- |
| **API** | `LIVE_PROVENANCE.json` | OTP + HTTP save→reload for category/product/address + media upload/bind |
| **Merchant UI** | `LIVE_UI_PROVENANCE.json` + `live-*-se.png` | Isolated integration test through `com.speedygo.speedygoMerchantApp` |

## Synthetic fixture

| Item | Value |
| --- | --- |
| Script / namespace | `apps/backend/scripts/dev-review-catalog` |
| Owner phone | `+213550000071` |
| Merchant | Dar El Bahja / `sgm_review_01` |
| Bundle ID | **`com.speedygo.speedygoMerchantApp`** |
| Simulator | **iPhone 16e** `8DB9007A-B816-4EC5-86ED-C627AC60F2C5` (SE UDID invalid/unavailable this pass) |
| Entrypoint | `integration_test/phase5_editors_live_test.dart` |
| Finjan / Customer | Untouched (17 Pro Finjan left alone; Customer app not launched) |

## Merchant UI verified (this pass)

| Step | Status |
| --- | --- |
| Login → home Dar El Bahja | **PASS** |
| Nav catalog → product create | **PASS** |
| Field validation (`Ce champ est obligatoire`) | **PASS** |
| Native keyboard focus on name | **PASS** (device IME; see `live-product-keyboard-se.png`) |
| Save → pop | **PASS** |
| Save identity (`productId` + expected name/price) | **PASS** — `01a0bce3-f2f1-7c6f-bd57-146d647e9252` / `Phase5 UI Probe 48411` / `18,50` (minor 1850) |
| Reopen from catalog by that ID | **PASS** — name + price fields match expected |
| Cleanup DELETE by same `productId` | **PASS** |
| Nav address + location summary | **PASS** |

## API verified (prior / retained)

Category / product / address save→reload; media upload+bind **PASS**.  
Merchant remote media **GET**: **UNRESOLVED** — no authorized merchant read route identified/verified (do not infer contract from guessed 404s). See `MEDIA.md`.

## Screenshots

`live-home-se.png`, `live-product-create-se.png`, `live-product-validation-se.png`, `live-product-keyboard-se.png`, `live-product-after-save-se.png`, `live-product-reopen-se.png`, `live-address-se.png`  
(Captured on iPhone 16e, 2026-09-20 ~04:37 local.)

Visual acceptance remains **pending**.
