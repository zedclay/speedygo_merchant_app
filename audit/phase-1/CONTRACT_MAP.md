# Merchant Phase 1 — Contract map

Evidence date: 2026-09-17. Base path prefix: `/api/v1`. Sources: backend Nest controllers/DTOs + merchant app clients. Stitch/prior reports are context only.

## Auth (shared account auth — implemented & wired)

| Method | Path | Request | Response | Auth | States / errors | Side effects |
| --- | --- | --- | --- | --- | --- | --- |
| POST | `/auth/otp/request` | `{ channel: PHONE\|EMAIL, identifier, purpose: AUTHENTICATE }` | `{ accepted: true }` | public | `AUTH_RATE_LIMITED` (+ retry hints when present), validation | Creates OTP challenge; may write local OTP capture in dev |
| POST | `/auth/otp/verify` | `{ channel, identifier, purpose, code, platform: ios\|android\|web, appVersion }` | `{ accessToken, refreshToken, expiresIn, tokenType }` | public | `AUTH_INVALID_OTP`, expired/rate, validation (`platform` lowercase) | Issues session tokens |
| POST | `/auth/refresh` | `{ refreshToken }` | Token pair | public | revoked/expired refresh | Rotates refresh; ambiguous timeout handled client-side |
| POST | `/auth/logout` | (Bearer) | ack | Bearer | auth failures | Server revoke best-effort; client always clears local |
| GET | `/auth/me` | — | account + `profiles.hasMerchantMembership` | Bearer | auth/account blocked codes | Read-only |

**Client status:** Implemented in `AuthApi` / `SessionController`. Merchant secure-storage keys are merchant-only (not Customer). OTP verify default `platform` corrected to `ios` after live validation against backend enum.

## Merchant access (implemented & wired)

| Method | Path | Request | Response | Auth | States / errors | Side effects |
| --- | --- | --- | --- | --- | --- | --- |
| GET | `/merchant/me` | — | `{ merchantMembershipExists, memberships[] }` with role, readiness, verification flags, merchant status, branches | Bearer + merchant membership | empty membership; `MERCHANT_ROLE_FORBIDDEN`; auth failures | Read-only |
| POST | `/merchant/profile` | `{ name }` | membership view | Bearer | role/status restricted codes | Creates merchant profile (OWNER path) |
| POST | `/merchant/:merchantId/branches` | name, phone, addressText, lat/lng | branch | Bearer + role | role/status restricted | Creates branch |
| POST | `/merchant/:merchantId/verification/submit` | — | package/membership | Bearer OWNER | `verificationReady` gating | Formal submit |

**Routing used in Phase 1:** membership status `PENDING_REVIEW` / `!approved` → pending; `REJECTED` → rejected; `SUSPENDED` → suspended; no membership → onboarding shell; 0 branches → need branch; 1 active → auto-select home; many → picker. Local Owner/Operator UI never grants privileges.

## Home / orders read (partial)

| Method | Path | Request | Response | Auth | Notes |
| --- | --- | --- | --- | --- | --- |
| GET | `/merchant/:merchantId/orders?branchId&limit&offset` | query | `{ items: [...] }` summaries | Bearer + merchant scope | Wired for Orders tab only. Home does **not** invent metrics. |

## Verification document writes

| Method | Path | Status in Phase 1 |
| --- | --- | --- |
| GET/PUT/POST document metadata & bytes under `/merchant/:id/verification/...` | Present on backend | **Absent in Merchant app UI** — pending screen shows server checklist + honest gap copy; does not fake upload |

## Uncertain / not claimed

- Exact admin rejection-reason field (backend docs: no rejection reason in v1.0).
- Server-provided OTP cooldown seconds always present (client uses header/`retryAfterSeconds` when available, else 60s constant).
- Aggregate Home KPI endpoints: **absent** — UI states metrics unavailable rather than zeros.

## Report archive

`SpeedyGo-Merchant-Analyse-76-ecrans.md` was **not found** in the workspace. Stitch HTML lives under `screens/MerchantScreens/`.
