# SpeedyGo Merchant Assigned Driver & Pickup Handoff v1.0

Additive contracts for Merchant parity rows:

| Row | Stitch folder |
| --- | --- |
| **21** `driver_assigned_call_action_at_bottom` | `screens/MerchantScreens/driver_assigned_call_action_at_bottom` |
| **23** `driver_arrived_secure_handoff_final_ux` | `screens/MerchantScreens/driver_arrived_secure_handoff_final_ux` |

Owner: `apps/backend` delivery module. Consumer: `apps/merchant_app` order detail.
Driver verification uses existing `POST …/confirm-pickup` (API only in this batch).
**No Driver / Customer / Admin UI changes** in this batch.

## A. Permission matrix (final)

| Action | OWNER | MANAGER | STAFF | Assigned Driver (self) | Foreign Merchant/Branch/Driver |
| --- | --- | --- | --- | --- | --- |
| `GET …/orders/:orderId/delivery` (incl. `assignedDriver`) | Yes (`ORDER_READ`) | Yes | Yes | N/A | 404 not-found style |
| `GET …/orders/:orderId/delivery/pickup-handoff` | Yes (`ORDER_READ`) | Yes | Yes | N/A | 404 |
| `POST …/delivery/pickup-handoff/regenerate` | Yes (`ORDER_READ`) | Yes | Yes | N/A | 404 |
| Enter / verify pickup code via `confirm-pickup` | No | No | No | Yes (current ACCEPTED assignment only) | Reject |
| Merchant enters pickup code / mutates Delivery via handoff | **No** | **No** | **No** | — | — |
| Read `Account.phone` / private Driver Account data | **No** | **No** | **No** | Self only via own auth surfaces | **No** |
| Call action (Merchant → Driver) | Only when response `callAllowed=true` **and** `contactPhone` present (v1: never) | | | | |

No new OWNER-only / STAFF-only capabilities. Handoff read/regenerate reuse `ORDER_READ` (same as Delivery GET). Backend authorization is authoritative.

## B. Driver data / privacy contract (Merchant)

Amends Matching decision table: **Customer** Delivery GET remains `assignedDriverId` only (**FINAL** unchanged for Customer).

**Merchant** Delivery GET may include additive nullable `assignedDriver` operational summary when an open `ACCEPTED` assignment exists:

| Field | Source | Notes |
| --- | --- | --- |
| `driverId` | `DriverAssignment.driverId` | Same as `assignedDriverId` |
| `assignmentId` | `DriverAssignment.id` | Current open assignment identity |
| `assignmentVersion` | `DriverAssignment.version` | Optimistic concurrency; starts at 1 |
| `displayName` | `DriverProfile.fullName` | Stored public operational name only |
| `vehicle` | ACTIVE `Vehicle` for driver (`type`, `plateNumber`) | Null if none; no fabricated vehicle |
| `contactPhone` | — | **Always null in v1** — `Account.phone` is private; not shareable to Merchants |
| `callAllowed` | derived | `true` only if policy permits + valid E.164 present (v1: always `false`) |
| `deliveryStatus` | `Delivery.status` | Current transport state |
| `arrivedPickupAt` | latest `DRIVER_ARRIVED_PICKUP` `DeliveryEvent.occurredAt` | Null if never arrived |
| `estimatedArrivalAt` | `Delivery.estimatedArrivalAt` | **Only if persisted**; today never written → null |

Never invent: avatar, rating, GPS live location, ETA, phone, vehicle, or arrival.

UI French when ETA null: « Heure d’arrivée indisponible. »
UI when call not allowed: omit enabled call CTA; show truthful unavailable contact copy. Do not deep-link `tel:` without `callAllowed`.

After reassignment / release / cancellation: response reflects the **current** open assignment only (or null). Prior driver must not remain actionable.

## C. Secure pickup handoff — direction & lifecycle

### Direction (proposed and adopted)

| Role | Action |
| --- | --- |
| **Merchant** | Sees the pickup code on order detail when Delivery is `AT_PICKUP` and a PENDING handoff exists for the current assignment. May regenerate. Does **not** enter the code. Does **not** confirm pickup. |
| **Driver** | Enters the code on `POST /api/v1/driver/deliveries/current/confirm-pickup` when a PENDING handoff binds the current assignment. Successful verify atomically consumes the handoff and transitions `AT_PICKUP` → `PICKED_UP`. |

This is **distinct** from customer delivery confirmation / `DeliveryProof.deliveryPinHash` (reserved for delivery-completion; unused in proofless MVP). Never reuse customer delivery OTP for Merchant→Driver pickup.

### Who / what / when

