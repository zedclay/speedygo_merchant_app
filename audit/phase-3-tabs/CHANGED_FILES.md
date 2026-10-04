# Phase 3 — changed files (Merchant app only)

## Screens / shell
- `lib/features/shell/home_dashboard_screen.dart`
- `lib/features/shell/profile_settings_screen.dart`
- `lib/features/shell/merchant_shell.dart` (nav wiring)
- `lib/features/catalog/presentation/catalog_screen.dart`
- `lib/features/catalog/application/catalog_controller.dart`
- `lib/features/catalog/data/catalog_models.dart`
- `lib/features/reports/presentation/reports_screen.dart`
- `lib/features/reports/application/reports_controller.dart`
- `lib/features/reports/data/reports_models.dart`
- `lib/features/orders/presentation/orders_screen.dart` (empty copy)
- `lib/features/orders/data/order_models.dart` (En cours AND filters)
- `lib/features/orders/application/orders_controller.dart` (home counts/lists AND)
- `lib/features/access/data/merchant_api.dart` (catalog/ratings/settlements)
- `lib/core/constants/app_strings.dart`
- `lib/app/router/app_router.dart`

## Tests / audit
- `test/features/phase1_flow_test.dart` (FakeMerchantApi stubs)
- `test/features/order_list_visual_corrections_test.dart`
- `test/audit/phase3_tabs_visual_capture_test.dart`
- `integration_test/phase3_tabs_live_capture_test.dart`
- `audit/phase-3-tabs/**`
- `docs/MERCHANT_UI_SOURCE_OF_TRUTH.md`

No Customer / backend / schema / `.env` changes. No commit/push.
