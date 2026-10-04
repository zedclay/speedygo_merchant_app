# Route / state map

## Signed-out (unchanged)
`/` splash → `/language?` → `/onboarding?` → `/phone` → `/otp`

## Post-OTP (`SessionPhase.resolvingAccess`)

| Condition | Destination | Route |
| --- | --- | --- |
| No membership | `noMembership` → UI registration | `/access/registration` |
| PENDING_REVIEW && !verificationSubmitted | `registration` | `/access/registration` |
| PENDING_REVIEW && verificationSubmitted | `verificationPending` | `/verification/pending` |
| REJECTED | `verificationRejected` (+ correct → registration) | `/verification/rejected` |
| SUSPENDED | `verificationSuspended` | `/verification/suspended` |
| ACTIVE, 0 branches | `needBranch` | `/access/need-branch` |
| ACTIVE, 1 branch | `home` + ready | `/app/home` |
| ACTIVE, many branches | `selectBranch` | `/access/select-branch` |

## Registration wizard steps (local)
account → activity → documents → establishment → review → submit → resolve()

Create merchant **once** on activity save; reconcile `GET /merchant/me` before create. Drafts in memory scoped to account; cleared on logout/account change. Document bytes not persisted to preferences.

## Finjan / existing memberships
Approved → home/branch gates. Incomplete → resume with server prefills (no recreate, no empty overwrite). Operator choice never grants role.
