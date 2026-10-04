# Phase 5 — media completeness

## Status matrix (Merchant JWT)

| Step | Product image | Branch cover | Notes |
| --- | --- | --- | --- |
| Local preview | **Exercised** | **Exercised** | `Image.memory` after pick / debug inject |
| Upload content | **Exercised** (live Dar El Bahja) | **Exercised** (live) | `POST …/image/content`, `POST …/cover/content` |
| Bind | **Exercised** (live) | **Exercised** (live) | `PUT` bind with `uploadReference` |
| Reload metadata | **Exercised** (`hasImage`) | **Partial** | Cover has no `hasCover`; GET probes presence |
| Reopen editor | **Exercised** (Merchant GET) | **Exercised** (Merchant GET) | Live cover reopen screenshot; product GET proven over HTTP |
| Remote display / merchant read | **Exercised** | **Exercised** | Dio Bearer → bytes → `Image.memory` |
| Replace without stale cache | **Exercised** (HTTP byte change) | **Exercised** (HTTP + `merchantMediaEpoch`) | Epoch bumps on bind/delete/catalog reload |
| Delete cover → fallback | **N/A** | **Exercised** (HTTP `STORAGE_OBJECT_MISSING` + UI empty/fallback) | |
| Unauthorized access | **Exercised** | **Exercised** | No token → 401; foreign merchant → 404 |

## Explicit separation

- Bind / form save success is independent of later remote preview failures.
- Upload failure → `catalogImageUploadError` / `storeCoverUploadError`; bind not attempted.
- Bind failure after upload → `catalogImageBindPartial` / `storeCoverBindPartial`.
- Remote load failure → `catalogImageRemoteUnavailable` / `storeCoverRemoteUnavailable` + **Réessayer**; does not roll back a successful save.
- **No Customer token**, Customer session, or public URL is used to fetch Merchant media.

## Merchant product image read (contract)

`GET /api/v1/merchant/:merchantId/branches/:branchId/products/:productId/image`  
Requires Merchant JWT with `CATALOG_READ`. Streams bound `product-images/` bytes. Missing → `STORAGE_OBJECT_MISSING`.

Merchant product list/detail include `hasImage: boolean`.  
Bind response `imageUrl` is a **customer-relative** path for discovery clients — Merchant UI must not use it with a Merchant JWT.

## Merchant branch cover read (contract)

`GET /api/v1/merchant/:merchantId/branches/:branchId/cover`  
Requires Merchant JWT with `MERCHANT_READ`. Streams bound `covers/` bytes. Missing → `STORAGE_OBJECT_MISSING`.

Bind response `coverImageUrl` is likewise a customer-relative path.

## Layout / MerchantScreens

- Product image preview: **4/3** (`aspect-[4/3]` in MerchantScreens).
- Cover preview: **16/9** (`aspect-video`).

## Store logo

**Contract gap.** Domain model has storefront **cover** only — no separate logo object. UI keeps `Non disponible actuellement` for logo; do not invent a logo upload.

## Evidence locations

| Layer | Path |
| --- | --- |
| HTTP API | `audit/phase-5-ui/media-http/MEDIA_HTTP_EVIDENCE.json` |
| Live UI | `audit/phase-5-ui/media-live/MEDIA_LIVE_PROVENANCE.json`, `media-cover-reopened.png` |
| Report | `audit/phase-5-ui/MEDIA_LIVE_REPORT.md` |

## Customer baseline

Unchanged. Customer media routes remain customer-owned; Merchant must not reuse Customer auth for previews.
