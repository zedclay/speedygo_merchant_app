# Merchant registration / verification — contract map

**Scope:** Merchant app only. Backend inspected read-only. Phase 2 order ops paused.  
**API prefix:** `/api/v1` · Auth: Bearer ACTIVE Account.

## Pre-approval writability (OWNER)

| Action / field | PENDING (not submitted) | Submitted PENDING | REJECTED | ACTIVE |
| --- | --- | --- | --- | --- |
| `POST /merchant/profile` `{name}` | create once | n/a | n/a | n/a |
| `PATCH .../profile` `{name}` | yes | no | yes | no |
| Evidence upload+bind | yes | no | yes | no |
| `POST .../verification/submit` | if ready | no | if ready (resubmit) | no |
| Branch CRUD (name, phone, addressText, lat, lng) | yes | yes | yes | yes* |
| Commerce vertical | **no** (admin only) | admin | admin | admin |

\* ACTIVE must keep ≥1 branch.

## Field / action matrix (reference → contract)

| Screen / UI meaning | Entity | Read | Write | Before approval? | Class |
| --- | --- | --- | --- | --- | --- |
| Owner full name | — | — | — | — | **missing backend** |
| Owner email | — | — | — | — | **missing backend** |
| Role Propriétaire / Opérateur | membership.role | GET `/merchant/me` | create OWNER only | create | **supported** (owner create); operator join **missing** (no invite API) |
| Verified login phone | Account | auth/me `account.phone` | OTP change only | read-only | **supported** read-only |
| Business / branch phone | Branch | me.branches[].phone | POST/PATCH branch | yes | **supported** (labeled distinct) |
| Merchant name | Merchant | me.merchant.name | POST/PATCH profile | conditional | **supported** |
| Translated name (AR) | — | — | — | — | **missing backend** |
| Description | — | — | — | — | **missing backend** |
| NIF as typed field | — | — | — | — | **missing backend** (use evidence docs) |
| Category / vertical | BranchClassification | admin | admin PUT classification | no merchant write | **missing merchant contract** |
| Address text | Branch | branches[].addressText | POST/PATCH | yes | **supported** |
| Coordinates | Branch | lat/lng | POST/PATCH | yes | **supported** (manual; map **missing external config**) |
| Pickup instructions | — | — | — | — | **missing backend** (fold into address) |
| BUSINESS_IDENTITY / REGISTRATION / SUPPORTING | Evidence | checklist on me | multipart content + PUT bind | conditional | **supported** |
| Terms / privacy consent | — | — | — | — | **missing backend** |
| Submit / resubmit | Merchant | flags | POST submit | conditional | **supported** |
| Rejection reason text | — | status only | admin reject empty | — | **missing backend** |

## Evidence pipeline

1. `POST /merchant/:id/verification/documents/:type/content` multipart `file` → `{uploadReference, contentType, sizeBytes, purpose}`  
2. `PUT /merchant/:id/verification/documents/:type` `{uploadReference, expiryDate?}`  
3. Refresh via `GET /merchant/me`  
Limits: PDF/JPEG/PNG, ≤10 MiB. No arbitrary URL upload with bearer.

## Minimal extensions needed for blocked Stitch fields

1. Account/owner profile fields (name, email) **or** document that they stay out of merchant onboarding.  
2. Merchant invite/accept for Opérateur.  
3. Merchant-writable vertical **or** keep admin-only with honest UI.  
4. Map/geocoder config + confirm API.  
5. Rejection reason persistence returned on GET verification.  
6. Consent persistence if legally required.
