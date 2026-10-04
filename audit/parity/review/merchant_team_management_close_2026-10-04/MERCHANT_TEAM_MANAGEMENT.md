# SpeedyGo Merchant Team Management v1.0

Additive Team Management foundation for Merchant roster, invitations and access
revocation. Closes parity row **64** `staff_and_account_access_french`.

Owner: `apps/backend/src/modules/merchants` (`MerchantTeamService`).
Consumer: `apps/merchant_app` Personnel et Accès screen.

Does **not** invent: person display names, presence/last-activity, branch-scoped
ACLs, SMS/email delivery, OWNER transfer, or Stitch “Opérateur / Gestionnaire
catalogue” role splits. Backend roles remain `OWNER` | `MANAGER` | `STAFF`.

## Permission matrix (final)

| Action | OWNER | MANAGER | STAFF |
| --- | --- | --- | --- |
| `GET …/team` list members + pending invites | Yes | Yes (read) | **No** → 403 `MERCHANT_ROLE_FORBIDDEN` |
| Create invite (`MANAGER`/`STAFF` only) | Yes | No | No |
| Cancel / regenerate invite code | Yes | No | No |
| Change member role `MANAGER` ↔ `STAFF` | Yes | No | No |
| Revoke `MANAGER`/`STAFF` membership | Yes | No | No |
| Assign / mutate `OWNER` | **No** | No | No |
| Self-revoke / self-demote via team APIs | **No** | No | No |
| Accept invite for **own** verified phone | Any authenticated Account whose phone matches the invite | | |

Capabilities (additive):

| Capability | Roles |
| --- | --- |
| `TEAM_READ` | OWNER, MANAGER |
| `TEAM_MANAGE` | OWNER |

Safe defaults match the brief. No silent broadening of MANAGER/STAFF powers.

## Branch scope

`MerchantMember` is **merchant-wide** (not branch-scoped). Responses expose
`branchScope: "ALL_MERCHANT_BRANCHES"`. There is no per-branch assignment UI or
API in this batch. Client-supplied `branchId` lists are rejected.

## Membership lifecycle

- List active `MerchantMember` rows for the Merchant (phone from `Account`, role, `createdAt`, `version`).
- Revoke = delete that Merchant’s `MerchantMember` row only. Global `Account` and other Merchants’ memberships stay.
- Historical Order/status attribution remains via `accountId` on events (no cascade delete of history).
- Unique `(merchantId, accountId)` prevents duplicate memberships.
- Optimistic concurrency: `MerchantMember.version` / `MerchantMemberInvitation.version`; stale → 409.
- After revoke or role change that removes privileges: `SessionService.revokeAllSessionsForAccount` for the target account (same pattern as Admin suspend). Next protected request requires re-auth; other Merchants remain joinable after login.

## Invitation lifecycle (no SMS/email)

1. OWNER `POST …/team/invitations` with E.164 phone + role `MANAGER`|`STAFF`.
2. Server stores `MerchantMemberInvitation` (`PENDING`), `tokenHash` only.
3. Response includes **one-time** plaintext `acceptCode` for manual share. UI must **not** claim “invitation sent”.
4. Duplicate active (`PENDING`, unexpired) invite for same `(merchantId, phone)` → 409.
5. Invitee authenticates with that phone (existing OTP). `GET /merchant/me/team-invitations` lists pending invites for their phone. `POST /merchant/me/team-invitations/:id/accept` with `acceptCode` creates `MerchantMember` and marks invite `ACCEPTED` (single-use).
6. OWNER may cancel (`CANCELLED`) or regenerate code (new hash/version; still no delivery).
7. Expiry: `expiresAt` (default 7 days). Expired treated as not acceptable; list may show `EXPIRED` or omit.

Secrets: never log `acceptCode` or raw token. Hash with existing crypto helpers (SHA-256 of random 32 bytes).

## Routes

| Method | Path | Capability |
| --- | --- | --- |
| GET | `/api/v1/merchant/:merchantId/team` | TEAM_READ |
| POST | `/api/v1/merchant/:merchantId/team/invitations` | TEAM_MANAGE |
| POST | `/api/v1/merchant/:merchantId/team/invitations/:invitationId/cancel` | TEAM_MANAGE |
| POST | `/api/v1/merchant/:merchantId/team/invitations/:invitationId/regenerate-code` | TEAM_MANAGE |
| PATCH | `/api/v1/merchant/:merchantId/team/members/:memberId` | TEAM_MANAGE |
| DELETE | `/api/v1/merchant/:merchantId/team/members/:memberId` | TEAM_MANAGE |
| GET | `/api/v1/merchant/me/team-invitations` | Authenticated (phone-bound) |
| POST | `/api/v1/merchant/me/team-invitations/:invitationId/accept` | Authenticated (phone-bound) |

## Error codes

| Code | When |
| --- | --- |
| `MERCHANT_NOT_FOUND` | Foreign merchant / no membership for TEAM_READ |
| `MERCHANT_ROLE_FORBIDDEN` | Capability missing |
| `TEAM_INVALID_INPUT` | Bad phone/role/body |
| `TEAM_OWNER_PROTECTED` | Target is OWNER or assign OWNER |
| `TEAM_SELF_FORBIDDEN` | Self revoke/demote |
| `TEAM_DUPLICATE_MEMBER` | Already a member |
| `TEAM_DUPLICATE_INVITE` | Pending invite exists |
| `TEAM_INVITE_NOT_FOUND` | Unknown/cancelled invite |
| `TEAM_INVITE_EXPIRED` | Past `expiresAt` |
| `TEAM_INVITE_CODE_INVALID` | Bad accept code |
| `TEAM_PHONE_MISMATCH` | Accept phone ≠ invite phone |
| `TEAM_VERSION_CONFLICT` | Stale version |

## UI mapping (truthful)

| Stitch | App |
| --- | --- |
| Person name | Phone (Account.phone); no fabricated name |
| Admin / Opérateur / Gestionnaire catalogue | Propriétaire / Gestionnaire / Équipe (`OWNER`/`MANAGER`/`STAFF`) |
| Actif maintenant / Dernière activité | Omitted (no contract) |
| Renvoyer | « Régénérer le code » (no SMS) |
| Inviter FAB | Create invite sheet → show shareable code |
| Role summary cards | Capability summary from real `roleHasCapability` truths |
