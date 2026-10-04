# API conventions

Contracts will be finalized after domain and ERD approval. The following conventions apply to the SpeedyGo backend.

## Style

- HTTP JSON REST as the default public API
- OpenAPI / Swagger published by the backend (`/docs` in local foundation)
- Global prefix: `api/v1`
- Socket.IO namespace `/realtime` for Realtime Tracking Foundation v1.0 (FINAL)

Realtime Tracking v1.0 events (namespace `/realtime`):

- `driver:location:update`
- `tracking:subscribe`
- `tracking:unsubscribe`
- `tracking:location`
- `tracking:status`
- `tracking:error`

HTTP tracking surface:

- `POST /api/v1/driver/location` (authenticated Driver ingest fallback; same store as the socket event)
- `GET /api/v1/customer/orders/:orderId/tracking`
- `GET /api/v1/merchant/:merchantId/orders/:orderId/tracking`

Merchant preparation estimate (see [MERCHANT_ORDER_PREPARATION_ESTIMATE_FOUNDATION.md](../architecture/MERCHANT_ORDER_PREPARATION_ESTIMATE_FOUNDATION.md)):

- `POST /api/v1/merchant/:merchantId/orders/:orderId/accept` may include `{ preparationMinutes?: number }` (5–120). Omitted → legacy accept without estimate.
- `POST /api/v1/merchant/:merchantId/orders/:orderId/preparation-estimate` `{ addMinutes, expectedEstimateVersion, reason? }`
- List/detail expose `estimatedReadyAt`, originals, `preparationEstimateVersion`, derived `isPreparationLate`. Errors: `MERCHANT_ORDER_PREP_ESTIMATE_INVALID` (400), `MERCHANT_ORDER_PREP_ESTIMATE_CONFLICT` (409), `MERCHANT_ORDER_PREP_ESTIMATE_NOT_ALLOWED` (409).

There is no `GET /api/v1/driver/location` and no `/tracking` namespace.

Driver Delivery Workflow v1.0 (current accepted assignment only; no generic status PATCH):

- `GET /api/v1/driver/deliveries/current`
- `POST /api/v1/driver/deliveries/current/start-to-pickup`
- `POST /api/v1/driver/deliveries/current/arrive-pickup` (fresh <=45s location, <=300m live pickup)
- `POST /api/v1/driver/deliveries/current/confirm-pickup`
- `POST /api/v1/driver/deliveries/current/start-delivery`
- `POST /api/v1/driver/deliveries/current/arrive-customer` (fresh <=45s location, <=300m address snapshot)
- `POST /api/v1/driver/deliveries/current/complete-delivery`

Clients never send `status` / `eventType` / release timestamps. Repeated actions return `409 DRIVER_DELIVERY_INVALID_STATE`. Arrival failures: `DRIVER_DELIVERY_LOCATION_REQUIRED`, `DRIVER_DELIVERY_LOCATION_STALE`, `DRIVER_DELIVERY_NOT_NEAR_PICKUP`, `DRIVER_DELIVERY_NOT_NEAR_DROPOFF`. ELECTRONIC completion without `SUCCEEDED` Payment: `DRIVER_DELIVERY_PAYMENT_NOT_READY`. COD completion without authoritative collection: `DRIVER_DELIVERY_COD_COMPLETION_NOT_READY`.

Driver Delivery History v1.0 (completed serving work only; P1-E):

- `GET /api/v1/driver/deliveries/history` — paginated self history (`deliveredAt` DESC, `deliveryId` DESC). Membership conjunction: `DELIVERED` + non-null `deliveredAt` + `RELEASED` serving assignment for this Driver **and** matching `DriverEarning.driverId` (RELEASED alone is insufficient). Optional `from`/`to` RFC3339 half-open `[from,to)` on `deliveredAt` (max 93 days; bare `YYYY-MM-DD` rejected). Money as decimal string. `earningStatus=EARNED` is recognition, not payout. No Customer PII, GPS trail, Rating comments, COD custody, Merchant finance, `orderId`, or `assignmentId`. Offset max 10_000.
- `GET /api/v1/driver/deliveries/history/:deliveryId` — owned completed detail (`pickedUpAt`/`arrivedCustomerAt` only as extras); foreign/non-serving → `DRIVER_DELIVERY_HISTORY_NOT_FOUND`.

Active Delivery remains on `/driver/deliveries/current`. Matching OFFERED/REJECTED/EXPIRED are not history. See [DRIVER_DELIVERY_HISTORY_FOUNDATION.md](../architecture/DRIVER_DELIVERY_HISTORY_FOUNDATION.md).

COD Foundation v1.0 Driver routes:

- `POST /api/v1/driver/deliveries/current/collect-cod` — body `{ collectedAmountMinor }` only (exact amount). ARRIVED_CUSTOMER + ACCEPTED assignment. Creates one `CodCollection` and COD Payment `PENDING → SUCCEEDED`. Safe same-amount replay reuses the row.
- `GET /api/v1/driver/cod/summary` — self custody (`outstandingCustodyMinor` = collected − confirmed allocations)
- `POST /api/v1/driver/cod/remittances` — declare remittance (`DECLARED` only; at most one open DECLARED per Driver). Does not reduce custody.

