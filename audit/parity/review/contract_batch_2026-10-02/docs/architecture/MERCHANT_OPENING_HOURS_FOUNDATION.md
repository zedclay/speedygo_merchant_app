# Merchant Branch Opening Hours Foundation v1.0

Status: **FINAL FROZEN** (P1-F Merchant Branch Opening Hours Foundation v1.0).

## Scope

In:

- Per-Branch weekly opening schedule (`MerchantBranchOpeningSchedule` + `MerchantBranchOpeningInterval`)
- Merchant GET/PUT under `/api/v1/merchant/:merchantId/branches/:branchId/opening-hours`
- Customer storefront projection fields (`hoursConfigured`, `isOpenNow`, `timezone`, `currentClosesAt`, `nextOpenAt`; detail includes public weekly days)
- Checkout Preview and Order create fail-closed when hours missing or currently closed
- Timezone `Africa/Algiers` via Intl (IANA); half-open intervals `[open, close)`
- Optimistic concurrency via `expectedVersion` (`0` creates)

Out:

- Temporary closures / holiday calendars (see later [MERCHANT_STORE_AVAILABILITY_FOUNDATION.md](./MERCHANT_STORE_AVAILABILITY_FOUNDATION.md) for Merchant pause / force-close)
- Per-day timezone overrides
- Admin CRUD for hours
- Changing Branch `operationalStatus` semantics (still separate from hours)
- Float money / financial formulas

**Related:** Per-date exceptions ([MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md](./MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md)) replace the weekly schedule only on their own `Africa/Algiers` dates; the weekly rules in this document are unchanged. Store availability overrides compose **on top of** this foundation. `isOpenNow` on Customer projections is the **effective** accepting-orders signal (override + hours). This P1-F document remains frozen for weekly schedule rules.

## Schema

- `MerchantBranchOpeningSchedule`: 1:1 with `MerchantBranch` (`branchId` unique), `version >= 1`, `updatedByAccountId`
- `MerchantBranchOpeningInterval`: day ISO 1..7, minutes 0..1439, `closesNextDay`, `sortOrder`, cascade delete with schedule
- Additive migration only

## Capabilities

| Method | Capability |
| --- | --- |
| GET | `MERCHANT_READ` |
| PUT | `MERCHANT_BRANCH_UPDATE` |

Foreign merchant/branch → `MERCHANT_NOT_FOUND` / `MERCHANT_BRANCH_NOT_FOUND` (no existence leak beyond existing Merchant patterns).

## Evaluation rules

- Missing schedule ⇒ `hoursConfigured=false`; Checkout/Order reject with `*_BRANCH_HOURS_NOT_CONFIGURED`
- Configured with all empty days ⇒ always closed (`hoursConfigured=true`)
- Half-open: exact open = open; exact close = closed
- Overnight: `closesNextDay=true`; 24h: `00:00→00:00` with `closesNextDay=true`
- `currentClosesAt` extends through adjacent continuous intervals
- `nextOpenAt` scans ≤ ~7 local days; null when open or always closed
- One `CHECKOUT_CLOCK.now()` per Checkout/Order request for hours + pricing

## Checkout / Order errors (409)

- `CHECKOUT_BRANCH_CLOSED` / `ORDER_BRANCH_CLOSED`
- `CHECKOUT_BRANCH_HOURS_NOT_CONFIGURED` / `ORDER_BRANCH_HOURS_NOT_CONFIGURED`

Still require Merchant approved + Branch `operationalStatus=ACTIVE`.

## Customer catalog

Batch-load schedules (no N+1). List/search get hours projection; detail may include public weekly days (no version, actor, or interval ids).

See [MERCHANT_OPENING_HOURS.md](../business-rules/MERCHANT_OPENING_HOURS.md).
