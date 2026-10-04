# SpeedyGo Catalog Foundation v1.0

Status: **FINAL FROZEN product rules for Branch-owned Catalog v1.0.** Prisma Schema v1.0 is unchanged. No migration was created. Authentication, Customer Onboarding, and Merchant foundations are unchanged.

This document is the Merchant-side catalog contract (categories, products, option groups, options). It is not Customer browsing, Cart, Checkout, Orders, Payments, or Admin catalog moderation.

## Scope

In:

- Merchant-authenticated catalog management for an owned `MerchantBranch`
- Category create / list / update / hard-delete (when empty)
- Product create / list / read / update / hard-delete (when unused)
- ProductOptionGroup and ProductOption management
- Derived catalog stats
- Role, membership, and Merchant-status gates via `MerchantAccessService`

Out:

- Customer browsing UI / Flutter integration (HTTP discovery is documented separately)
- Cart, Checkout, Orders, Delivery, Pricing, Commission, Payments, COD
- Promotions, ratings, favorites, inventory / branch stock
- Product images / media upload
- Admin catalog moderation
- Cross-Branch catalog sync or product cloning
- Frontends

Customer Catalog Discovery (authenticated read projection) is documented in [CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md](./CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md). Merchant Catalog management routes under `/api/v1/merchant/:merchantId/...` remain write/management only.

## Final Branch-owned Catalog rule

Frozen Prisma models are **Branch-owned**. There is no Merchant-level Product master and no global catalog.

```
Merchant
→ MerchantBranch
→ Category
→ Product
→ ProductOptionGroup
→ ProductOption
```

Contract:

- `Category.merchantBranchId` NOT NULL
- `Product.merchantBranchId` NOT NULL
- `Product.categoryId` NOT NULL

A Merchant **may exist without a Branch**. Merchant onboarding does not require a Branch.

A Merchant **must create a Branch before creating Categories or Products**. Catalog authoring is Branch-owned because the frozen schema is Branch-owned. Do not change schema to support Merchant-level Catalog.

This replaces the previous Merchant Foundation assumption that a Draft Catalog could be authored without a Branch. There is no Draft Catalog layer in v1.0.

If a Merchant has multiple Branches, each Branch owns its own Categories, Products, and Options. Cross-Branch synchronization and product cloning are not implemented and may be future enhancements.

HTTP routes stay Merchant-scoped because Accounts are multi-Merchant. Every list/create that needs a Branch requires `branchId`. Mutations by resource id verify:

`Account → MerchantMember → Merchant → MerchantBranch → Category/Product → OptionGroup → Option`

Missing or foreign Branch ids return 404 (`MERCHANT_BRANCH_NOT_FOUND` or `CATALOG_*_NOT_FOUND`). Do not expose whether another Merchant owns the Branch.

Admin RBAC never grants catalog access.

## Prisma models / field classes

### Category

| Field | Class |
| --- | --- |
| `id` | immutable |
| `merchantBranchId` | internal (client sends `branchId` on create only) |
| `name` | client-editable |
| `sortOrder` | client-editable |
| `active` | client-editable customer-facing visibility |
| timestamps | server-managed |

No unique constraint on Category name. Duplicate names inside one Branch are allowed. Do not add application-only uniqueness; it is race-prone without database support.

`Category.active` is customer-facing catalog visibility for that Branch. It is **not** hard deletion.

- `active=true`: Category may participate in future customer-facing catalog.
- `active=false`: Category remains stored and editable, but must not be shown as available to customers.

Products under an inactive Category must not become customer-orderable merely because `Product.available=true`.

### Product

| Field | Class |
| --- | --- |
| `id` | immutable |
| `merchantBranchId` | internal (`branchId` on create; cannot move Branch) |
| `categoryId` | client-editable, same Branch only |
| `name` | client-editable |
| `description` | client-editable optional |
| `priceMinor` | client-editable BIGINT minor units |
| `available` | client-editable operational offer flag |
| timestamps | server-managed |

There is **no** `imageUrl`, `status`, `currency`, `position`, or per-Branch stock table.

Product names are not unique. Multiple Products may share a display name. UUID identity is authoritative.

`Product.available` means whether this Product is currently offered for ordering from this Branch. It is **not**:

- archive status
- draft/published lifecycle
- stock quantity
- opening-hours state

`available=false` is not deletion. The Product remains stored and editable, but must not be orderable.

### ProductOptionGroup

| Field | Class |
| --- | --- |
| `id` | immutable |
| `productId` | internal |
| `name`, `required`, `minSelections`, `maxSelections` | client-editable |
| timestamps | server-managed |

No `position`. DB CHECKs: `min_selections >= 0`, `max_selections >= min_selections`. Application rules are stricter than the schema CHECKs (see OptionGroup selection rules).

### ProductOption

| Field | Class |
| --- | --- |
| `id` | immutable |
| `optionGroupId` | internal |
| `name` | client-editable |
| `additionalPriceMinor` | client-editable BIGINT `>= 0` |
| `available` | client-editable operational selectability |
| timestamps | server-managed |

