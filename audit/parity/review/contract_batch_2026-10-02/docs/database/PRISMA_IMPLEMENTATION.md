# SpeedyGo Prisma Schema v1.0 — implementation notes

**Status: FROZEN with ERD v1.0.** Prisma Schema **v1.1** is an additive evolution (`CartItemOption` / `cart_item_options`) and does not rewrite v1.0 history.

Physical design authority remains [ERD.md](./ERD.md). This file records Prisma 8 adaptations only.

## Canonical schema

Prisma 8 is **contract-first**. There is one executable schema:

```
apps/backend/prisma/contract.prisma
```

Do **not** add `schema.prisma` or `@prisma/client`. Emitted artefacts:

- `prisma/contract.json`
- `prisma/contract.d.ts`

Runtime client: `prisma/db.ts` → `getDb()`.

Commands:

```bash
cp .env.example .env
docker compose up -d
pnpm contract:emit
pnpm prisma:migrate:plan   # prisma migration plan --name <slug>
pnpm prisma:migrate        # prisma db migrate
pnpm prisma:verify         # prisma db verify
```

Initial migration: `migrations/app/20260901T0054_init_speedygo_v1`  
PostGIS enablement: `migrations/postgis/20260601T0000_install_postgis_extension` (`CREATE EXTENSION IF NOT EXISTS postgis`).  
Prisma Schema v1.1: `migrations/app/20260901T1312_cart_item_options` (`cart_item_options`; CartItem CASCADE, ProductOption CASCADE join-only).  
Commerce verticals + storefront covers: `migrations/app/20260908T1956_commerce_verticals_and_covers` (additive; no financial rewrite).  
Product photographs: `migrations/app/20260909T0234_product_images` (additive `product_images`; no financial rewrite).  
Refund origin + paid-terminal intent: `migrations/app/20260906T1108_refund_request_origin_paid_terminal_intent`.  
Algeria Wilaya/Commune catalogue + nullable branch FKs: `migrations/app/20260920T1326_algeria_wilaya_commune` (additive; legacy branches keep null pair).  
Merchant contract-completion batch: `migrations/app/20261002T1907_merchant_contract_completion_batch` (additive; no financial table touched). See [Merchant contract-completion batch models](#merchant-contract-completion-batch-models).

## Merchant contract-completion batch models

Migration `20261002T1907_merchant_contract_completion_batch`: contract hash `0cb52e95…` → `8f14779e…`, `migrationHash` `24a95c1a89e39ebb31855371dd2d0f448825818cacf65dbb1cd87f99f7a08fcc`. 15 additive operations, no data rewrite, no dropped or altered column.

| Prisma model / field | Table / column | Notes |
| --- | --- | --- |
| `MerchantBranchLogo` | `merchant_branch_logos` | `branchId @unique` (`merchant_branch_logos_branch_id_key`), FK → `merchant_branches` RESTRICT; CHECKs `byte_size > 0`, `width_px > 0`, `height_px > 0` |
| `MerchantBranchHoursException` | `merchant_branch_hours_exceptions` | `localDate DateString`; unique index `(branch_id, local_date)` (`mbhe_branch_local_date_uq_*`); FKs → `merchant_branches` and `accounts` RESTRICT; CHECKs `version >= 1`, non-blank `label` |
| `MerchantBranchHoursExceptionInterval` | `merchant_branch_hours_exception_intervals` | FK → exception CASCADE; index `(exception_id, sort_order)`; CHECKs minute ranges, `sort_order >= 0`, same-day (`closes_next_day` only with `closes_minute = 0`) |
| `Product.duplicateRequestKey` | `products.duplicate_request_key` | `VarChar(64)?`, `@unique` (`products_duplicate_request_key_key`); NULL for every pre-existing row |

The planner also emits plain indexes on the foreign-key columns (`exception_id`, `branch_id`, `updated_by_account_id`). Physical names carry a planner hash suffix; the ERD lists the logical columns.

## UUIDv7

Columns are PostgreSQL `uuid` (`Uuid` in PSL). There is **no** `@default(uuid())` (that would be UUIDv4).

The future backend must generate **UUIDv7** before insert. No generator is implemented in this task.

## Money / BigInt

Authoritative amounts are `BIGINT` / Prisma `BigInt`. Rates are `Int` basis points.

**Future API note:** `JSON.stringify` cannot serialize `bigint`. NestJS DTOs must convert minor units deliberately (string or number after explicit policy). Do **not** change columns to Float.

## Timestamps

Storage is `timestamptz(6)` UTC.

Prisma 8 field type is `TimestamptzString(6)` (ISO strings), not Temporal and not Prisma 6 `DateTime @db.Timestamptz`. This avoids a Temporal polyfill in Nest bootstrap.

Local pricing windows: `TimeString` → PostgreSQL `time`.  
Document expiry: `DateString` → PostgreSQL `date`.

## Coordinates

ERD listed `DOUBLE PRECISION`. Prisma implementation uses `Numeric(9, 6)` for latitude/longitude so geo points are not binary floats. Same precision on `addresses`, `merchant_branches`, and `order_delivery_address_snapshots`.

## PostGIS

`delivery_zones.geometry` is authored as `postgis.Geometry(4326)` because `@prisma/orm-extension-postgis` 8.0.0-rc.8 only accepts an SRID argument and always renders `geometry(Geometry, 4326)`. The live column **must** match that typmod. Do not alter it to `geometry(MultiPolygon, 4326)` — that creates contract/database drift and fails `prisma db verify`.

A DeliveryZone is a coverage **area**. MultiPolygon + SRID 4326 are enforced by a Prisma-owned CHECK (column is `NOT NULL`):

```sql
CHECK (
  GeometryType(geometry) = 'MULTIPOLYGON'
  AND ST_SRID(geometry) = 4326
)
```

Repeatable procedure (local `speedygo_dev` included):

```bash
pnpm contract:emit
pnpm prisma:migrate:plan -- --name <slug>   # only when the contract changed
pnpm prisma:migrate
pnpm prisma:verify
```

Do **not** run ad-hoc typmod SQL after migrate. A previous `alter_typmod.sql` workaround is retired.

`geometry_columns.type` may still read `MULTIPOLYGON` after this: PostGIS fills that view from a `GeometryType(...) = 'MULTIPOLYGON'` CHECK when the typmod is generic `Geometry`. That is catalog inference, not a MultiPolygon typmod. Prisma verify compares `format_type` → `geometry(Geometry,4326)`.

- Extension install is a planned migration (`CREATE EXTENSION IF NOT EXISTS postgis`).
- GIST index: `delivery_zones_geometry_gist_*`.
- Local Compose image is built from `postgres:16-alpine` + PostGIS 3.5.7 (`docker/postgres-postgis/`).
- Zone queries may use the PostGIS operators on the Prisma 8 SQL/ORM client. Complex spatial work can still use raw SQL.

Do not store zone polygons as JSON. Point / LineString / Polygon / non-4326 inserts are rejected by PostgreSQL.

## Enums

Frozen status machines are Prisma **text-backed enums** (`@@type("pg/text@1")`): TEXT + CHECK, **not** PostgreSQL `ENUM`.

Unfrozen codes (COD status, document type, …) stay `VarChar(64)`.

## Partial uniques and CHECKs

Declared on the contract (`@@index(..., unique: true, where: ...)` and `@@check`). The planner emits them. Prisma application validation does not replace them.

## Immutable snapshot

`order_financial_snapshots` is write-once in the domain. Prisma can `UPDATE`. Future repositories must not expose arbitrary snapshot mutation. Corrections: refunds, settlement lines, ledger reversals.

## Ratings

Domain `Rating` → tables `driver_ratings` and `merchant_ratings` (ERD decision). Prisma models `DriverRating` / `MerchantRating`.

## Not tables

`DriverLiveLocation` (Redis), Timer/Countdown (UI), HighDemandNotification (event).
