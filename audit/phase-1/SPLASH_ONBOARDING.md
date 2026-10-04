# Merchant splash + onboarding (Phase 2 paused)

Mocked captures only — not live device evidence.

## Captures

Directory: `captures/splash-onboarding/`

| File | Route / content |
| --- | --- |
| `splash-375x667.png` | `/` blue splash + logo + tagline |
| `splash-402x874.png` | `/` same at Pro size |
| `onboarding-1-*.png` | `/onboarding` page 1 |
| `onboarding-2-375x667.png` | page 2 |
| `onboarding-3-*.png` | page 3 + Commencer |
| `*-text-1_3-*.png` | onboarding at text scale 1.3 |

Regenerate:

```bash
cd apps/merchant_app
flutter test test/audit/splash_onboarding_capture_test.dart
```

## Routing

Signed-out: splash → language (if needed) → onboarding (if needed) → phone.

Flag: `speedygo.merchant.onboarding.v1` (separate from language + tokens).

## Asset limitations

- Illustrations bake French UI copy (`Nouvelle commande`, `Mon Commerce`, etc.) — not Arabic-localized.
- Logo has soft AA fringe (~33% of non-transparent pixels at alpha ≤ 40); content bbox touches bottom edge. Real alpha (no opaque black plate). Report as asset polish debt, not production-perfect.
- Native launch: iOS/Android solid `#0A4096` only — no Flutter curves/logo animation on the OS frame.