`ProductOption.available` has the same operational meaning as Product availability:

- `available=true`: Option may be selected if its Product and OptionGroup are otherwise valid.
- `available=false`: Option remains stored but is not selectable.

It is not an archive flag. Do not introduce archive fields.

Negative `additionalPriceMinor` is forbidden by schema CHECK and API.

## No Draft / Published lifecycle

Do not introduce Product status values such as `DRAFT`, `PUBLISHED`, or `ARCHIVED`. The schema does not support them and they are not required for MVP.

Merchant status remains the publication gate.

A `PENDING_REVIEW` or `REJECTED` Merchant may build and edit Catalog. Nothing becomes customer-orderable until the Merchant is operational.

Unexpected `status` / `imageUrl` write fields are rejected (`forbidNonWhitelisted`).

## Future customer visibility invariant

A Product may only be orderable when all relevant conditions are satisfied, conceptually:

```
Merchant operationalReady = true
AND Branch operationalStatus = ACTIVE
AND Category.active = true
AND Product.available = true
```

This is documented and covered by helper logic (`isProductCustomerOfferable`). Customer Catalog Discovery enforces the same predicate on authenticated Customer routes; see [CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md](./CUSTOMER_CATALOG_DISCOVERY_FOUNDATION.md).

Opening-hours and stock availability remain separate future concerns.

Catalog existence never sets `operationalReady`. Catalog does not control Merchant operational readiness by itself.

## Product media

Optional one photograph per `Product` (`product_images`). Bytes live in ObjectStorage namespace `product-images/` with locator `sg-product-image:v1:<32-hex>`. JPEG/PNG, 400–4096 px, max 2 MiB, same validation and malware scan as storefront covers.

Merchant bind/remove uses catalog-write `PRODUCT_MANAGE`. Admin bind/remove requires `product.images.manage` and is audited. Pending tokens are bound to actor, merchant, branch, product, and purpose `PRODUCT_IMAGE`. Bind rechecks authorization and rejects cover tokens, verification-document tokens, and cross-product / cross-branch references.

Merchant management reads the bound photograph via `GET /api/v1/merchant/:merchantId/branches/:branchId/products/:productId/image` (`CATALOG_READ`). Merchant product list/detail include `hasImage`. Customer discovery exposes nullable `imageUrl` as `/customer/branches/:branchId/products/:productId/image`. Image reads use the same visibility predicate as product discovery. Missing image → `STORAGE_OBJECT_MISSING`. Never a storage credential, `sg-object:` locator, branch cover, or verification document.

Do not add a raw `imageUrl` column on `products`. Do not accept arbitrary external image URLs on catalog write DTOs.

## OptionGroup selection rules

Application-level rules (DTO + service):

- If `required=true`, then `minSelections >= 1`
- If `required=false`, then `minSelections` MUST equal `0`
- For every OptionGroup, `maxSelections >= 1`
- `maxSelections >= minSelections`

Valid:

- required=true, min=1, max=1
- required=true, min=1, max=3
- required=false, min=0, max=2

Invalid:

- required=false, min=1, max=2
- required=true, min=0
- maxSelections=0
- maxSelections < minSelections

## Price

Authoritative money is integer **minor units** (`priceMinor`, `additionalPriceMinor`). JSON uses `number` within `0..9_999_999_999`. Floats such as `10.99` are rejected.

- `priceMinor >= 0`. Zero-priced Products are allowed (free / included / promotional items).
- `additionalPriceMinor >= 0`. Negative Option price deltas are not supported in v1.0. Do not implement discount options through negative values.

There is no currency column.

## Catalog access policy

| Role | Read catalog | Manage categories / products / options |
| --- | --- | --- |
| OWNER | yes | yes, when Merchant status permits |
| MANAGER | yes | yes, when Merchant status permits |
| STAFF | yes | no |
| Unknown role | fail closed | fail closed |

Capabilities: `CATALOG_READ`, `CATEGORY_MANAGE`, `PRODUCT_MANAGE`, `PRODUCT_OPTIONS_MANAGE`.

Merchant status:

| Status | Catalog mutation |
| --- | --- |
| PENDING_REVIEW | allowed to OWNER/MANAGER |
| REJECTED | allowed to OWNER/MANAGER (corrections) |
| ACTIVE | allowed to OWNER/MANAGER |
| SUSPENDED | read-only |
| Unknown status | mutation denied |

## No Admin catalog moderation

Catalog-specific Admin moderation is not required in MVP. Merchant-level approval remains the operational gate.

Do not create catalog approval, product approval, or category approval Admin APIs.

## HTTP contract

