# Merchant Maps — final integration backlog

**Created:** 2026-10-09  
**Parity row:** 51 `store_map_location_french`  
**Parity-phase status:** `exception_approved` (external-integration deferral)  
**Not:** Maps `user_accepted` · not Merchant `release_ready` · not SpeedyGo project-complete

## User decision (2026-10-09)

Complete functional development of Merchant, Driver, Admin, and Customer first.  
Configure and activate external APIs and providers together during the **final integration phase**.

That deferred phase includes (non-exhaustive): Google Maps Platform (Maps SDK Android/iOS, Places API, Geocoding API), production SMS/OTP, FCM/APNs, payment providers, email and other external services, plus production API keys, billing, quotas, and credentials.

**Planned future Maps direction:** Google Maps Platform — **not configured or activated now.**

## Current implemented state (parity phase)

- `LocationPickerScreen` (`lib/features/access/presentation/location_picker_screen.dart`)
- French and Arabic UI strings for picker / GPS / invalid coordinates
- GPS permission and current position via `geolocator` (`LocationClient`)
- Pan / zoom (`flutter_map`; rotate disabled)
- Center-pin coordinate selection (map moves under pin)
- Latitude / longitude confirmation (`LocationPickResult`)
- Backend branch-coordinate persistence (`PATCH` branch lat/lng from `StoreAddressScreen`)
- Configurable tile URL: `--dart-define=MAP_TILE_URL_TEMPLATE=…`
- Development-only OSM public-tile fallback (OSMF policy → **not** production-approved)
- Map-card polish: cover thumb / storefront placeholder, branch label, address preferred over painted coords
- `MerchantMapConfig.addressSearchSupported == false`

## Deferred Google Maps / Places / Geocoding work

- Google Cloud project
- Billing account
- Maps SDK for Android
- Maps SDK for iOS
- Places API (New) — address autocomplete
- Geocoding API — forward and reverse
- Restricted development and production API keys
- Android application restrictions (package name + SHA)
- iOS bundle-ID restrictions
- Backend / server-key restrictions where applicable
- Secure configuration **outside Git** (no keys in source)
- Address autocomplete UI wired to Places
- Forward geocoding
- Reverse geocoding
- French and Arabic result presentation
- Algeria country bias / filter
- Request cancellation and debounce
- Quota and billing alerts
- Privacy policy and map attribution updates for the chosen provider
- iOS and Android live tests against the production provider
- Final screenshots and explicit acceptance where required

## Explicitly unsupported until a domain contract exists

Do **not** fabricate:

- Pickup entrance hint (“Entrée côté retrait” / equivalent)
- Owner footer (“Propriétaire : …”)
- Invented branch-owner display names

These remain omitted.

## Reopening / completion criteria (Maps backlog)

The external-integration backlog for row 51 is complete only when **all** of the following hold:

1. A production map/geocoding provider is configured (planned: Google Maps Platform).
2. Keys and credentials are secured outside the repository.
3. Real address search / autocomplete works end-to-end.
4. Coordinates and the displayed address remain consistent.
5. French and Arabic work for search and related copy.
6. Android and iOS live tests pass against the configured provider.
7. Cost / quota protections exist (alerts, restrictions).
8. Evidence is reviewed.
9. Explicit acceptance occurs where the product process requires it (`user_accepted` / release gates — separate from this parity exception).

Until then: row 51 stays an **approved parity-phase exception**, not an implemented Maps verification.
