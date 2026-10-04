# Phase 2 changed files (Merchant)

## Remaining visual corrections (this pass)

- `lib/features/orders/presentation/order_public_reference.dart` — compact ref + full view/copy
- `lib/features/orders/presentation/orders_screen.dart` — En cours/Historique segments; secondary refs; customer-first cards
- `lib/features/orders/presentation/order_detail_screen.dart` — single ready status section; compact refs
- `lib/features/orders/data/order_models.dart` — filter enum + API mapping docs (completed/failed history)
- `lib/features/orders/application/orders_controller.dart` — default filter `incoming`
- `lib/core/constants/app_strings.dart` — segment / reference copy strings
- `integration_test/phase2_post_rejection_test.dart` — Historique → Annulées navigation
- `test/features/order_list_visual_corrections_test.dart` — focused regression
- `test/audit/phase2_visual_review_capture_test.dart` — shell + SE/Pro/1.3
- `audit/phase-2/review/**`, `INDEX.md`, `ACCEPTANCE_REPORT.md`, `CONTRACT_MAP.md`, `phase-2-review.zip`
- `audit/phase-2/fixtures/customer_pass_baseline_*`, `customer_pass_end_report.json`
- `docs/MERCHANT_UI_SOURCE_OF_TRUTH.md` — design source of truth + Phase 2 inventory
- Workspace rule: `.cursor/rules/merchant-ui-design-references.mdc`

## Preserved

Accept / reject / start-preparation / mark-ready contracts; labelled GMS vs net; Créée/Annulée timestamps; sticky footer DecoratedBox; Finjan session.

Backend / Customer / schema / `.env` / Catalogue: **unchanged**.