Remittance confirmation is available on Admin Foundation (`POST /api/v1/admin/cod/remittances/:id/confirm`). See [COD_FOUNDATION.md](../architecture/COD_FOUNDATION.md) and [ADMIN_FOUNDATION.md](../architecture/ADMIN_FOUNDATION.md).

Merchant Commission Foundation v1.0 public read (no Admin mutation HTTP):

- `GET /api/v1/merchant/:merchantId/commission` — OWNER/MANAGER effective rate (`scope`, `rateBps`, `ruleId`, windows). STAFF receives `MERCHANT_ROLE_FORBIDDEN`. Customers/Drivers have no commission routes. See [MERCHANT_COMMISSION_FOUNDATION.md](../architecture/MERCHANT_COMMISSION_FOUNDATION.md).

Driver Remuneration Foundation v1.0 public self-read (no mutation / payout HTTP):

- `GET /api/v1/driver/earnings/summary` — `totalEarnedMinor`, `unpaidEarnedMinor`, `earningCount`, `currency` (not COD custody; not a wallet)
- `GET /api/v1/driver/earnings` — paginated self history (`earningId`, `deliveryId`, `orderId`, `amountMinor`, `status`, `earnedAt`)

Earning creation is system-only on successful Delivery completion. See [DRIVER_REMUNERATION_FOUNDATION.md](../architecture/DRIVER_REMUNERATION_FOUNDATION.md).

Refunds Foundation v1.0 public Customer self-read (no mutation HTTP):

- `GET /api/v1/customer/orders/:orderId/refunds` — owned Order only; safe Refund fields (`requestedAt`, `completedAt`, totals). Foreign Order → `REFUND_NOT_FOUND`.

Refund create / authorize / confirm / reject are available on Admin Foundation HTTP (`RefundService` via Admin commands; verified AdminProfile). Chargily automatic Refund is unsupported; ELECTRONIC uses `MANUAL_OTHER`, COD uses `MANUAL_COD`. See [REFUNDS_FOUNDATION.md](../architecture/REFUNDS_FOUNDATION.md) and [ADMIN_FOUNDATION.md](../architecture/ADMIN_FOUNDATION.md).

Merchant Settlements Foundation v1.0 public Merchant self-read (no mutation HTTP):

- `GET /api/v1/merchant/:merchantId/settlements` — OWNER/MANAGER list (`settlementId`, period, status, currency DZD, totals). STAFF → role forbidden. Foreign Merchant → forbidden/not-found.
- `GET /api/v1/merchant/:merchantId/settlements/:settlementId` — detail with safe lines (`type`, `orderId`, `refundId`, amounts). No COD custody, DriverEarning, provider secrets, or other Merchants.

Settlement open/build/attach liability/finalize are available on Admin Foundation HTTP (verified AdminProfile). Settlement ≠ payout; `paidAt` / `PAID` are not used. See [MERCHANT_SETTLEMENTS_FOUNDATION.md](../architecture/MERCHANT_SETTLEMENTS_FOUNDATION.md) and [ADMIN_FOUNDATION.md](../architecture/ADMIN_FOUNDATION.md).

Financial Ledger Foundation v1.0 Admin read: `GET /api/v1/admin/ledger` (`ledger.read`). Ledger postings remain system/internal only. Customers/Merchants/Drivers never access the global ledger. See [FINANCIAL_LEDGER_FOUNDATION.md](../architecture/FINANCIAL_LEDGER_FOUNDATION.md) and [ADMIN_FOUNDATION.md](../architecture/ADMIN_FOUNDATION.md).

Promotions Foundation v1.0 (FINAL safe subset): optional `promoCode` on Checkout preview and Order create. Preview does not redeem. Zero Customer payable after Promotion fails closed (`PROMOTION_ZERO_PAYABLE_UNSUPPORTED`). No usage limits, targeting, or shared funding. Authenticated Customer discovery: `GET /customer/promotions` returns only offers explicitly published for Customer visibility that are currently effective; unpublished offers stay hidden; the read never redeems. Admin HTTP can create, activate/deactivate, and publish/hide discovery. See [PROMOTIONS_FOUNDATION.md](../architecture/PROMOTIONS_FOUNDATION.md).

Notifications Foundation v1.0 **FINAL FREEZE** (durable IN_APP-only + bounded recovery): Account-scoped inbox under `/api/v1/notifications` — `GET /`, `GET /unread-count`, `POST /:id/read`, `POST /read-all`, `PUT`/`DELETE /device-tokens`. No public create or retry. No preference routes. IN_APP `SENT` = persisted authenticated inbox. Push vocabulary only (`SKIPPED_NOT_CONFIGURED`; zero provider calls). See [NOTIFICATIONS_FOUNDATION.md](../architecture/NOTIFICATIONS_FOUNDATION.md).

