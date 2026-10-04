# SpeedyGo Customer Catalog Discovery Foundation v1.0

Status: **additive v1.2** — optional product `imageUrl` plus existing platform `CommerceVertical` listing/filter and storefront `coverImageUrl`. Prisma Schema v1.0 history is unchanged. Cart / Checkout / money contracts are unchanged.

This document is the Customer-facing **read projection** of Branch-owned Catalog. It is not a second writable Catalog domain.

## Objective

Authenticated Customers discover eligible storefronts, browse orderable catalog content, search bounded public text fields, and obtain the exact `productId` accepted by Cart — without deep-linking undocumented database IDs.

## Storefront entity (RBC)

**Storefront = `MerchantBranch`.**

Evidence:

- `Cart.merchantBranchId` is required
- `Category` / `Product` are Branch-owned
- Checkout / Order bind the cart’s Branch

`Merchant` remains the legal / verification identity (`status`, `verifiedAt`, name, `publicReference`). One Merchant may own multiple Branches; discovery lists each eligible Branch separately and does not flatten Merchant↔Branch ownership.

## Authority

All routes require:

1. Valid JWT / Session (`AuthGuard`)
2. Existing `CustomerProfile` for `principal.accountId`

`customerId` is never accepted from query, params, or body. Merchant / Driver accounts without a CustomerProfile receive `CUSTOMER_PROFILE_NOT_FOUND` (same pattern as Cart). There is no public unauthenticated catalog surface in v1.0.

## Visibility predicate

### Storefront visible

```
Merchant.status = ACTIVE
AND Merchant.verifiedAt IS NOT NULL
AND length(btrim(Merchant.name)) > 0
AND MerchantBranch.operationalStatus = ACTIVE
```

This matches `isStorefrontCustomerVisible` / Branch-scoped operational readiness. Opening hours are **not** modeled; `ACTIVE` ≠ openNow.

### Product / category visible

```
storefront visible
AND Category.active = true
AND Product.available = true
```

Equals `isProductCustomerOfferable` with `merchantOperationalReady` derived from the same storefront predicate for that Branch.

Fail-closed: ineligible detail routes return `CUSTOMER_STOREFRONT_NOT_FOUND` / `CUSTOMER_PRODUCT_NOT_FOUND` without revealing internal existence.

Categories listed for a storefront are active categories that have at least one available product.

## Routes (implemented)

