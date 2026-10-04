# Merchant map location picker

**Status:** implementer_reviewed (functional map flow delivered; tile provider config remains)

## Behaviour

| Action | Result |
| --- | --- |
| Address form | Labeled **Adresse exacte** + **Lieu de retrait** |
| Unconfirmed | **Choisir sur la carte** (no lat/lng text fields) |
| Confirmed | Summary + **Position confirmée** + **Modifier** |
| Picker | Full-screen `flutter_map`, centered store pin, zoom, **Utiliser ma position** |
| Confirm | Writes draft lat/lng + `locationConfirmed`; no server call |
| Back/cancel | Pops `null` — draft unchanged |
| Continue | Blocked with `regLocationRequired` until confirmed |
| GPS | Permission only after GPS tap; suggestion only; still requires Confirm |
| Address text | Never overwritten by picker (no geocoder) |

## Provider / configuration

| Item | State |
| --- | --- |
| Backend `GOOGLE_MAPS_API_KEY` | Declared, **empty** |
| Google Maps mobile SDK | **Not** wired in Merchant/Customer |
| Geocoding / Places | **None** → no address search |
| Interactive tiles | `flutter_map` + `MAP_TILE_URL_TEMPLATE` (default OSM public tiles) |

**Blocker for production tiles:** default OSMF public tiles are not licensed for unrestricted app use. Set a licensed template:

```bash
flutter run --dart-define=MAP_TILE_URL_TEMPLATE='https://your-tiles/{z}/{x}/{y}.png'
```

Optional future: provision `GOOGLE_MAPS_API_KEY` and adopt Google Maps SDK.

**Partial note:** GPS-only without pan would be insufficient (merchant may register away from the shop). This build always offers map pan selection; GPS is assistive.

## Native changes

- iOS `NSLocationWhenInUseUsageDescription`
- Android `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` / `INTERNET`
- Deps: `flutter_map`, `latlong2`, `geolocator`

## Tests (mocked)

`test/features/location_picker_test.dart` — confirm enable/disable, cancel preserve, GPS denied/forever/services/unavailable, continue blocked, hydrate confirmed, payload mapping.

`test/audit/registration_capture_test.dart` — choose / picker / confirmed captures.

## Real-device check (not automated here)

Full rebuild required for geolocator. Verify tiles load with network + licensed `MAP_TILE_URL_TEMPLATE` (or accept OSM policy for local only). Exercise GPS grant/deny on SE / Pro.

## Captures

- `captures/reg-location-choose-375x667.png`
- `captures/reg-location-picker-375x667.png`
- `captures/reg-location-confirmed-375x667.png`
- `captures/reg-establishment-location-summary-375x667.png`

Widget-test map tiles return HTTP 400 (test binding) — grey map canvas in captures is expected; device shows real tiles when network + template allow.