Merchant Verification Foundation v1.0 public Merchant self routes (no Admin review HTTP):

- `GET /api/v1/merchant/:merchantId/verification` — OWNER full package (no fileUrl); MANAGER status/readiness/attention only; STAFF forbidden
- `POST /api/v1/merchant/:merchantId/verification/documents/:type/content` — OWNER multipart `file` (PDF/JPEG/PNG, max 10 MiB) → opaque `uploadReference` (`sg-upload:v1:...`). No paths/URLs.
- `PUT /api/v1/merchant/:merchantId/verification/documents/:type` — OWNER upsert (`BUSINESS_IDENTITY` | `BUSINESS_REGISTRATION` | `SUPPORTING_DOCUMENT`). Optional `expiryDate` + optional `uploadReference` bind. No client `fileUrl` / `status`. Locked when submitted, ACTIVE, or SUSPENDED
- `POST /api/v1/merchant/:merchantId/verification/submit` — OWNER formal submission (required docs `SUBMITTED`). Does not set `ACTIVE`. Approval requires submitted + ready

Approve / reject / suspend are available on **Admin Foundation** HTTP (`MerchantReviewService` via Admin commands, verified AdminProfile). No persisted rejection reason in v1.0. See [MERCHANT_VERIFICATION_FOUNDATION.md](../architecture/MERCHANT_VERIFICATION_FOUNDATION.md) and [ADMIN_FOUNDATION.md](../architecture/ADMIN_FOUNDATION.md).

Secure Document Uploads (P1-C review): private verification bytes only. Driver: `POST /api/v1/driver/documents/:type/content` + `PUT .../documents/:type` with optional `uploadReference`. Admin download (permission + audit before bytes): `GET /api/v1/admin/drivers/:id/documents/:documentId/content`, `GET /api/v1/admin/merchants/:id/documents/:documentId/content` — attachment, nosniff, no-store. No public URLs. See [SECURE_DOCUMENT_UPLOADS_FOUNDATION.md](../architecture/SECURE_DOCUMENT_UPLOADS_FOUNDATION.md).

Admin Foundation v1.0 (trusted AdminProfile + Role.active + permission codes):

- `GET /api/v1/admin/me` — AdminGuard only
- Merchants: `GET /admin/merchants`, `GET /admin/merchants/verification/queue`, `GET /admin/merchants/:id`, `GET /admin/merchants/:id/verification`, `GET /admin/merchants/:id/documents/:documentId/content` (`merchants.verify` + audit), `POST .../verification/approve|reject`, `POST .../suspend`
- Drivers: `GET /admin/drivers`, `GET /admin/drivers/verification/queue`, `GET /admin/drivers/:id`, `GET /admin/drivers/:id/documents/:documentId/content` (`drivers.verify` + audit), `POST .../verification/approve|reject`, `POST .../suspend`
- Customers: `GET /admin/customers`, `GET /admin/customers/:id`
- Orders: `GET /admin/orders`, `GET /admin/orders/:id`
- Payments: `GET /admin/payments`, `GET /admin/payments/:id` (no provider secrets)
- Refunds: `GET /admin/refunds`, `GET /admin/refunds/:id`, `POST /admin/refunds`, `POST /admin/refunds/:id/approve|reject|confirm-manual` (MANUAL_* only; actor from CurrentAdmin)
- COD: `GET /admin/cod/remittances`, `GET /admin/cod/remittances/:id`, `POST /admin/cod/remittances/:id/confirm`
- Settlements: `GET /admin/settlements`, `GET /admin/settlements/:id`, `POST /admin/settlements`, `POST .../build-sale-lines`, `POST .../refund-liability`, `POST .../finalize` (no PAID)
- Promotions: `GET /admin/promotions`, `GET /admin/promotions/:id`, `POST /admin/promotions`, `POST .../activate|deactivate`, `POST .../publish-discovery|hide-discovery`, `POST .../presentation`
- Delivery zones (P1-I): `GET /admin/delivery/zones`, `GET /admin/delivery/zones/:id`, `POST /admin/delivery/zones`, `PUT /admin/delivery/zones/:id`, `POST .../activate|deactivate` — GeoJSON Polygon input (`[lon,lat]`), stored MultiPolygon SRID 4326; active interiors may not overlap (`ST_Intersects AND NOT ST_Touches`); boundary-only touching allowed; shared-boundary `ST_Covers` multi-match fails closed; no DELETE. Permissions: `delivery.zones.read|manage`
- Delivery pricing rules (P1-I): `GET /admin/delivery/pricing-rules`, `GET /admin/delivery/pricing-rules/:id`, `POST /admin/delivery/pricing-rules` (inactive), `POST .../activate|deactivate` — zone-scoped flat minor fees; multiple active rules allowed only when Checkout applicability is disjoint (Africa/Algiers; effective `[from,to)`; inclusive local windows); money responses are exact minor-unit decimal strings; no DELETE. Permissions: `delivery.pricing.read|manage`
- Ledger: `GET /admin/ledger` only (no POST)
- Audit: `GET /admin/audit` (immutable)

