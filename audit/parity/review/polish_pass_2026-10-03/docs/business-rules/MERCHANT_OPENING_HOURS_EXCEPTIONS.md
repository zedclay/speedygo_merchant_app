# Merchant opening hours exceptions — business rules

Companion to [MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md](../architecture/MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md).

## What an exception is

A Branch-scoped replacement of the weekly schedule for one `Africa/Algiers` civil date. It either closes the Branch for the whole date or opens it only during 1–3 same-day intervals. It does not change the weekly schedule, the availability override, `operationalStatus` or Merchant approval.

## Effective acceptingOrders

```
platformEligible
AND NOT forceClosed AND NOT activeTemporaryClosed
AND weeklyHoursConfigured
AND openAt(now) where, for the local date of now:
      exception exists → its intervals (none when closed)
      otherwise        → weekly intervals, including the previous date's
                         overnight spill unless that date or today has an exception
```

## Boundaries

- Midnight belongs to the new date. An exception on date D starts governing at D 00:00 local.
- `closes=00:00` in an exception means 24:00 of the same date; nothing continues after midnight.
- Overnight exception intervals are refused; use two dates.
- The exact opening minute is open; the exact closing minute is closed.

## Precedence

Platform eligibility, then an active `FORCE_CLOSED` / `TEMPORARY_CLOSED` override, then today's exception, then the weekly schedule. `FOLLOW_SCHEDULE` never reopens a date that an exception closes. An exception never configures hours: without a weekly schedule the Branch stays `*_HOURS_NOT_CONFIGURED`.

## Concurrency and roles

- Each exception has an integer `version`. PUT sends `expectedVersion` (`0` to create); DELETE sends it as a query parameter. A mismatch returns `409 OPENING_HOURS_EXCEPTION_VERSION_CONFLICT` with the current row in `error.openingHoursException` (or `null`), and nothing is written.
- `(branch_id, local_date)` is unique, so two simultaneous creates for one date produce one row.
- The Merchant app reloads the list on a conflict and keeps the unsaved draft.
- OWNER and MANAGER edit. STAFF reads the list only (`403 MERCHANT_ROLE_FORBIDDEN` on PUT/DELETE).

## Ranges

The reference shows "21 - 22 Avril" as one card. This contract stores one exception per date; a multi-day closure is entered date by date. The Merchant screen therefore remains **partial by decision** against that reference.

## Errors

| Situation | Code |
| --- | --- |
| Checkout / Order while an exception closes the Branch | `CHECKOUT_BRANCH_CLOSED` / `ORDER_BRANCH_CLOSED` |
| Weekly hours missing | `CHECKOUT_BRANCH_HOURS_NOT_CONFIGURED` / `ORDER_BRANCH_HOURS_NOT_CONFIGURED` |
| Invalid exception | `OPENING_HOURS_EXCEPTION_INVALID` (structurally malformed body: `VALIDATION_ERROR`) |
| Stale version / date already taken | `OPENING_HOURS_EXCEPTION_VERSION_CONFLICT` |
| Unknown date on delete | `OPENING_HOURS_EXCEPTION_NOT_FOUND` |
| No weekly schedule yet | `OPENING_HOURS_EXCEPTION_WEEKLY_REQUIRED` |
