# Merchant Staff Management Completion Report

**Environment:** `fxenv_20261004T030139Z` · `speedygo_parity_fx` · API `:3100` · Redis index **9**  
**Row:** **64** `staff_and_account_access_french`  
**Stitch:** `screens/MerchantScreens/staff_and_account_access_french`  
**Status:** `implementer_reviewed` (not `user_accepted`)  
**Migration:** `20261004T0330_merchant_team_management` (additive; applied **only** to `speedygo_parity_fx`)

## Permission matrix (final)

| Action | OWNER | MANAGER | STAFF |
| --- | --- | --- | --- |
| List roster + pending invites | Yes | Yes (read) | No → 403 |
| Create / cancel / regenerate invite | Yes | No | No |
| Change role MANAGER ↔ STAFF | Yes | No | No |
| Revoke MANAGER/STAFF | Yes | No | No |
| Assign / mutate OWNER | No | No | No |
| Self-revoke / self-demote | No | No | No |
| Accept invite for own verified phone | Any authenticated Account with matching phone | | |

Capabilities: `TEAM_READ` = OWNER+MANAGER · `TEAM_MANAGE` = OWNER.

Branch scope: merchant-wide only (`ALL_MERCHANT_BRANCHES`). Client `branchId`/`branchIds` rejected.

## Membership / invitation lifecycle

1. OWNER creates invite → `MerchantMemberInvitation` PENDING + SHA-256 `tokenHash`; response includes one-time `acceptCode` for **manual share** (UI never claims SMS/email sent).
2. Invitee authenticates with that phone → `GET /merchant/me/team-invitations` → accept with code → `MerchantMember` created; invite ACCEPTED (single-use).
3. Accounts without membership reach invitations via `/access/team-invitations` (registration “Opérateur” / no-membership CTA).
4. Revoke deletes only that Merchant’s membership; Account and other Merchants preserved.
5. Demote or revoke → `SessionService.revokeAllSessionsForAccount` for the target; next protected request → `AUTH_SESSION_REVOKED`.

## Domain / ERD / API / Prisma

- Docs: `docs/architecture/MERCHANT_TEAM_MANAGEMENT.md`
- Prisma: `MerchantMember.version` + `updatedAt`; new `MerchantMemberInvitation`
- Migration id: `20261004T0330_merchant_team_management`  
  Snapshot: `4ff87496…` → `5a6c3e70…`  
  Scope: **speedygo_parity_fx only** (`merchant_member_invitations` count on `speedygo_dev` = **0**)

## Verification table

| Suite | Result | Count |
| --- | --- | --- |
| Backend unit `merchant-team.service.spec.ts` | PASS | 55/55 |
| Flutter `merchant_team_test.dart` | PASS | 40/40 |
| Flutter mocked capture `batch6_team_capture_test.dart` | PASS | 6/6 |
| Isolated API e2e `fx_team_e2e` | PASS | **45/45** |
| Isolated live iPhone 16e text 1.0 | PASS | 1/1 |
| Isolated live iPhone 16e text 1.35 | PASS | 1/1 |
| `speedygo_dev` writes / migration | PASS | unchanged (0 createdSince; invitation table absent) |

## Evidence

### Mocked
- `audit/parity/mocked/b6_team_{top,end,invite_sheet}_{w390,w375_t135}.png`
- Comparisons: `audit/parity/comparisons/b6_team_*.png`

### Live (isolated)
- Screens: `team_visual/screens/fxteam_t100_*`, `fxteam_t135_*`
- Comparisons: `audit/parity/comparisons/live/fxteam_*.png`

### Remaining visual differences vs Stitch
- Person display names → Account phone (no name contract)
- Presence / “Actif maintenant” omitted
- Role labels: Propriétaire / Gestionnaire / Équipe (not Stitch Opérateur / Gestionnaire catalogue)
- No SMS “Renvoyer”; regenerate exposes a new shareable code

## Parity recalculation

**72/77 closed (93.5%)** · 5 unfinished  
Counts: **59 done · 2 partial · 1 blocked · 2 deferred · 8 exceptions · 5 duplicates**  
Bottom Navigation V1 remains `user_accepted`. Daily Summary / Delayed Order / Bottom Nav untouched.

## Review ZIP

Path: `audit/parity/review/merchant_team_management_close_2026-10-04_review.zip`  
SHA-256: `d89db5bf40b16b3aacc351e387f69c0754d0f83a04bc961a117d325f63dfc109`