See [ADMIN_FOUNDATION.md](../architecture/ADMIN_FOUNDATION.md) and [ADMIN.md](../business-rules/ADMIN.md).

Suspend + Session Revocation (P1-G):

- `POST /api/v1/admin/merchants/:id/suspend` — `merchants.suspend`; empty body (no free-text reason); ACTIVE verified Merchant → `SUSPENDED`; revokes **all** member Account Sessions in the same TX as domain + AuditLog (`sessionsRevoked`); post-commit Redis + `/realtime` disconnect. Does **not** set `Account.status`. Immediate containment even with active Orders; no auto reject/cancel/refund; new checkout denied. No unsuspend in v1.0.
- `POST /api/v1/admin/drivers/:id/suspend` — `drivers.suspend`; empty body; APPROVED Driver → verification + availability `SUSPENDED`; revokes Driver Account Sessions similarly. Active Delivery unchanged (no auto reassign/fail/cancel/refund); revoked sessions cannot continue logistics actions.
- Authorization authority is PostgreSQL `Session.revokedAt` (`AUTH_SESSION_REVOKED`); Redis `auth:*sess:*` is best-effort only. `Role.name` is non-authoritative; verify permissions do not imply suspend. Multi-merchant and shared CustomerProfile boundaries preserved.

See [SUSPEND_SESSION_REVOCATION_FOUNDATION.md](../architecture/SUSPEND_SESSION_REVOCATION_FOUNDATION.md) and [SUSPEND_SESSION_REVOCATION.md](../business-rules/SUSPEND_SESSION_REVOCATION.md).

CORS Configuration (P1-H):

- Env: `CORS_ALLOWED_ORIGINS` — comma-separated exact `http(s)://host[:port]` Origins for browsers. Fail-closed at startup if missing/invalid/`*`.
- Shared by NestJS HTTP and Socket.IO `/realtime` (CORS headers + Engine.IO `allowRequest` so disallowed Origins are rejected at handshake, including forged Node clients). Reflect exact Origin only; never `*`. `credentials=false` (Bearer + JSON refresh; no auth cookies).
- Missing Origin (native Flutter, webhooks, curl) passes the CORS layer; Auth/signature still apply. `Origin: null` denied.
- Methods: GET/HEAD/POST/PUT/PATCH/DELETE/OPTIONS. Request headers: Authorization, Content-Type, Accept. Exposed: Content-Disposition. Preflight 204, max-age 600.
- Not AuthZ. Not stored in DB/Redis/Settings. See [CORS_CONFIGURATION_FOUNDATION.md](../architecture/CORS_CONFIGURATION_FOUNDATION.md).

Support Foundation v1.0 (conversation triage; no business-state mutation; no Notifications; no attachments):

Customer:

- `POST /api/v1/customer/support` — body `{ body, orderId? }`; always OPEN/NORMAL + first message
- `GET /api/v1/customer/support` — own tickets (`updatedAt` DESC)
- `GET /api/v1/customer/support/:ticketId` — messages oldest-first; no internal notes
- `POST /api/v1/customer/support/:ticketId/messages` — reply; `WAITING_CUSTOMER` → `IN_PROGRESS`; `RESOLVED`/`CLOSED` → conflict

Driver:

- `POST /api/v1/driver/support` — `driverId` forced to self; optional `orderId` via Delivery + DriverAssignment
- `GET /api/v1/driver/support`, `GET .../:ticketId`, `POST .../:ticketId/messages`

Merchant (OWNER/MANAGER; STAFF forbidden):

- `POST /api/v1/merchant/:merchantId/support`
- `GET /api/v1/merchant/:merchantId/support`, `GET .../:ticketId`, `POST .../:ticketId/messages`

Admin (`support.read` / `support.manage`):

- `GET /api/v1/admin/support` — filters: status, priority, assignedAdminId, createdFrom/To
- `GET /api/v1/admin/support/:ticketId` — includes internal notes
- `POST .../:ticketId/messages` — public reply (`displayName` SpeedyGo Support; no AuditLog)
- `POST .../:ticketId/internal-notes` — audited
- `POST .../:ticketId/assign` — body `{ assignedAdminId: uuid | null }`; target must be AdminProfile + active Role + `support.manage`; actor = CurrentAdmin; audited; null unassigns
- `POST .../:ticketId/priority` — LOW|NORMAL|HIGH; audited
- `POST .../:ticketId/start|wait-customer|resolve|close|reopen` — explicit lifecycle; audited; reopen Admin-only (`RESOLVED|CLOSED` → `OPEN`); no auto-reopen on user reply

See [SUPPORT_FOUNDATION.md](../architecture/SUPPORT_FOUNDATION.md) and [SUPPORT.md](../business-rules/SUPPORT.md).

Ratings Foundation v1.0 (Customer → Merchant / Customer → Driver only; immutable):