Prefix: `/api/v1/merchant/:merchantId`

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/catalog?branchId=` | Categories + stats. No product dump. |
| GET/POST | `/categories` | List requires `branchId`. Create body includes `branchId`. |
| PATCH/DELETE | `/categories/:categoryId` | Owned Category |
| GET | `/products?branchId=&categoryId=&available=&q=&limit=&offset=` | Paginated summaries |
| GET/PATCH/DELETE | `/products/:productId` | Detail includes option trees |
| POST | `/products` | Body includes `branchId` + `categoryId` |
| POST | `/products/:productId/duplicate` | Atomic copy, starts unavailable; idempotent per `requestId`. See [CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md](./CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md) |
| GET/POST | `/products/:productId/option-groups` | |
| PATCH/DELETE | `/products/:productId/option-groups/:groupId` | Options CASCADE on group delete |
| POST/PATCH/DELETE | `/products/:productId/option-groups/:groupId/options` | |

Nested Product+Groups+Options create in one request is not supported.

## Deletion

- **Category:** hard delete if zero Products; else `CATALOG_CATEGORY_IN_USE`. Do not cascade-delete Products. Prefer `active=false` to hide the Category.
- **Product:** unused Products may be hard-deleted if no database constraint blocks deletion. If any `OrderItem` references the Product, do **not** hard-delete. Return `CATALOG_PRODUCT_IN_USE` and set `available=false` instead. Do not rely only on `ON DELETE SET NULL`. The repository locks the Product row, checks historical `OrderItem` use, then deletes. Order Foundation v1.0 takes the same Product row lock in the order-insert transaction so a line cannot appear between the historical-use decision and deletion. Prisma 8 has no `forUpdate` helper; the current lock pattern is a Product `updatedAt` UPDATE. Cart `RESTRICT` still maps to `CATALOG_PRODUCT_IN_USE`.
- **ProductOption:** Catalog `deleteOption` takes the same Option-row `updatedAt` UPDATE before delete. Order Foundation v1.0 locks selected ProductOption rows, in sorted id order, after Product locks and before OrderItemOption snapshots. A selected Option must not disappear between validation and snapshot persistence. If the row is gone, Order creation fails with `ORDER_CART_NOT_READY`. Selections are never silently omitted.
- **Option group / option:** hard delete where frozen relationships allow it. Historical Orders use snapshots and do not depend on live Option rows. No archive fields.

## Pagination / filters

Product list: `limit` default 50, max 100; `offset` default 0, max 10_000. Optional `categoryId`, `available`, `q` (name contains; `%` `_` `\` stripped). No Elasticsearch.

Category list is unpaginated per Branch (expected small).

## Readiness / stats

No persisted `catalogReady` column. Catalog creation does not activate the Merchant.

Derived only, on `GET .../catalog`:

```
categoryCount
productCount
availableProductCount
```

## Errors

| Code | HTTP |
| --- | --- |
| `CATALOG_CATEGORY_NOT_FOUND` | 404 |
| `CATALOG_PRODUCT_NOT_FOUND` | 404 |
| `CATALOG_OPTION_GROUP_NOT_FOUND` | 404 |
| `CATALOG_OPTION_NOT_FOUND` | 404 |
| `CATALOG_INVALID_PRICE` | 400 |
| `CATALOG_CATEGORY_IN_USE` | 409 |
| `CATALOG_PRODUCT_IN_USE` | 409 |
| `CATALOG_OPTION_GROUP_INVALID` | 400 |

Merchant membership/status still uses `MERCHANT_NOT_FOUND`, `MERCHANT_BRANCH_NOT_FOUND`, `MERCHANT_ROLE_FORBIDDEN`, `MERCHANT_STATUS_RESTRICTED`.

## Security

In-scope checks:

- IDOR / cross-Merchant: foreign catalog ids return 404
- Cross-Branch ownership: Category/Product Branch mismatch returns 404
- Mass assignment: unexpected fields (`imageUrl`, `status`, server-managed timestamps) rejected
- Price manipulation: floats and negatives rejected; integer minor units only
- Unknown role/status: fail closed
- Unsafe image URL: no image write field
- Product historical deletion: explicit OrderItem check before delete
- Pagination: limit/offset capped
- No unexpected Product cascade from Category delete

## Future boundaries

- Customer Catalog / discovery
- Order snapshots (already designed: copy names and amounts at order time)
- Catalog media via platform Media/Storage pipeline
- Admin catalog moderation (only if business requirements change)
- Per-Branch stock / temporary open-close / opening hours
- Cross-Branch product clone / sync
- Merchant-level (non-Branch) catalog — requires schema change; not v1.0

## REQUIRES BUSINESS CONFIRMATION

None for Catalog Foundation v1.0 product rules. Remaining platform items live in other foundations (for example Merchant document types).

## Local / test

E2E uses `speedygo_test` + Redis DB 15. Never `speedygo_dev`. Never `FLUSHALL`.

Historical Product deletion against a live `OrderItem` is covered at repository/unit level. Full e2e Order fixtures are deferred because they require Customer, DeliveryZone, and Order setup that is out of Catalog Foundation scope.
