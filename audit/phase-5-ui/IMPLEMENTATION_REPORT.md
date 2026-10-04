# Phase 5c — implementation report

**Date:** 2026-09-20  
**App:** Merchant `com.speedygo.speedygoMerchantApp`  
**Visual status:** implementer_reviewed (visual acceptance pending)  

## Fixes this pass

| Area | Change |
| --- | --- |
| Product CREATE order | Informations → Médias → Prix et préparation → Configuration |
| Product EDIT | Kept separate: Disponibilité → Image → Informations générales → Prix et détails → Configuration |
| Merchant copy | Gap rows use **Non disponible actuellement**; removed hors contrat / endpoint / Structure de référence / non branché from UI |
| Validation | Field-level errors + focus/scroll; `Enregistrement impossible. Vérifiez…` only on save failure |
| Footer | Full **Enregistrer**; **Aperçu** opens local draft preview sheet (name/price/description/image); close preserves draft, does not save |
| Evidence | Bottom section captures; width-normalized comparisons; separate validation vs save-failure PNGs; `product_preview_se.png` |
| Live reopen | Record `productId` + expected name/price; reopen via Merchant UI; assert persisted fields; DELETE cleanup by that ID |

## Tests

```bash
cd apps/merchant_app
flutter test \
  test/features/phase5_forms_test.dart \
  test/features/phase5_catalog_reports_test.dart \
  test/audit/phase5_editors_visual_capture_test.dart
# EXIT 0, +46 All tests passed

# Focused preview
flutter test test/features/phase5_forms_test.dart --name "local draft preview"
flutter test test/audit/phase5_editors_visual_capture_test.dart --name "draft preview"
# EXIT 0

flutter test integration_test/phase5_editors_live_test.dart \
  -d 8DB9007A-B816-4EC5-86ED-C627AC60F2C5 \
  --dart-define=PHASE5_PHONE=550000071
# EXIT 0, +1 All tests passed (Merchant UI on iPhone 16e / Dar El Bahja)
# productId 01a0bce3-f2f1-7c6f-bd57-146d647e9252 → reopen PASS → DELETE cleanup PASS
```

## Live

- **API** provenance: `live/LIVE_PROVENANCE.json`  
- **UI** provenance: `live/LIVE_UI_PROVENANCE.json` + `live-*-se.png` (16e)  
- Local draft preview capture: `mocked/editors/product_preview_se.png`  
- Remote media read: **UNRESOLVED** (documented in `MEDIA.md`; not inferred from guessed GETs)

## Preserved

Catalogue/report layout fixes, CRUD, media bind semantics, Finjan/Customer sessions. No backend/schema/.env/commit/push.