- `POST /api/v1/customer/orders/:orderId/ratings/merchant` — body `{ score: 1..5, comment? }`; Order COMPLETED; merchantId derived
- `POST /api/v1/customer/orders/:orderId/ratings/driver` — same; Delivery DELIVERED; Driver from historical serving assignment (`RELEASED` after completion; never REJECTED/EXPIRED/OFFERED)
- `GET /api/v1/customer/orders/:orderId/ratings/merchant|driver` — own rating only (includes comment)
- `GET /api/v1/customer/merchants/:merchantId/ratings/summary` — `{ count, average }` (`average` null when count=0; two decimals)
- `GET /api/v1/customer/drivers/:driverId/ratings/summary`
- `GET /api/v1/merchant/:merchantId/ratings/summary` — Merchant member
- `GET /api/v1/driver/ratings/summary` — own DriverProfile

No edit/delete. No Admin rating routes. Duplicate → `409 RATING_ALREADY_EXISTS`. See [RATINGS_FOUNDATION.md](../architecture/RATINGS_FOUNDATION.md).

Customer Catalog Discovery Foundation v1.0 (authenticated CustomerProfile read projection of Branch-owned Catalog; no mutations):

- `GET /api/v1/customer/branches` — paginated eligible storefronts (`MerchantBranch`)
- `GET /api/v1/customer/branches/:branchId` — storefront detail (fail-closed when not visible)
- `GET /api/v1/customer/branches/:branchId/categories` — active categories with available products
- `GET /api/v1/customer/branches/:branchId/products` — paginated orderable products (`categoryId?`); `productId` is Cart add-item ID; `priceMinor` money string
- `GET /api/v1/customer/branches/:branchId/products/:productId` — product detail + option groups
- `GET /api/v1/customer/catalog/search?q=` — bounded ILIKE search (storefront/merchant name + product name); `q` length 2..100 after trim
- `GET /api/v1/customer/promotions` — published effective Customer-facing offers only (`discountKind` + `value` in existing units). Not cart eligibility. Never redeems. See [PROMOTIONS_FOUNDATION.md](../architecture/PROMOTIONS_FOUNDATION.md).

Visibility: Merchant `ACTIVE` + `verifiedAt` + non-empty name + Branch `operationalStatus=ACTIVE`; products also require `Category.active` and `Product.available`. Storefronts include opening-hours projection (`hoursConfigured`, `isOpenNow`, `timezone`, `currentClosesAt`, `nextOpenAt`); `isOpenNow` is **effective** (availability override + per-date hours exception + weekly hours); the `openNow=true` list filter applies the same rules. Detail may include public weekly days. Optional authenticated `coverImageUrl` is a Customer cover path, never a verification document. Optional authenticated product `imageUrl` is `/customer/branches/:branchId/products/:productId/image`, never a storage key or branch cover. No distance / ETA / delivery fee on catalog payloads. Customer Home banner uses `GET /api/v1/customer/promotions` (published effective offers only; not cart eligibility). Checkout remains delivery and pricing authority and enforces effective open hours. See [CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md](../architecture/CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md), [MERCHANT_OPENING_HOURS_FOUNDATION.md](../architecture/MERCHANT_OPENING_HOURS_FOUNDATION.md), and [MERCHANT_STORE_AVAILABILITY_FOUNDATION.md](../architecture/MERCHANT_STORE_AVAILABILITY_FOUNDATION.md).

Merchant Branch Opening Hours Foundation v1.0 (P1-F):

- `GET /api/v1/merchant/:merchantId/branches/:branchId/opening-hours` — `MERCHANT_READ`
- `PUT /api/v1/merchant/:merchantId/branches/:branchId/opening-hours` — `MERCHANT_BRANCH_UPDATE`; body `{ expectedVersion, days[7] }`; `expectedVersion=0` creates
- Optimistic concurrency → `409 OPENING_HOURS_VERSION_CONFLICT`
- Checkout/Order closed or unconfigured → `409 CHECKOUT_BRANCH_CLOSED` / `CHECKOUT_BRANCH_HOURS_NOT_CONFIGURED` (and `ORDER_*` twins)
- Timezone `Africa/Algiers`; half-open `[open, close)`

See [MERCHANT_OPENING_HOURS_FOUNDATION.md](../architecture/MERCHANT_OPENING_HOURS_FOUNDATION.md) and [MERCHANT_OPENING_HOURS.md](../business-rules/MERCHANT_OPENING_HOURS.md).

Merchant Store Availability Foundation v1.0:

- `GET /api/v1/merchant/:merchantId/branches/:branchId/availability` — `MERCHANT_READ`
- `PUT /api/v1/merchant/:merchantId/branches/:branchId/availability` — `MERCHANT_BRANCH_UPDATE`; body `{ expectedVersion, mode, reasonCode?, customerMessage?, closedUntil? }`; `expectedVersion=0` creates
- Modes: `FOLLOW_SCHEDULE` | `FORCE_CLOSED` | `TEMPORARY_CLOSED`
- Optimistic concurrency → `409 AVAILABILITY_VERSION_CONFLICT`
- Invalid body → `400 AVAILABILITY_INVALID`
- Active override close reuses `CHECKOUT_BRANCH_CLOSED` / `ORDER_BRANCH_CLOSED` at Checkout and Order create
- GET evaluates expired temporary overrides without DB writes; `closedUntil` ≠ `nextOpenAt`

See [MERCHANT_STORE_AVAILABILITY_FOUNDATION.md](../architecture/MERCHANT_STORE_AVAILABILITY_FOUNDATION.md) and [MERCHANT_STORE_AVAILABILITY.md](../business-rules/MERCHANT_STORE_AVAILABILITY.md).

Merchant Opening Hours Exceptions v1.0 (contract-completion batch, 2026-10-02):

- `GET /api/v1/merchant/:merchantId/branches/:branchId/opening-hours/exceptions` — `MERCHANT_READ`; `{ branchId, timezone, today, items[] }`, items dated today or later; item `{ date, closed, label, customerMessage, intervals[{ opens, closes }], version, updatedAt }`
- `PUT …/opening-hours/exceptions/:date` — `MERCHANT_BRANCH_UPDATE`; body `{ expectedVersion, closed, intervals, label, customerMessage? }`; `expectedVersion=0` creates; `200` with the saved item
- `DELETE …/opening-hours/exceptions/:date?expectedVersion=n` — `MERCHANT_BRANCH_UPDATE`; `200 { deleted: true, date }`; unknown date → `404 OPENING_HOURS_EXCEPTION_NOT_FOUND`
- Domain validation → `400 OPENING_HOURS_EXCEPTION_INVALID`; malformed body → `400 VALIDATION_ERROR`; no weekly schedule → `409 OPENING_HOURS_EXCEPTION_WEEKLY_REQUIRED`
- Stale or create-on-existing version → `409 OPENING_HOURS_EXCEPTION_VERSION_CONFLICT`, with top-level `error.openingHoursException` = current item or `null`
- Merchant availability GET/PUT responses gain additive `hoursException: { date, closed, label } | null` for today
- Checkout/Order reuse `CHECKOUT_BRANCH_CLOSED` / `ORDER_BRANCH_CLOSED`. No Customer field is added; the label and customer message are not exposed to Customer

See [MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md](../architecture/MERCHANT_OPENING_HOURS_EXCEPTIONS_FOUNDATION.md) and [MERCHANT_OPENING_HOURS_EXCEPTIONS.md](../business-rules/MERCHANT_OPENING_HOURS_EXCEPTIONS.md).

Merchant Branch Logo v1.0 (contract-completion batch, 2026-10-02):

- `POST /api/v1/merchant/:merchantId/branches/:branchId/logo/content` — `MERCHANT_BRANCH_UPDATE`; multipart `file` (JPEG/PNG, ≤ 1 MiB, 128–2048 px); `200` pending upload with `uploadReference`
- `PUT …/branches/:branchId/logo` — `MERCHANT_BRANCH_UPDATE`; body `{ uploadReference }`; `200 { branchId, logoImageUrl, logoVersion, contentType, widthPx, heightPx }`
- `GET …/branches/:branchId/logo` — `MERCHANT_READ` (STAFF included); bytes with `ETag`, `Cache-Control: private, no-cache`, `nosniff`; none → `404 STORAGE_OBJECT_MISSING`
- `DELETE …/branches/:branchId/logo` — `MERCHANT_BRANCH_UPDATE`; `200 { deleted: true }`, idempotent
- Unsupported type or dimensions → `400 STORAGE_UNSUPPORTED_TYPE`; over 1 MiB → `413` (`HTTP_ERROR`, multipart limit); consumed / foreign / other-purpose reference → `404 STORAGE_UPLOAD_REFERENCE_FOREIGN`; STAFF write → `403 MERCHANT_ROLE_FORBIDDEN`
- No Customer logo route or projection field

See [MERCHANT_BRANCH_LOGO_FOUNDATION.md](../architecture/MERCHANT_BRANCH_LOGO_FOUNDATION.md) and [MERCHANT_BRANCH_LOGO.md](../business-rules/MERCHANT_BRANCH_LOGO.md).

Catalog Product Duplication v1.0 (contract-completion batch, 2026-10-02):

- `POST /api/v1/merchant/:merchantId/products/:productId/duplicate` — `PRODUCT_MANAGE` (OWNER, MANAGER); body `{ requestId (UUID), name? (trimmed 1–255) }`
- `201 { product, replayed: false, copied: { optionGroupCount, optionCount, imageCopied } }`; same `requestId` and source → `200` with `replayed: true` and the existing copy
- The copy starts `available=false`; the source is never written; all rows in one transaction
- STAFF → `403 MERCHANT_ROLE_FORBIDDEN`; foreign product or Branch → `404 CATALOG_PRODUCT_NOT_FOUND`; non-member → `404 MERCHANT_NOT_FOUND`; invalid body → `400 VALIDATION_ERROR`; replay key on another Branch → `409 CATALOG_DUPLICATE_REQUEST_CONFLICT`; storage failure → `503 STORAGE_UNAVAILABLE`
- The endpoint-specific `requestId` is not the open global `Idempotency-Key` question (see Idempotency)

