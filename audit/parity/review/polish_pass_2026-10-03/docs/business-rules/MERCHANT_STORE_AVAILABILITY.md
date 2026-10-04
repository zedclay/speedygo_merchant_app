# Merchant store availability rules

Companion to [MERCHANT_STORE_AVAILABILITY_FOUNDATION.md](../architecture/MERCHANT_STORE_AVAILABILITY_FOUNDATION.md).

## Timezone

All civil presets (e.g. “aujourd’hui 15:30”) use IANA **`Africa/Algiers`**, same as opening hours. `closedUntil` is stored as an absolute timestamptz.

## Effective acceptingOrders

```
platformEligible AND NOT forceClosed AND NOT activeTemporaryClosed AND hoursConfigured AND isOpenNow(hours)
```

Expired temporary closed → evaluate as following schedule (hours only).

`isOpenNow(hours)` applies the hours exception for the current `Africa/Algiers` date when one exists, then the weekly schedule ([MERCHANT_OPENING_HOURS_EXCEPTIONS.md](./MERCHANT_OPENING_HOURS_EXCEPTIONS.md)). Overrides still win.

## Customer discovery

Storefronts remain browseable when closed (same as hours foundation). Checkout and Order create are authoritative for placement. List filter `openNow=true` must exclude Branches with an active force/temporary closure as well as those outside hours.

## Error codes

| Situation | Checkout | Order |
| --- | --- | --- |
| Active override closed | `CHECKOUT_BRANCH_CLOSED` | `ORDER_BRANCH_CLOSED` |
| Hours missing | `CHECKOUT_BRANCH_HOURS_NOT_CONFIGURED` | `ORDER_BRANCH_HOURS_NOT_CONFIGURED` |
| Hours closed | `CHECKOUT_BRANCH_CLOSED` | `ORDER_BRANCH_CLOSED` |

Merchant PUT validation: `AVAILABILITY_INVALID`. Concurrency: `AVAILABILITY_VERSION_CONFLICT`.
