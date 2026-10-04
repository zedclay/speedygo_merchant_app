# Merchant Opening Hours Exceptions Foundation v1.0

Status: **implemented 2026-10-02, `implementer_reviewed`** (not FINAL FREEZE, not visually accepted). Migration `migrations/app/20261002T1907_merchant_contract_completion_batch`. Composes with the frozen weekly schedule ([MERCHANT_OPENING_HOURS_FOUNDATION.md](./MERCHANT_OPENING_HOURS_FOUNDATION.md)) and the availability override ([MERCHANT_STORE_AVAILABILITY_FOUNDATION.md](./MERCHANT_STORE_AVAILABILITY_FOUNDATION.md)). Weekly-schedule rules are unchanged.

## Scope

In:

- Per-Branch, per-date exceptions (`MerchantBranchHoursException` + `MerchantBranchHoursExceptionInterval`)
- Merchant GET / PUT / DELETE under `/api/v1/merchant/:merchantId/branches/:branchId/opening-hours/exceptions`
- The same server-side evaluation for Checkout Preview, Order create, Merchant effective availability, Customer `isOpenNow` and the Customer `openNow=true` list filter
- Merchant app "Horaires exceptionnels" screen (24-hour format)

Out:

- Multi-date ranges in one record (a range is one exception per date)
- Overnight exception intervals
- Customer display of the label or customer message (stored only; Customer UI out of scope)
- Recurring annual holidays

## Precedence (accepting new orders)

1. Platform eligibility: Merchant approved and Branch `operationalStatus=ACTIVE` (existing errors).
2. Active availability override: `FORCE_CLOSED`, or `TEMPORARY_CLOSED` while `now < closedUntil` → closed.
3. Hours exception for the current `Africa/Algiers` civil date → closed all day, or open only inside its intervals.
4. Weekly schedule for that date. Missing weekly schedule → `*_HOURS_NOT_CONFIGURED` (exceptions do not configure hours).

## Civil-date semantics

- An exception governs its whole civil date `[00:00, 24:00)` in `Africa/Algiers`.
- A weekly overnight interval that starts the previous date stops at the exception date's 00:00.
- Exception intervals never spill into the next date. `closes = 00:00` means "until midnight" (stored `closesNextDay=true`, `closesMinute=0`); `00:00 → 00:00` means open all day.
- Dates without an exception use the weekly schedule unchanged.
- Half-open evaluation as for weekly hours: exact open = open, exact close = closed. Adjacent intervals are continuous for `currentClosesAt`.

## Validation (`400 OPENING_HOURS_EXCEPTION_INVALID`)

Domain rules below return `400 OPENING_HOURS_EXCEPTION_INVALID`. Structurally malformed bodies (missing `closed`, non-boolean `closed`, non-array `intervals`, non-integer `expectedVersion`) are rejected earlier by the DTO with the standard `400 VALIDATION_ERROR`.

| Field | Rule |
| --- | --- |
| `:date` | Strict `YYYY-MM-DD`, a real calendar date (year ≥ 2000), from today to today + 365 days (`Africa/Algiers`) |
| `expectedVersion` | PUT: integer ≥ 0 (`0` = create). DELETE query: integer ≥ 1 |
| `closed` | Boolean. `true` requires `intervals: []` |
| `intervals` | When open: 1–3 items, strict `HH:mm`, `opens < closes` (or `closes=00:00` = midnight), sorted on save, no overlaps (adjacent allowed). Zero-length (`opens = closes`, except `00:00 → 00:00` = full day) and overnight (`closes < opens`) are rejected |
| `label` | Required, trimmed, 1–80 characters |
| `customerMessage` | Optional, trimmed, ≤ 500 characters, empty → null |
| Upcoming count | At most 100 exceptions dated today or later per Branch |

## Concurrency and errors

| Situation | Response |
| --- | --- |
| PUT `expectedVersion=0` when the date already has an exception | `409 OPENING_HOURS_EXCEPTION_VERSION_CONFLICT`; the envelope carries `error.openingHoursException` = the current row (same shape as a GET item), or `null` when the row no longer exists |
| PUT/DELETE with a stale `expectedVersion` | Same 409 with `error.openingHoursException` |
| DELETE of a date without an exception | `404 OPENING_HOURS_EXCEPTION_NOT_FOUND` |
| PUT before weekly hours exist | `409 OPENING_HOURS_EXCEPTION_WEEKLY_REQUIRED` |
| Foreign Merchant/Branch | `MERCHANT_NOT_FOUND` / `MERCHANT_BRANCH_NOT_FOUND` |
| STAFF PUT/DELETE | `403 MERCHANT_ROLE_FORBIDDEN` |

`(branch_id, local_date)` is unique in the database, so two concurrent creates for the same date produce one row and one 409.

## Endpoints

| Method | Path | Capability |
| --- | --- | --- |
| GET | `…/opening-hours/exceptions` | `MERCHANT_READ` |
| PUT | `…/opening-hours/exceptions/:date` `{ expectedVersion, closed, intervals, label, customerMessage? }` | `MERCHANT_BRANCH_UPDATE` |
| DELETE | `…/opening-hours/exceptions/:date?expectedVersion=n` | `MERCHANT_BRANCH_UPDATE` |

GET returns `{ branchId, timezone, today, items[] }`, items dated today or later in date order; each item has `date`, `closed`, `label`, `customerMessage`, `intervals[{ opens, closes }]`, `version`, `updatedAt`.

The Merchant availability response gains an additive `hoursException` (`{ date, closed, label } | null`) for today's date.

## Checkout / Order / Customer

- Reuse `CHECKOUT_BRANCH_CLOSED` / `ORDER_BRANCH_CLOSED` when an exception closes the Branch, and `*_HOURS_NOT_CONFIGURED` unchanged.
- One `CHECKOUT_CLOCK.now()` per request (unchanged). Order create re-evaluates at placement time.
- Customer `isOpenNow`, `currentClosesAt` and `nextOpenAt` include exceptions. Field names are unchanged. The public weekly `days` stay the weekly schedule.
- The `openNow=true` SQL filter applies the same rules (today's exception, previous-date spill only when today and the previous date have no exception).

## Merchant UI semantics

- Info banner: exceptions replace the usual hours only for the selected dates.
- Upcoming list with Fermé / Ouvert badges and the 24-hour interval; delete per date.
- Add form: date, Ouvert / Fermé, modified hours (24-hour), reason, optional customer message.
- OWNER and MANAGER edit; STAFF sees the list read-only.
- A change is shown as saved only after a 200. On failure the draft stays and the server message is shown; a version conflict reloads the list and keeps the draft.
- The weekly hours screen links to this screen. The date picker offers today to today + 365 days in `Africa/Algiers`.
- Not implemented (by decision): one card for a multi-date range, batch entry, and any Customer display of the label or message.

## Verification (2026-10-02)

- Backend e2e on the isolated fixture API: checks H01–H23 PASS, including closed-day and interval Checkout/Order checks, midnight and spill, override precedence and conflicts (`apps/merchant_app/audit/parity/isolated/evidence/fxenv_20261002T193016Z/contract_e2e/contract_e2e_results.json`).
- Merchant live on the isolated API at text 1.0 and 1.35: add closed future date, add modified-hours date, add today-closed (availability shows the exception, then weekly fallback after delete), stale-version conflict with draft preserved, STAFF read-only. Report: `apps/merchant_app/audit/parity/contract_batch/CONTRACT_COMPLETION_BATCH_REPORT.md`.
- Not verified live: a real clock crossing midnight (covered by e2e H14/H15 and evaluator unit tests only).