See [CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md](../architecture/CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md) and [CATALOG_PRODUCT_DUPLICATION.md](../business-rules/CATALOG_PRODUCT_DUPLICATION.md).

Reports Foundation v1.0 (Admin read-only projections; no write model; no export):

Query: required `from` + `to` RFC3339 timestamps (half-open `[from, to)`, UTC instants; max 93 days). Money as integer minor-unit strings.

Operational (`reports.read`):

- `GET /api/v1/admin/reports/operations/orders`
- `GET /api/v1/admin/reports/operations/deliveries`
- `GET /api/v1/admin/reports/operations/support`
- `GET /api/v1/admin/reports/operations/ratings`
- `GET /api/v1/admin/reports/operations/drivers` — paginated

Finance (`reports.finance.read`; not implied by `reports.read`):

- `GET /api/v1/admin/reports/finance/completed-orders` — OFS sums for completedAt cohort
- `GET /api/v1/admin/reports/finance/payments` — SUCCEEDED during period via `PaymentTransaction.processedAt` (ELECTRONIC) or `CodCollection.collectedAt` (COD); never `Payment.updatedAt`
- `GET /api/v1/admin/reports/finance/refunds` — REFUNDED via `Refund.completedAt`
- `GET /api/v1/admin/reports/finance/cod` — period flows + `codOutstandingCustodyAsOfToMinor` (history before `to`)
- `GET /api/v1/admin/reports/finance/driver-earnings` — EARNED via `DriverEarning.createdAt`
- `GET /api/v1/admin/reports/finance/settlements` — creation cohort (`createdAt`); currently FINALIZED classification — not finalization-event time
- `GET /api/v1/admin/reports/finance/promotions`
- `GET /api/v1/admin/reports/finance/merchants` — paginated

No platform revenue/profit/bank-balance metrics. No generic report builder. See [REPORTS_FOUNDATION.md](../architecture/REPORTS_FOUNDATION.md) and [REPORTS.md](../business-rules/REPORTS.md).

Settings Foundation v1.0 (Admin allowlisted `PlatformSetting` only; no arbitrary keys; no secrets):

- `GET /api/v1/admin/settings` — `settings.read` (exactly two keys; application defaults when missing)
- `GET /api/v1/admin/settings/:key` — `settings.read`
- `PUT /api/v1/admin/settings/:key` — `settings.manage` body `{ "value": ... }` (typed per key; atomic AuditLog)

Allowlisted keys only: `platform.supportContactEmail`, `platform.supportContactPhone`.  
`platform.publicAnnouncement` and other keys → unsupported.  
Response fields: key, value, valueType, source, classification, mutability, effectiveTime, updatedAt — **not** `updatedByAdminId`.  
`settings.read` does not imply manage. No DELETE/reset/public Settings API. No mobile consumer in this foundation. Domain economics and env secrets remain outside Settings. See [SETTINGS_FOUNDATION.md](../architecture/SETTINGS_FOUNDATION.md) and [SETTINGS.md](../business-rules/SETTINGS.md).

See [DRIVER_DELIVERY_WORKFLOW.md](../architecture/DRIVER_DELIVERY_WORKFLOW.md).

Customer Order Cancellation Foundation v1.0 (P1-D):

- `POST /api/v1/customer/orders/:orderId/cancel` — optional body `{ "reason" }` (trimmed, max 255; HTML/control chars rejected). Customer self-cancel only while `Order.status=CREATED` and `fulfillmentStatus=PENDING_ACCEPTANCE`. Ownership from JWT `CustomerProfile` only — foreign Order → `ORDER_NOT_FOUND` (404); Merchant/Driver without CustomerProfile → `CUSTOMER_PROFILE_NOT_FOUND` (404).
- Unpaid / COD early cancel: no Refund row; unexecuted `Payment.status` `PENDING` → `CANCELLED`.
- Paid ELECTRONIC (`Payment.status=SUCCEEDED`): atomic Order `CANCELLED` + durable Refund intent (`REQUESTED`, `MANUAL_OTHER`). Response includes `refundRequired`, `refundId`, `refundStatus`, `refundAmountMinor` (decimal string). `refundRequired` ≠ money returned; `completedAt` stays null until Admin manual confirm.
- Repeat cancel by same owner is idempotent (`cancellationAccepted: true`; reuses same Refund intent). Concurrent duplicate cancels produce one Refund.
- Cancel while electronic checkout is `PROCESSING` leaves Payment open; late verified webhook success on a `CANCELLED` Order creates/reuses exactly one Refund intent; webhook replay does not duplicate Refunds.
- After Merchant accept or fulfillment progress → `409 ORDER_CANCELLATION_NOT_ALLOWED`. Active Delivery → `ORDER_CANCELLATION_FULFILLMENT_ACTIVE`. COD collected → `ORDER_CANCELLATION_COD_COLLECTED`.
- Merchant paid reject (pre-accept) shares the same paid-terminal Refund coupling. Promotions remain consumed after cancel/reject (FINAL for P1-D). Provider auto-refund unsupported — `MANUAL_OTHER` intent only; Admin confirms. Automatic Refunds use typed `requestOrigin` and unique `paidTerminalIntentKey` (no system Admin env). See [CUSTOMER_ORDER_CANCELLATION_FOUNDATION.md](../architecture/CUSTOMER_ORDER_CANCELLATION_FOUNDATION.md).