Prefix: `/api/v1/customer`

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/commerce-verticals` | Active platform Home categories |
| GET | `/branches` | Paginated eligible storefronts (`verticalId?`) |
| GET | `/branches/:branchId/cover` | Stream the bound cover image when present |
| GET | `/branches/:branchId` | Storefront detail |
| GET | `/branches/:branchId/categories` | Categories with orderable content |
| GET | `/branches/:branchId/products` | Paginated orderable products (`categoryId?`) |
| GET | `/branches/:branchId/products/:productId` | Product detail + option groups |
| GET | `/branches/:branchId/products/:productId/image` | Stream the bound product photograph when present |
| GET | `/catalog/search` | Bounded search (`q`, pagination) |

## Response contracts (safe fields)

### Storefront

`branchId`, `branchName`, `addressText`, `latitude`, `longitude`, `merchantId`, `merchantName`, `merchantPublicReference`, `coverImageUrl` (null when no cover)

Omitted: phone, email, verification docs, statuses, commission, settlement, members, Admin notes, private object keys.

`coverImageUrl` is the authenticated Customer path `/customer/branches/:branchId/cover`. It is never a storage credential, `sg-object:` locator, or verification document URL.

Filtered `GET /branches?verticalId=` returns visible branches **explicitly classified** to that **active** vertical. Unfiltered `GET /branches` keeps the existing visibility predicate and includes unclassified branches and branches whose vertical is deactivated.

### Product

`productId` (**Cart add-item ID**), `branchId`, `categoryId`, `name`, `description`, `priceMinor` (decimal **string**), `imageUrl` (null when no product image is bound)

`imageUrl` is the authenticated Customer path `/customer/branches/:branchId/products/:productId/image`. It is never a storage credential, branch cover, `sg-object:` locator, or verification document URL. Product search hits use this field; they must not reuse `coverImageUrl`.

Detail also returns option groups/options with `additionalPriceMinor` strings. Options retain `available` flags; Cart remains the live option validator.

### Search hits

Discriminated union:

- `{ type: 'STOREFRONT', storefront }` — matches Branch name or Merchant name
- `{ type: 'PRODUCT', product, storefront }` — matches Product name

Order: `hit_type ASC`, `name ASC`, `id ASC`.

## Cart compatibility

`productId` in discovery responses is `Product.id` — the same field required by `POST /api/v1/customer/cart/items`. No mapping layer.

## Price authority

Discovery `priceMinor` is informational current `Product.priceMinor` (Catalog-owned). Serialized via `moneyMinorToDecimalString` (no `Number(bigint)`).

Checkout remains authoritative for eligibility, delivery pricing, discounts, and `OrderFinancialSnapshot`. Discovery never freezes prices or posts ledger entries.

## Search semantics

| Rule | Value |
| --- | --- |
| Pipeline | typeof → trim → remove `%` `_` `\` → trim → length 2..100 → repository |
| Wildcard policy | **B — remove** LIKE metacharacters (not escape-as-literal) |
| Match | case-insensitive `ILIKE` contains on normalized term |
| Entities | storefront (branch/merchant name), product name |
| Pagination | DB-side limit/offset |
| Ranking | none (deterministic lexical order only) |

Wildcard-only / space+wildcard / single-character-after-strip queries are rejected with `CUSTOMER_SEARCH_QUERY_INVALID` and never execute the repository as `ILIKE '%%'`.

## Pagination / sorting

- Default limit 50, max 100, max offset 10_000
- Allowlisted sort: `name` only (default)
- Clients cannot submit SQL column names

## Location / delivery eligibility

Platform delivery zones are **not** Merchant/Branch-owned. Discovery does **not** claim nearby / deliverable / distance / ETA / delivery fee. Customers may browse; Checkout revalidates zone coverage for the Customer address.

## Opening hours

Not implemented. Responses never include `openNow`, `closesAt`, `openingHours`, or time-based `acceptingOrders`.

## Images / storage

Optional one cover per `MerchantBranch` (`merchant_branch_covers`). Bytes live in ObjectStorage namespace `covers/` with locator `sg-cover:v1:<32-hex>`.

Optional one photograph per `Product` (`product_images`). Bytes live in ObjectStorage namespace `product-images/` with locator `sg-product-image:v1:<32-hex>`. Customer reads require the same product visibility as discovery.

Verification documents remain `permanent/` + `sg-object:v1:` and are never exposed on discovery.

Merchant branch logos (`logos/`, `sg-logo:v1:`) are Merchant-only and have no Customer field or route ([MERCHANT_BRANCH_LOGO_FOUNDATION.md](./MERCHANT_BRANCH_LOGO_FOUNDATION.md)).

## Promotions

Catalog storefront payloads still omit promotions. Customer Home banner uses a separate authenticated discovery contract:

- `GET /api/v1/customer/promotions` — offers **explicitly** published for Customer discovery (`customerDiscoverable=true`) that are currently effective (`active` and `startsAt <= now < endsAt`).
- Existing promotions remain undisclosed by default.
- Safe fields only: `id`, `code`, `discountKind` (`FIXED_MINOR` | `RATE_BPS`), `value` (same units as `Promotion.value`), window, optional `customerLabel`, `eligibility=DISCOVERABLE`.
- Funding / Admin `type` / `customerDiscoverable` / internals are omitted.
- Discovery is **not** cart eligibility. Without a cart, the API never guarantees that a code will apply. Checkout preview remains authority.
- The read never reserves usage or creates `PromotionRedemption`.
- Results are bounded (default/max 20) and ordered by `endsAt ASC`, `id ASC`.

See [PROMOTIONS_FOUNDATION.md](./PROMOTIONS_FOUNDATION.md).

## Privacy

Responses omit Customer PII of others, Merchant phone, verification evidence, bank/settlement data, passwords, AuditLog metadata, private object keys. Cross-Merchant product IDs under the wrong Branch fail closed.

## Performance

DB-side filters and pagination. Option groups for product detail: one groups query + one options `IN` query (no per-group N+1). PostgreSQL remains authoritative; no Redis catalog cache.

## Errors

| Code | When |
| --- | --- |
| `AUTH_INVALID_TOKEN` | Missing/invalid JWT |
| `CUSTOMER_PROFILE_NOT_FOUND` | Authenticated Account without CustomerProfile |
| `CUSTOMER_STOREFRONT_NOT_FOUND` | Branch missing or not visible |
| `CUSTOMER_PRODUCT_NOT_FOUND` | Product missing, wrong Branch, or not offerable |
| `CUSTOMER_SEARCH_QUERY_INVALID` | Search q invalid (service path) |
| `CUSTOMER_CATALOG_INVALID_PAGINATION` | Invalid sort/pagination (service path) |
| `COMMERCE_VERTICAL_NOT_FOUND` / `COMMERCE_VERTICAL_INACTIVE` | `verticalId` missing or inactive |
| `STORAGE_OBJECT_MISSING` | Visible storefront has no bound cover |
| Validation `400` | DTO bound failures (limit/offset/q length) |

## Related

- [CUSTOMER_CATALOG_DISCOVERY.md](../business-rules/CUSTOMER_CATALOG_DISCOVERY.md)
- [CATALOG_FOUNDATION.md](./CATALOG_FOUNDATION.md)
- [CART_FOUNDATION.md](./CART_FOUNDATION.md)
- [CHECKOUT_FOUNDATION.md](./CHECKOUT_FOUNDATION.md)
- [API_CONVENTIONS.md](../api/API_CONVENTIONS.md)
