# Catalog product duplication — business rules

Companion to [CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md](../architecture/CATALOG_PRODUCT_DUPLICATION_FOUNDATION.md).

- Duplication is one server command, never a sequence of client calls.
- Only OWNER and MANAGER duplicate (`PRODUCT_MANAGE`). STAFF cannot.
- The copy lives in the source's Branch and Category and starts unavailable (`available=false`) until the Merchant reviews and enables it.
- The copy's configuration is the source's configuration at the time of the request: price, description, required choices, optional extras and option availability.
- History is never copied: no order items, carts, ratings, report figures or audit identity.
- The photograph is a separate copy of the bytes in a new object. Deleting or replacing either product's photograph never affects the other. A source without a stored photograph gives a copy without one (`imageCopied=false`).
- The original is not modified (not even `updatedAt`).
- All rows are written in one transaction: either the complete copy exists or nothing does.
- A retried request with the same `requestId` returns the copy already created. Concurrent identical requests (for example a double tap) produce exactly one copy. A new `requestId` makes a new copy on purpose.
- Money stays in integer minor units; no price is recomputed.
