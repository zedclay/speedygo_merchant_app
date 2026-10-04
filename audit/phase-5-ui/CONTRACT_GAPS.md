# Phase 5 — contract gaps (exact)

Separate from Flutter work shipped for catalog CRUD, cover, address, and Phase 5b layout/media messaging.

## Backend / domain absent

1. **Merchant sales aggregates** — no endpoint for period GMS / commission / net / order counts / prep averages / cancellations / trends / top products.
2. **Period query params** for such aggregates — N/A until (1) exists.
3. **Store logo** — no `.../logo/content` or bind route (branch **cover** exists).
4. **Merchant-authenticated media read** — Product image: **Resolved** (`GET …/products/:id/image` + `hasImage`). Branch cover: **Resolved** (`GET …/branches/:branchId/cover`). Store **logo** still unavailable (no domain entity). See `MEDIA.md`.
5. **Product list image metadata** — `hasImage` on `CatalogProductSummaryResponseDto` / detail (**shipped**). Optional future: `imageUpdatedAt` / `hasCover` to avoid blind cover probes.
6. **Order summary line-item count** — list DTO lacks item summary for home cards.
7. **Ouvert/Fermé toggle, temporary closure, prep ETA, delay, staff, exceptional hours, driver call/handoff** — unchanged.

## Editor fields vs DTOs (exact)

| Surface | Supported (real API) | Documented unsupported (gap rows only) |
| --- | --- | --- |
| Product | `name`, `description`, `priceMinor`, `categoryId`, `available`; image upload/bind/delete + Merchant GET stream | AR name/desc, prep time, sale unit, variants, extras (UI: compact “Non disponible actuellement”) |
| Category | `name`, `active` (+ sortOrder if used) | AR name, category description |
| Address | `phone`, `addressText`, `latitude`, `longitude`, `wilayaCode`, `communeId` (+ map confirm) | Public contact |
| Cover | Cover upload/bind/delete + Merchant GET stream | Store **logo** (no merchant logo endpoint) |

## Frontend shipped against existing contracts

- Product POST/PATCH/DELETE, category POST/PATCH/DELETE  
- Product image POST content + PUT bind + DELETE + **GET stream (Merchant JWT)**  
- Branch cover POST content + PUT bind + DELETE + **GET stream (Merchant JWT)**  
- Remote display uses Dio Bearer bytes → `Image.memory` (not Customer routes, not public CDN)  
- Media epoch refresh after bind/delete/catalog reload to avoid stale thumbs  
- Branch PATCH address/lat/lng/wilaya/commune with map confirmation  
- Opening hours GET/PUT (prior phase)  
- Live API / UI evidence: `media-http/`, `media-live/` (see `MEDIA.md`)