Payments Foundation v1.0 **FINAL FREEZE** (Chargily Pay V2):

- `GET /api/v1/customer/orders/:orderId/payment` — aggregate only (`paymentId`, `method`, `status`, `amountMinor`, `currency`, `provider`, timestamps). No checkout URL.
- `POST /api/v1/customer/orders/:orderId/payment/initiate` — empty body. Returns aggregate plus `attemptId` and provider `checkoutUrl`.
- `POST /api/v1/payments/webhooks/:provider` (public; Chargily uses header `signature` over raw body HMAC-SHA256). Production path: `/api/v1/payments/webhooks/chargily`.

Customer initiate does not accept `amount`, `amountMinor`, `currency`, `status`, `providerReference`, `customerId`, or `paymentId`. Client `Idempotency-Key` is not required for Payments v1.0 correctness. Foreign Payment/Order returns `PAYMENT_NOT_FOUND`. COD initiate returns `409 PAYMENT_METHOD_NOT_ELECTRONIC`. Already `SUCCEEDED` returns `409 PAYMENT_ALREADY_SUCCEEDED`. Invalid Chargily signature returns `401 PAYMENT_WEBHOOK_INVALID_SIGNATURE` and does not mutate Payment. Customer `success_url` / `failure_url` landings do not mutate Payment.

See [PAYMENTS_FOUNDATION.md](../architecture/PAYMENTS_FOUNDATION.md).

## Authority

- The backend validates every command.
- Clients must not treat locally computed money, tax, commission, or eligibility as authoritative.
- Permission checks are enforced server-side.

## Errors

Error bodies should be stable and machine-readable.

Authentication and Customer Onboarding endpoints use:

```json
{ "error": { "code": "AUTH_INVALID_TOKEN", "message": "Authentication required" } }
```

See [AUTHENTICATION.md](../architecture/AUTHENTICATION.md), [CUSTOMER_ONBOARDING.md](../architecture/CUSTOMER_ONBOARDING.md), [MERCHANT_FOUNDATION.md](../architecture/MERCHANT_FOUNDATION.md), and [CATALOG_FOUNDATION.md](../architecture/CATALOG_FOUNDATION.md).

Some version conflicts add one documented key inside `error` carrying the current server state, for example `error.openingHoursException` on `OPENING_HOURS_EXCEPTION_VERSION_CONFLICT`. Clients must ignore unknown keys.

**REQUIRES BUSINESS CONFIRMATION:** whether this envelope is the global API shape, localization, and problem+json vs custom shape.

## Versioning

Breaking changes require a new API version. Additive, compatible fields may appear in `v1`.

## Auth

See [AUTHENTICATION.md](../architecture/AUTHENTICATION.md).

Mobile auth: OTP + short-lived JWT access + opaque rotating refresh + `sessions` row.

Clients **must single-flight** `POST /api/v1/auth/refresh`. Concurrent refresh with the same token is treated as reuse and revokes the Session. The backend does not offer a refresh grace window.

Admin password/TOTP login: **REQUIRES BUSINESS CONFIRMATION**.

## Financial payloads

- Amounts: integer minor units in storage (Prisma `BigInt`)
- JSON transport for money: exact base-10 **decimal strings** (e.g. `"1500"`, `"9007199254740993"`). Never JavaScript `number` / raw `bigint` in JSON for money
- Pattern: `^-?[0-9]+$` (use non-negative `^[0-9]+$` where the domain forbids negatives)
- Rates: integers (basis points) when representing percentages — remain JSON numbers
- Snapshots: read-only; clients never PATCH historical financial fields

## Resources vs statuses

Do not overload a single `status` field. Order, delivery, payment, refund, and COD reconciliation are separate.

## Idempotency

Mutating financial and order commands should become idempotent.

Payments Foundation v1.0 does **not** require a client `Idempotency-Key` header. Server-owned Payment serialization, open-attempt reuse, unique `PaymentTransaction.idempotencyKey`, and `providerReference` collision checks are sufficient for that foundation.

**REQUIRES BUSINESS CONFIRMATION:** a future global client idempotency header name and replay window for other mutating APIs. This is not a Payments Foundation v1.0 blocker.
