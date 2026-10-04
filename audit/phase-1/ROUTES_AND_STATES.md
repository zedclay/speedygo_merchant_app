# Merchant Phase 1 — Routes and state handling

## Session phases → routes

| SessionPhase | AccessDestination (when resolving) | Route |
| --- | --- | --- |
| `boot` | — | `/` splash |
| `restoring` / `restoreRetryable` | — | `/restore` |
| `signedOut` | — | `/language` if unseen else `/phone` |
| `awaitingOtp` | — | `/otp` |
| `resolvingAccess` | `loading` | `/access/loading` |
| | `error` | `/access/error` |
| | `noMembership` | `/access/none` |
| | `verificationPending` | `/verification/pending` |
| | `verificationRejected` | `/verification/rejected` |
| | `verificationSuspended` | `/verification/suspended` |
| | `needBranch` | `/access/need-branch` |
| | `selectBranch` | `/access/select-branch` |
| | `permissionDenied` | `/access/denied` |
| | `home` | `/app/home` (+ `markAccessReady`) |
| `ready` | — | `/app/*` shell only |

Failed auth (`AUTH_SESSION_*`, blocked account) clears tokens, merchant/branch context, and generation → `signedOut`. No Home shell while rejected.

## Shell tabs

`Accueil` `/app/home` · `Commandes` `/app/orders` · `Catalogue` `/app/catalog` (honest soon) · `Rapports` `/app/reports` (honest soon) · `Profil` `/app/profile`.

## Isolation

- Context store: merchantId + branchId scoped with session clear on logout.
- Orders provider generation + account/merchant/branch checks drop stale responses.
- Token refresh: single-flight `TokenRefresher`, persisted rotation, session epoch invalidation (Customer principles, merchant-owned storage).
