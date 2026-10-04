# Merchant Phase 1 — Validation

## Commands

```bash
cd apps/merchant_app
flutter analyze
# → 14 info issues (prefer_const_*, prefer_initializing_formals). Exit 0. No errors/warnings.

flutter test test/ --concurrency=1
# → 00:06 +14: All tests passed!
```

## Test coverage (mocked)

- Cold start → phone
- OTP cooldown / duplicate request block
- Auth failure clears session → signed out
- No membership / single branch / multi branch / permission denied / pending review
- Branch-scoped orders + generation isolation
- Home empty metrics copy + tab navigation
- Orders error AsyncValue
- PhoneInput unit
- Mocked captures (phone, keyboard, OTP, home 402×874, text scale 1.3)

Skipped: none in this suite.

## Live API smoke (not Flutter UI)

Backend `http://127.0.0.1:3000` available. Existing synthetic merchant phone used (no new business rows created).

- `POST /auth/otp/request` → `accepted: true`
- `POST /auth/otp/verify` with `platform: ios` → tokens (`expiresIn=900`) — tokens not logged
- `GET /auth/me` → ACTIVE, `hasMerchantMembership=true`
- `GET /merchant/me` → 1 OWNER membership, ACTIVE, 1 ACTIVE branch
- `GET /merchant/:id/orders` → `{ items: [], limit, offset, total }`

Live Flutter device/simulator Merchant journey screenshots: **not run** this pass.

## Manual steps (operator)

1. `flutter run` Merchant app against local API.
2. Sign in with an authorized merchant phone; complete OTP.
3. Confirm single-branch auto-home vs multi-branch picker.
4. Confirm pending/rejected/suspended accounts never reach Home.
5. Confirm Catalog/Reports show soon copy; Orders empty vs list from API.
6. Logout clears session; cold restart does not restore revoked tokens.
