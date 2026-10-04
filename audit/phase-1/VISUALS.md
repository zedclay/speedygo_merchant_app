# Merchant Phase 1 — Visual references and captures

## DESIGN.md resolutions

- Primary `#0A4096`, primary container `#2F59AF`, background `#F9F9FF`, ink `#121B2E`, white cards.
- Prose “Primary Blue #2F59AF” → container; Surface `#F7F9FC` not used.
- Lime `#BBD562` washes only; dark/success-on-light text — never low-contrast green on white.
- Fonts: Inter + Noto Sans Arabic; RTL via locale `ar`.

## Stitch priorities used

| Reference | Adaptation |
| --- | --- |
| premium_splash_and_session_routing_french | Blue splash brand + session restore routing |
| merchant_phone_login_french | Phone field + continue; FR copy |
| merchant_otp_verification_french | 6-digit OTP + resend cooldown |
| merchant_operational_dashboard_french | Branch name + operational badge; **no fabricated KPIs** |
| merchant_verification_*_french | Pending/rejected/suspended destinations from server status |

Broken Stitch exports (black/truncated/desktop spill) were not treated as pixel truth; HTML structure informed layout only.

## Captures (mocked Flutter widget tests)

All under `audit/phase-1/captures/`. Asserted route/content before `RepaintBoundary.toImage` via `tester.runAsync`. **Mocked, not live device.**

| File | Size / notes |
| --- | --- |
| `phone-se-375x667.png` | 375×667 phone |
| `phone-keyboard-se-375x667.png` | keyboard open |
| `otp-se-375x667.png` | OTP |
| `home-pro-402x874.png` | 402×874 home |
| `home-dense-se-text-1_3.png` | text scale 1.3 |

Live UI screenshots: **not taken** (no Merchant integration harness on device this pass). Live **API** smoke documented in `VALIDATION.md`.
