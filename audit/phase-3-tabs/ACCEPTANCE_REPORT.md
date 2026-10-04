# Phase 3 — five main tabs (implementer review)

**Status:** `implementer_reviewed` — visual acceptance pending human review.  
**Identity correction:** Desktop 14:18 screenshots were **Customer**, not Merchant. See `APP_IDENTITY_DISCREPANCY.md`. Prefer captures in `live-verified/`.

**Scope:** Accueil, Commandes, Catalogue, Rapports, Profil only.  
**Out of scope preserved:** splash/onboarding, phone/OTP, registration, access gates, order detail ops.  
**Not modified:** Customer, backend, schema, `.env`, Finjan data.


## Profile entry screen (from references)

| Reference | Role |
| --- | --- |
| `merchant_settings_french` | **Profil tab entry** — Paramètres hierarchy + Déconnexion |
| `store_profile_french` | Store public profile (not the tab landing; no dead nav to unsupported editors) |
| `merchant_logout_french` | Logout confirm pattern (wired via existing session logout) |

## Implemented surfaces

| Tab | Screen | Wired behaviour |
| --- | --- | --- |
| Accueil | `HomeScreen` | Branch header, `Actif`≠Ouvert, counts via `list.total` with **orderStatus∧fulfillmentStatus**, active order cards, shortcuts → Commandes filters |
| Commandes | `OrdersScreen` | En cours / Historique preserved; filter-specific empty copy; loading/error bodies |
| Catalogue | `CatalogScreen` | Products/categories, search, availability PATCH; empty vs error |
| Rapports | `ReportsScreen` | Ratings + settlements when allowed; finance/trend/top = designed unavailable |
| Profil | `ProfileSettingsScreen` | Avatar/role (`Propriétaire`), branch, switch-branch if multi, logout confirm |

## Terminal-order filter verification (backend read-only)

**Observed:** merchant reject sets `status=CANCELLED` while keeping `fulfillmentStatus=PENDING_ACCEPTANCE` (`order.repository` reject path).  
**Implication:** fulfillment-only En cours / Home queries **would** include cancelled rows.  
**Merchant fix (this phase):** active chips and Home counts/lists now send matching `orderStatus` **and** `fulfillmentStatus` (AND on server). History remains `orderStatus` only. Backend unchanged.

## Exact API / functionality gaps

| Gap | Evidence | UI treatment |
| --- | --- | --- |
| Store open/closed hours (`Ouvert`) | No merchant hours read/write used in app | Show operational `Actif` / inactive labels only — never invent Ouvert |
| Home KPI row (ventes, temps moyen) | No sales/avg-prep contract | Omitted |
| Livreur count | No courier queue for merchant | Tile shows `—`, non-interactive |
| Accept countdown timer | No server TTL on list | Omitted |
| Catalog add/edit/delete product, media, unit labels | Write APIs beyond `available` not wired | No FAB / overflow menu |
| Reports finance summary, period aggregates, trend, top products | No merchant report aggregate endpoints | Unavailable cards; period chips display-only |
| Settlements for STAFF | 403 `MERCHANT_ROLE_FORBIDDEN` | Dedicated forbidden copy |
| Profile: team, security, hours, delivery zone, help/legal | No destinations | Omitted (no dead rows) |
| Store profile editors / customer preview | Separate reference; no contracts | Not linked from Profil tab |

## Supported interactions actually wired

- Home refresh; shortcut navigation to Commandes filters; open order detail  
- Commandes segments/filters, refresh, open detail, existing mutations (unchanged)  
- Catalog refresh, category chips, search, availability toggle  
- Reports refresh; ratings summary; settlements list (OWNER/MANAGER)  
- Profil switch branch (multi-branch); logout confirm → session clear  

## Captures

| Layer | Path |
| --- | --- |
| **Verified Merchant live (use these)** | `audit/phase-3-tabs/live-verified/live-*-pro.png` + `PROVENANCE.json` |
| Prior live (also Merchant UI; see identity note) | `audit/phase-3-tabs/live/` |
| Customer Desktop 14:18 (misread as Merchant) | `audit/phase-3-tabs/customer-desktop-14.18/` |
| Mocked SE/Pro/1.3 | `audit/phase-3-tabs/mocked/*.png` |
| Identity report | `APP_IDENTITY_DISCREPANCY.md` |
| Reference comparison | `REFERENCE_COMPARISON.md` |

## Tests (this pass)

- `flutter test test/audit/phase3_tabs_visual_capture_test.dart`  
- `flutter test test/features/phase1_flow_test.dart`  
- `flutter test test/features/order_list_visual_corrections_test.dart`  

## Customer preservation

Baseline start: `CUSTOMER_BASELINE_START.txt`  
End hashes (unchanged vs start):

```
c42620cff4ab3a572ae6d675a8a8f50f10bdd30effe3d317ae5564896f59a11d  apps/customer_app/lib/main.dart
e0a48c4cb2d7c17494459f305180a5796ebd92d4f276be0082200773b45cedb1  apps/customer_app/lib/features/auth/presentation/splash_screen.dart
```

No Customer code edits in this task.
