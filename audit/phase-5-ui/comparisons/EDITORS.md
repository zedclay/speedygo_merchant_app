# Phase 5 — editor reference vs current

Comparisons use **same display width (390px)** for reference and current, preserve aspect ratio, and crop **corresponding** top/bottom sections (not a full tall reference beside a wider viewport).

## Plates

| Plate | Section | Notes |
| --- | --- | --- |
| `product_create_ref_vs_mocked_se.png` | top | Informations-first create |
| `product_create_scrolled_ref_vs_mocked_se.png` | bottom | Configuration + availability |
| `product_edit_ref_vs_mocked_se.png` | top | Edit reference layout |
| `product_validation_ref_vs_mocked_se.png` | top | Field error (not save-failure) |
| `product_save_failure_ref_vs_mocked_se.png` | top | Server save failure + retry copy |
| `category_edit_ref_vs_mocked_se.png` | top | Détails / Paramètres |
| `address_ref_vs_mocked_se.png` | top | Coordonnées |
| `address_scrolled_ref_vs_mocked_se.png` | bottom | Confirmed location + map |
| `cover_ref_vs_mocked_se.png` | top | Logo gap + cover |
| `cover_scrolled_ref_vs_mocked_se.png` | bottom | Cover / aperçu client |
| `reports_ref_vs_mocked.png` | top | Landing 2+1 ops |

## Mocked captures

Under `mocked/editors/`: SE/Pro, scrolled bottoms, text 1.3, keyboard (simulated `viewInsets` + `*.NOTE.txt`), `product_validation_se`, `product_save_failure_se`, **`product_preview_se`** (local Aperçu sheet with name/price/description/image; close does not save).

## Live UI (separate)

`live/live-*-se.png` on **iPhone 16e** — native IME keyboard shot is device-captured, not simulated insets.  
Save→reopen asserts persisted name/price against the catalog `productId`, then DELETE cleanup by that ID (`LIVE_UI_PROVENANCE.json`).  
Merchant remote media read remains **UNRESOLVED** (`MEDIA.md`).
