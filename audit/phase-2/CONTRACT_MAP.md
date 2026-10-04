# Phase 2 contract / state / action map

Backend source of truth: `MerchantOrderController` + `MerchantOrderService` (read-only inspection this phase).

## Endpoints

| UI action | Method | Path | Body | Roles |
| --- | --- | --- | --- | --- |
| List | GET | `/merchant/:merchantId/orders` | query: `branchId`, `orderStatus`, `fulfillmentStatus`, `limit`, `offset` | OWNER/MANAGER/STAFF read |
| Detail | GET | `/merchant/:merchantId/orders/:orderId` | — | same |
| Accept | POST | `…/orders/:orderId/accept` | `{}` (mass-assignment rejected) | OWNER/MANAGER |
| Reject | POST | `…/orders/:orderId/reject` | `{ reason }` max 255 | OWNER/MANAGER |
| Start preparation | POST | `…/orders/:orderId/start-preparation` | `{}` | OWNER/MANAGER |
| Mark ready | POST | `…/orders/:orderId/mark-ready` | `{}` | OWNER/MANAGER |
| Delivery (read) | GET | `/merchant/:merchantId/orders/:orderId/delivery` | — | read; **no Merchant mutation** |

Idempotency headers: **not** present on Merchant order mutations. Recovery = re-GET detail after network/409.

## Distinct statuses

| Dimension | Values used |
| --- | --- |
| Order.status | CREATED → CONFIRMED → ACTIVE (→ COMPLETED/CANCELLED/FAILED) |
| fulfillmentStatus | PENDING_ACCEPTANCE → ACCEPTED → PREPARING → READY |
| Payment | method COD/ELECTRONIC; status separate (Merchant does not execute payment) |
| Delivery | separate resource; may be absent until later foundation |

## Transitions (source → action → result)

| From (order / fulfillment) | Action | To |
| --- | --- | --- |
| CREATED / PENDING_ACCEPTANCE | accept | CONFIRMED / ACCEPTED (+ confirmedAt) |
| CREATED / PENDING_ACCEPTANCE | reject | CANCELLED / PENDING_ACCEPTANCE + cancellation.reason |
| CONFIRMED / ACCEPTED | start-preparation | ACTIVE / PREPARING (COD may be PENDING; ELECTRONIC needs SUCCEEDED) |
| ACTIVE / PREPARING | mark-ready | ACTIVE / READY (no Delivery row created) |

Reject **after** accept → 409 `MERCHANT_ORDER_NOT_REJECTABLE` (not cancellation UX).  
Repeated accept → 409 `MERCHANT_ORDER_ALREADY_ACCEPTED`.

## List filters (UI tabs → query)

### En cours / Historique (Phase 2 visual correction)

| Segment | Chip | Query |
| --- | --- | --- |
| En cours | Nouvelles | `fulfillmentStatus=PENDING_ACCEPTANCE` |
| En cours | Acceptées | `fulfillmentStatus=ACCEPTED` |
| En cours | En préparation | `fulfillmentStatus=PREPARING` |
| En cours | Prêtes | `fulfillmentStatus=READY` |
| Historique | Annulées | `orderStatus=CANCELLED` |
| Historique | Terminées | `orderStatus=COMPLETED` |
| Historique | Échouées | `orderStatus=FAILED` |

No unfiltered “Toutes” / OR combination: each chip is one supported API filter applied **before** pagination. Counts use `list.total` for the active filter only. Default open: En cours → Nouvelles.

Home counts use `list.total` with `limit=1` per fulfillment filter (incoming/preparing/ready — not page length).

## Realtime

None for Merchant orders. Client: manual refresh + pull-to-refresh. Notification `MERCHANT_ORDER_CREATED` exists server-side but is not a Merchant app socket subscription in this phase.

## Errors surfaced

`MERCHANT_ORDER_NOT_FOUND`, `MERCHANT_ORDER_ALREADY_ACCEPTED`, `MERCHANT_ORDER_NOT_REJECTABLE`, `MERCHANT_ORDER_INVALID_TRANSITION`, `MERCHANT_ORDER_PAYMENT_NOT_READY`, `MERCHANT_ROLE_FORBIDDEN`, network → reconcile via GET before retry.
