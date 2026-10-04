# Merchant Store Availability Foundation v1.0

Status: **ready for review** (not FINAL FREEZE). Consumes frozen Merchant Branch Opening Hours Foundation v1.0 (P1-F). Does not change `operationalStatus` or account approval semantics.

## Scope

In:

- Per-Branch availability override (`MerchantBranchAvailabilityOverride`)
- Modes: `FOLLOW_SCHEDULE`, `FORCE_CLOSED`, `TEMPORARY_CLOSED`
- Merchant GET/PUT `/api/v1/merchant/:merchantId/branches/:branchId/availability`
- Effective availability for Checkout Preview, Order create, and Customer storefront `isOpenNow`
- Closure reason vocabulary + optional customer message + `closedUntil`
- Timezone `Africa/Algiers` (same as opening hours)

Out:

- Changing Branch `operationalStatus` or Merchant approval as open/closed
- Holiday / exceptional hours calendars
- Customer UI changes
- Auto-claiming the store is open when a temporary closure expires

## Separation of concerns

| Concept | Meaning |
| --- | --- |
| Merchant approval / `verifiedAt` | Account may operate on the platform |
| Branch `operationalStatus` | Platform eligibility (`ACTIVE` / `INACTIVE` / `SUSPENDED`) |
| Weekly opening hours | Recurring schedule window |
| Availability override | Merchant pause / force-close / resume schedule |

These are independent. A Branch may be `ACTIVE` and still Fermé because of hours or an override.

## Precedence (accepting new orders)

1. Merchant approved + Branch `operationalStatus=ACTIVE` (existing errors).
2. Active override: `FORCE_CLOSED` → closed. `TEMPORARY_CLOSED` while `now < closedUntil` → closed.
3. Expired `TEMPORARY_CLOSED` (`now >= closedUntil`) is treated as `FOLLOW_SCHEDULE` **in memory on GET/eval** — never implies open by itself.
4. Weekly opening hours evaluation (P1-F half-open rules). Missing schedule → `*_HOURS_NOT_CONFIGURED`.

Since the opening hours exceptions foundation (2026-10-02), step 4 first applies the hours exception for the current `Africa/Algiers` date when one exists, and falls back to the weekly schedule otherwise. Steps 1–3 and the error codes are unchanged. See [MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md](./MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md).

Existing in-flight Orders are unchanged; Merchant preparation continues.

## Expiry and persistence

- **GET / evaluate:** expired temporary overrides do **not** write the database.
- **PUT / optional cleanup:** may clear an expired temporary row only when `version` still matches and the row is still expired — never erase a newer closure.
- Clock authority: same server clock used for opening hours (`CHECKOUT_CLOCK` on Checkout/Order).

## `closedUntil` vs `nextOpenAt`

| Field | Meaning |
| --- | --- |
| `closedUntil` | Override expiry (temporary only). Not a promise the store is open then. |
| `nextOpenAt` | Next instant the Branch would accept orders under effective rules |
| `FORCE_CLOSED` | `nextOpenAt = null` (do not advertise schedule reopen) |
| Active `TEMPORARY_CLOSED` | `nextOpenAt` = first open window at/after `closedUntil` under hours, or null |
| `FOLLOW_SCHEDULE` / expired temp | Existing hours-derived `nextOpenAt` |

## Modes and validation

| Mode | `closedUntil` | Reasons / message |
| --- | --- | --- |
| `FOLLOW_SCHEDULE` | must be null | reason/message cleared |
| `FORCE_CLOSED` | must be null | reason/message optional |
| `TEMPORARY_CLOSED` | required, strictly future on PUT | reason recommended; message optional |

Reason codes: `PEAK_KITCHEN`, `TECHNICAL`, `OUT_OF_STOCK`, `LUNCH_BREAK`, `OTHER`.

Optimistic concurrency: `expectedVersion` (`0` creates). Conflict → `AVAILABILITY_VERSION_CONFLICT` with current state; clients reload; never silent overwrite.

## Merchant UI semantics

- `FOLLOW_SCHEDULE` displays as **Selon les horaires**, not Ouvert.
- **Ouvert / Fermé** badges use server `isOpenNow` / `acceptingOrders` only.
- Manual reopen → `FOLLOW_SCHEDULE`. If outside weekly hours, warn before confirm that the store stays Fermé until hours open.
- Saves are confirmed only after PUT 200.

## Customer contract

Existing projection fields keep names. `isOpenNow` means **effective** accepting-orders (override + hours). Additive optional fields may appear; Customer UI unchanged.

## Checkout / Order

Reuse `CHECKOUT_BRANCH_CLOSED` / `ORDER_BRANCH_CLOSED` when an active override closes the Branch. Order create **re-evaluates** at placement time even if Checkout preview earlier returned open.

See [MERCHANT_STORE_AVAILABILITY.md](../business-rules/MERCHANT_STORE_AVAILABILITY.md).