| Question | Answer |
| --- | --- |
| Who sees the code? | Authorized Merchant members with `ORDER_READ` for the owning Merchant of the Order’s branch |
| Who enters/verifies? | Currently assigned authenticated Driver only |
| Bound to? | Exact `deliveryId` + current open `assignmentId` (+ `assignmentVersion` check on verify) |
| When allowed to issue/read? | Delivery `AT_PICKUP`, Order not terminal, open ACCEPTED assignment, Merchant owns branch |
| When verify allowed? | Same + handoff `PENDING`, not expired, not locked, code matches, assignment still current |
| Success changes? | Handoff → `CONSUMED` (single-use); Delivery → `PICKED_UP`; `pickedUpAt`; one `ORDER_PICKED_UP` event. **No** financial settlement, COD, earnings, Order COMPLETED, or customer delivery proof |

### Lifecycle states

`PENDING` → `CONSUMED` | `INVALIDATED` | `EXPIRED` | `LOCKED` (attempt lock; may return to verifiable after lock window or stay locked until regenerate)

Invalidation triggers (server time):

- Order/Delivery cancellation
- Assignment release / reassignment (old assignment no longer open ACCEPTED)
- Explicit Merchant regenerate (old proof INVALIDATED; new PENDING issued)
- Expiry (`expiresAt`)

### Security properties

- Cryptographically secure random 4-digit numeric code (`crypto.randomInt`)
- Store `codeHash` = HMAC-SHA256(OTP_HMAC_SECRET, code) — never plaintext in DB
- Store `codeSealed` = AES-256-GCM(sealKey, code) for Merchant cold-relaunch re-display only (seal key derived from `OTP_HMAC_SECRET`)
- Never log plaintext codes or include in analytics / list endpoints
- Bounded attempts (`maxAttempts`, default 5) + lock window; Redis rate limit per delivery/driver
- Server time for `expiresAt` / lock / consume
- Audit: status transitions + actor ids; **no** plaintext secret in `metadataJson`
- Concurrent verify: transactional conditional consume — exactly one winner
- Retry after success: explicit already-confirmed / idempotent result **without** repeating Delivery transition side effects when already `PICKED_UP` + handoff `CONSUMED` by same driver/assignment
- Stale `assignmentId` / `assignmentVersion` → distinct conflict error
- Distinct errors: invalid code, expired, locked, wrong assignment, already consumed, invalid state

### Legacy compatibility

| Case | Behavior |
| --- | --- |
| Delivery with **no** `DeliveryPickupHandoff` row | `confirm-pickup` remains body-optional / code-not-required (pre-handoff MVP). No retroactive requirement for in-flight legacy orders |
| Delivery with PENDING handoff for current assignment | Code **required**; missing/wrong code rejected |
| Historical events / financial snapshots | Unchanged |
| Matching / cancellation / preparation / delivery SM | Preserved; handoff invalidation is additive side effect |

Issuing a handoff is **not** automatic on every AT_PICKUP transition. Merchant GET pickup-handoff (or regenerate) creates PENDING when eligible. Viewing/generating a code never auto-picks-up.

## D. HTTP

| Method | Path | Authz |
| --- | --- | --- |
| GET | `/api/v1/merchant/:merchantId/orders/:orderId/delivery` | `ORDER_READ` — additive `assignedDriver` |
| GET | `/api/v1/merchant/:merchantId/orders/:orderId/delivery/pickup-handoff` | `ORDER_READ` — ensure/read PENDING code (plaintext only here) |
| POST | `/api/v1/merchant/:merchantId/orders/:orderId/delivery/pickup-handoff/regenerate` | `ORDER_READ` — invalidate + new code |
| POST | `/api/v1/driver/deliveries/current/confirm-pickup` | Driver — optional body `{ pickupCode, assignmentId, assignmentVersion }` required when PENDING handoff exists |

## E. Schema (additive)

`driver_assignments.version INT NOT NULL DEFAULT 1`

`delivery_pickup_handoffs`:

- `id`, `delivery_id`, `assignment_id`, `assignment_version`
- `code_hash`, `code_sealed`, `status`, `attempt_count`, `max_attempts`
- `expires_at`, `locked_until`, `consumed_at`, `consumed_by_driver_id`
- `created_by_account_id` (nullable for system), `invalidated_at`, `invalidated_reason`
- `version`, `created_at`, `updated_at`
- Partial unique: one `PENDING` per `delivery_id`

## F. Driver UI dependency (row 23)

Backend + Merchant display + authenticated Driver **API** fixture tests are in scope.
`apps/driver_app` has **no** delivery / confirm-pickup UI. Closing row 23 as a real-world handoff workflow requires a Driver UI enter-code action that does not exist yet.

API fixture evidence must **not** be labeled Driver UI evidence. Row 23 remains unfinished until that dependency is implemented (separate batch).

## G. Out of scope

External SMS/email/Maps/Firebase/payment activation; Arabic; Bottom Nav / Staff / Daily Summary / Delayed Order redesign; Customer Delivery PIN; inventing ratings/avatars/ETA; `speedygo_dev` migration in parity runs.
