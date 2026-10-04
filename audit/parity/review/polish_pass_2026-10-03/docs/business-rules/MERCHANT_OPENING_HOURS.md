# Merchant Branch Opening Hours — business rules (P1-F v1.0)

## Hours ≠ operational status

Branch `operationalStatus=ACTIVE` means the Branch is eligible for Catalog/Checkout in the Merchant foundation sense. It does **not** mean the store is open at this moment. Opening hours are a separate weekly schedule gate.

## Timezone

All civil-day evaluation uses IANA `Africa/Algiers` via `Intl`. Do not hardcode UTC+1 arithmetic as the sole conversion method.

## Schedule shape

PUT requires exactly seven unique ISO weekdays (1=Mon … 7=Sun). Empty `intervals` for a day means closed that day. All empty days means configured always closed. Missing schedule means hours are not configured.

## Interval semantics

- Times are strict `HH:mm`.
- Same-day: `closes > opens` ⇒ `closesNextDay=false`.
- Overnight: `closes < opens` ⇒ `closesNextDay=true`.
- 24h: `00:00→00:00` ⇒ `closesNextDay=true`.
- Max 3 intervals per day, 21 total.
- Overlaps across the circular week are rejected; adjacent half-open intervals are allowed.

## Checkout and Order

Customer Checkout Preview and Order create require:

1. Hours configured
2. Currently open under half-open evaluation
3. Branch operationally ACTIVE (and Merchant approved)

Missing hours and closed hours are distinct 409 codes. Cancellation is not a refund; hours checks do not invent refunds.

## Customer discovery

Storefront responses may show open/closed projection for UX. Checkout remains the authority for placing an order. Discovery fields must not invent delivery fee, ETA, or distance.
