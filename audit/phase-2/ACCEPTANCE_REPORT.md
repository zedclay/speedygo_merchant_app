# Merchant Phase 2 — Order operations

**Status:** `implementer_reviewed` (awaits human visual acceptance; **not** `human_accepted`)  
**Design source of truth:** `screens/MerchantScreens/<folder>/screen.png` + `code.html` — see `docs/MERCHANT_UI_SOURCE_OF_TRUTH.md`.  
**Pass:** Remaining visual corrections — compact refs, ready status consolidation, En cours/Historique + shell captures. Catalogue paused.

## Verdict

| Item | Result |
| --- | --- |
| Compact canonical references + copy sheet | **Done** |
| Ready: one “Commande prête” status section | **Done** |
| En cours / Historique API filter mapping | **Done** (documented in `review/INDEX.md`) |
| Shell captures SE/Pro/1.3 | **Done** (mocked) |
| Order mutations | **Preserved** |
| Updated live SE smoke | **NOT RUN** (Finjan on 17 Pro preserved; API health 200) |
| Customer this-pass content hash | **MATCH** |

## Validation (exact)

```text
cd apps/merchant_app
dart analyze lib/features/orders lib/core/constants/app_strings.dart lib/features/shell/merchant_shell.dart
# exit 0 — No issues found!

flutter test test/features/order_list_visual_corrections_test.dart test/features/order_ops_test.dart
# exit 0 — +15: All tests passed!

flutter test test/audit/phase2_visual_review_capture_test.dart
# exit 0 — +1
```

## Customer (this pass)

Baseline → end: **MATCH**  
`3cf5b81b1e7645edf57a0ec47fa8a8ff8320360f656aedf8e2703c08414708f1`  
See `fixtures/customer_pass_end_report.json`. Not a claim about prior historical mismatches.

## Evidence

- Package: `review/` + `phase-2-review.zip`
- Index: `review/INDEX.md`
- Side-by-sides: `review/structure/side-*.png`

## Untouched

Finjan 17 Pro session, Customer files, backend/schema/`.env`, Catalogue, commit/push.
