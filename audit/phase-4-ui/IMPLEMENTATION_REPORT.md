# Phase 4 — Implementation report

**Date:** 2026-09-19  
**App:** Merchant `com.speedygo.speedygoMerchantApp` (`apps/merchant_app`)  
**Device:** iPhone 17 Pro simulator `4A1C3481-8B8E-48BD-983D-03896884EF09`  
**API:** `http://127.0.0.1:3000/api/v1`  
**Visual status:** implementer reviewed (not user accepted)  
**Customer:** file hashes unchanged vs `CUSTOMER_BASELINE_START.txt` (157 dart files)

---

## 1. Screens implemented or corrected

| Area | Change |
| --- | --- |
| Shared chrome | `MerchantLayout` tokens, `MerchantStatusPill`, `MerchantNavRow`, `MerchantStickyBar`, tertiary switch colors |
| Accueil | Compact header, Actif≠Ouvert pill, order shortcuts, active cards, unread badge on bell, removed false “à l’instant” sync claim |
| Commandes | Incoming left accent, denser cards; En cours/Historique AND filters preserved |
| Catalogue | Description + category label on rows, richer thumb chrome |
| Rapports | Finance unavailable as 2×2 metric skeleton (—), period hint (non-interactive) |
| Profil | `store_profile_french` hub: cover gradient hero, identity card, grouped nav; settings nested |
| Horaires | GET/PUT opening hours screen |
| Notifications | Day-grouped inbox + mark-read |
| Settings / logout | Nested under Profil; dead rows omitted |

---

## 2. Reference → route → visual → functional

See `audit/phase-4-ui/SCREEN_MATRIX.md` (full matrix). Summary:

| Family | Visual | Functional |
| --- | --- | --- |
| Five-tab shell | implementer reviewed | wired and verified |
| Dashboard / notifications / hours | implementer reviewed | wired (hours/notif live unverified beyond route) |
| Orders list + detail ops | implementer reviewed | wired and verified |
| Prep ETA / delay / handoff / call | needs correction | blocked |
| Catalogue list + availability | implementer reviewed | wired and verified |
| Catalogue CRUD / image crop | needs correction | blocked (client forms) |
| Store profile hub | implementer reviewed | wired and verified |
| Sales aggregates | needs correction | blocked |
| Settings / logout | implementer reviewed | wired and verified |

---

## 3. Screenshots & comparisons

| Kind | Path |
| --- | --- |
| Live Merchant (Pro) | `audit/phase-4-ui/live/live-{home,orders,catalog,reports,profile}-pro.png` + `IDENTITY.txt` |
| Mocked widget captures | `audit/phase-4-ui/mocked/` (375×667 SE + Pro + textScale 1.3) |
| Ref vs live side-by-side | `audit/phase-4-ui/comparisons/{home,orders,catalog,reports,profile}_ref_vs_live.png` |

Live home shows Finjan Coffer, **Actif**, tabs Accueil / Commandes / Catalogue / Rapports / Profil — not Customer Accueil/Recherche/….

---

## 4. Interactions verified & data sources

| Interaction | Source | Evidence |
| --- | --- | --- |
| Tab navigation | shell routes | live captures + phase1/phase3 tests |
| Home counts / active list | orders API AND filters | tests + live empty Finjan |
| Accept / reject / prep / ready | order mutations | prior phase2 + order tests |
| Catalog availability toggle | PATCH catalog | catalog controller + tests |
| Opening hours load/save | GET/PUT hours | controller + FakeMerchantApi |
| Notifications list / unread | notifications API | FakeMerchantApi + UI |
| Logout | session clear | settings screen + phase1 |
| Ratings / settlements | reports API | reports screen |

---

## 5. Remaining gaps / blockers

1. Merchant-writable Ouvert/Fermé & temporary closure — no contract  
2. Prep-time on accept / update ETA / delay — no contract  
3. Sales / daily / popular aggregates — no contract  
4. Staff management, exceptional hours — no/partial contract  
5. Driver call / secure handoff — no Merchant mutation  
6. Catalog create/edit/upload UI — backend partial; client forms not shipped  
7. Cover/logo upload UI — cover API exists; UI not wired  
8. Customer preview on profile — unavailable by design  

---

## 6. Tests & analysis

| Check | Result |
| --- | --- |
| `phase3_tabs_visual_capture_test` + `phase1_flow_test` + `order_list_visual_corrections_test` | All passed (35) |
| `flutter analyze lib` | 27 info-only (no errors/warnings) |
| Live identity | Merchant bundle confirmed; Customer still installed |

---

## 7. Launch identity & Customer unchanged

```
merchant_bundle=com.speedygo.speedygoMerchantApp
merchant_display=Speedygo Merchant App
customer_bundle=com.speedygo.speedygoCustomerApp
CUSTOMER_UNCHANGED (157 paths, hashes match start)
```

Human visual acceptance remains separate from this implementer review.
