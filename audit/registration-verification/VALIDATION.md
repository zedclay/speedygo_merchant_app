# Validation — registration / verification

## Commands

```bash
cd apps/merchant_app
flutter analyze   # exit 1, 28 *info* only (0 errors) — 2026-09-17
flutter test      # exit 0, 53 passed
```

## Mocked coverage
- New registration entry (account step)
- Operator does not create merchant
- Existing membership reconcile skips create
- Resume prefills name (Finjan-safe pattern)
- Upload/bind checklist update
- Incomplete PENDING → registration; submitted PENDING → pending UI
- Splash/onboarding/phone regressions

## Captures
`captures/*.png` (mocked). Live gesture/API evidence: **not run** against Finjan (read-only). No synthetic merchant fixture claimed this pass.

## Customer preservation
Working-tree porcelain compared before/after: **unchanged**.  
HEAD `8adae21afc1a575cf119a44a20538d93bad3d190` unchanged.

## Step 3–4 visual correction

- Status: **implementer_reviewed**
- Tests: `evidence_presentation_test`, `registration_flow_test`, `registration_capture_test` — exit 0
- Analyze: see `STEP34_VISUAL_CORRECTION.md`
- Customer porcelain: unchanged vs baseline
- Captures + comparisons under `captures/` and `captures/comparisons/`

