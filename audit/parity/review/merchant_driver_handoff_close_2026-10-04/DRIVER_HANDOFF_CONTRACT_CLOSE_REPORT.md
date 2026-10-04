# Merchant Assigned Driver + Pickup Handoff — Close Report

**Run:** fxenv_20261004T152426Z  
**Date:** 2026-10-04T15:33:10Z  
**Isolation:** `speedygo_parity_fx` :3100 Redis 9 — `speedygo_dev` fingerprint unchanged (`createdSince.since` is snapshot window only; see `isolation_compare.txt`). Cleanup: DB dropped, Redis 9 flushed, `FX_CLEANUP_OK`.

## Rows

| Row | Ref | Stitch | Outcome |
| --- | --- | --- | --- |
| **21** | `driver_assigned_call_action_at_bottom` | `screens/MerchantScreens/driver_assigned_call_action_at_bottom` | **CLOSED** `implementer_reviewed` |
| **23** | `driver_arrived_secure_handoff_final_ux` | `screens/MerchantScreens/driver_arrived_secure_handoff_final_ux` | **UNFINISHED** — Driver UI dependency |

## Counts (from matrix)

- **73/77 closed (94.8%)**
- Row 21 closed; row 23 retained unfinished (Driver enter-code UI absent in `apps/driver_app`)
- Bottom Navigation V1 remains `user_accepted`
- New closures: `implementer_reviewed`

## Permission matrix

| Action | OWNER | MANAGER | STAFF | Assigned Driver |
| --- | --- | --- | --- | --- |
| Delivery GET + `assignedDriver` | ORDER_READ | ORDER_READ | ORDER_READ | N/A |
| Pickup handoff GET/regenerate | ORDER_READ | ORDER_READ | ORDER_READ | N/A |
| confirm-pickup with code | No | No | No | Yes (current assignment) |
| Account.phone to Merchant | Never (v1) | | | |

## Handoff direction

Merchant **displays** code; currently assigned Driver **enters/verifies** via `POST …/confirm-pickup`. Distinct from customer `DeliveryProof` PIN. Legacy deliveries without handoff rows remain code-optional.

## Migration

- Id: `20261004T1501_merchant_assigned_driver_pickup_handoff`
- Scope: `delivery_pickup_handoffs` table + `driver_assignments.version` (additive)
- Applied to `speedygo_parity_fx` only — **not** `speedygo_dev`

## Tests

| Suite | Result | Count |
| --- | --- | --- |
| Backend unit (`pickup-handoff`, delivery/driver-delivery services) | PASS | 63 |
| Merchant widget (`order_driver_handoff_test`) | PASS | 7 |
| Merchant capture (`driver_handoff_capture_test`) | PASS | 2 (4 PNGs) |
| Isolated authenticated HTTP (`fx_driver_handoff_e2e`) | PASS | 24 |
| Live Merchant simulator | NOT RUN | simulator not booted; mocked captures used |
| Driver UI workflow | NOT RUN | no Driver UI |

## Evidence

- HTTP: `driver_handoff/RESULTS.json`, `e2e.log`
- Mocked comparisons: `b2_detail_ready_to_pickup_assigned(+_t135).png`, `b2_detail_ready_at_pickup_handoff(+_t135).png`
- Foundation: `docs/architecture/MERCHANT_ASSIGNED_DRIVER_AND_PICKUP_HANDOFF.md`

## Driver UI dependency (row 23)

`apps/driver_app` has no delivery / confirm-pickup enter-code screen. API fixture PASS must not be labeled Driver UI evidence. Retain unfinished until Driver UI ships.

## Stitch remaining differences (row 21)

- No avatar photo, no ★ rating (not in contract; not fabricated)
- Call CTA disabled — `callAllowed=false`, `contactPhone=null` (Account.phone private)
- ETA unavailable truthful French copy (column never written)

## Preserved

Staff Management FAB clearance, Daily Summary, Delayed Order, Bottom Nav user_accepted, Finjan/Dar El Bahja sessions, Keychain.
