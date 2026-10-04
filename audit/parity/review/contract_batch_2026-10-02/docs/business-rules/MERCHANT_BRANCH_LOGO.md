# Merchant branch logo — business rules

Companion to [MERCHANT_BRANCH_LOGO_FOUNDATION.md](../architecture/MERCHANT_BRANCH_LOGO_FOUNDATION.md).

## Ownership

- A logo belongs to one MerchantBranch (at most one per Branch). It is not a Merchant-wide asset; Branches of the same Merchant may differ.
- The logo is independent of the storefront cover, product images and verification documents. Changing one never changes the others.

## Roles

| Action | OWNER | MANAGER | STAFF |
| --- | --- | --- | --- |
| View | yes | yes | yes |
| Upload / replace / remove | yes | yes | no (`403 MERCHANT_ROLE_FORBIDDEN`) |

## Media lifecycle

1. Upload: the bytes are validated (JPEG or PNG, ≤ 1 MiB, 128–2048 px per side, malware scan as for covers) and held as a pending upload bound to the Account, Branch and purpose `MERCHANT_BRANCH_LOGO`.
2. Bind: the pending upload is promoted to a new `logos/` object and recorded on the Branch. A reference can be bound once; references issued for covers or product images are refused.
3. Replace: a bind on a Branch that already has a logo writes a new object and then deletes the previous object if nothing references it. The served bytes change immediately (new `ETag`).
4. Remove: deletes the record and then the object if unreferenced. Removing an absent logo succeeds (idempotent).
5. Read: authenticated Merchant members of the Branch only, `Cache-Control: private, no-cache`. There is no public or Customer logo URL.

A failed bind leaves the previous logo in place and deletes the newly promoted object. The Merchant app shows "saved" only after the bind succeeds.

## Not in scope

- Customer display of the logo (no Customer projection field).
- Admin moderation of logos.
- Server-side cropping or resizing.
