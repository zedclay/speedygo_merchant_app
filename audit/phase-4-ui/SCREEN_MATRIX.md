# Phase 4 — screen-to-route matrix (reference-accurate UI)

**Visual status vocabulary:** not reviewed / needs correction / implementer reviewed / user accepted  
**Functional:** wired and verified / wired but unverified / blocked  

Identity: Merchant `com.speedygo.speedygoMerchantApp` · Customer unchanged hashes in `CUSTOMER_BASELINE_*`.  
Evidence: `live/`, `mocked/`, `comparisons/`, `IMPLEMENTATION_REPORT.md`.

## Main shell

| Reference | Route / file | Visual | Functional | API | Remaining diffs |
| --- | --- | --- | --- | --- | --- |
| Five-tab shell | `MerchantShell` | implementer reviewed | wired and verified | n/a | — |
| `merchant_operational_dashboard_french` | `/app/home` `HomeScreen` | implementer reviewed | wired and verified | partial | No KPI ventes/temps; Actif≠Ouvert; unread badge on bell |
| `store_availability_control_french` | — | needs correction | blocked | no | Merchant cannot set Ouvert/Fermé |
| `temporary_closure_french` | — | not reviewed | blocked | no | No temporary-closure contract |
| `merchant_notification_center_french` | `/app/notifications` | implementer reviewed | wired but unverified | yes | Filters simplified; day groups present |

## Orders

| Reference | Route / file | Visual | Functional | API | Remaining diffs |
| --- | --- | --- | --- | --- | --- |
| `active_orders_list_french` | `/app/orders` | implementer reviewed | wired and verified | yes | No search / Urgent chips |
| `merchant_order_history_unified` | Historique segment | implementer reviewed | wired and verified | yes | No combined “Tout” |
| Detail / prep / ready / finance | `/app/orders/:id` | implementer reviewed | wired and verified | partial | No prep-time picker, countdown, call, handoff |
| `accept_order_and_preparation_time_french` | Accept CTA | needs correction | blocked | no | Prep ETA on accept |
| Prep/delay/handoff refs | — | not reviewed | blocked | no | Contracts absent |
| `signaler_un_probl_me_standardis` | — | needs correction | blocked | partial | Support ticket UI not composed |

## Catalogue

| Reference | Route / file | Visual | Functional | API | Remaining diffs |
| --- | --- | --- | --- | --- | --- |
| `liste_des_produits_standardis_e` | `/app/catalog` | implementer reviewed | wired and verified | partial | No FAB; placeholder thumbs (no image field) |
| Category list tab | same | implementer reviewed | wired and verified | yes | No reorder/CRUD forms |
| Product CRUD / variants / bulk / crop | — | needs correction | blocked / partial | yes (backend) | Client forms not shipped |

## Store profile & settings

| Reference | Route / file | Visual | Functional | API | Remaining diffs |
| --- | --- | --- | --- | --- | --- |
| `store_profile_french` | `/app/profile` `StoreProfileScreen` | implementer reviewed | wired and verified | partial | Cover gradient placeholder; aperçu client unavailable |
| `horaires_d_ouverture_pur` | `/app/profile/hours` | implementer reviewed | wired but unverified | yes | Exceptional hours blocked |
| `merchant_settings_french` | `/app/profile/settings` | implementer reviewed | wired and verified | partial | Dead rows omitted |
| `merchant_logout_french` | settings logout | implementer reviewed | wired and verified | yes | — |
| Logo/cover upload, staff, exceptional hours | — | needs correction | blocked / partial | partial | Cover API exists; UI not wired |

## Reports

| Reference | Route / file | Visual | Functional | API | Remaining diffs |
| --- | --- | --- | --- | --- | --- |
| `merchant_reports_overview_french` | `/app/reports` | implementer reviewed | wired and verified | partial | Finance tiles show — unavailable; ratings/settlements real |
| `daily_summary` / `popular_products` / `sales_summary` | — | needs correction | blocked | no | No aggregate contracts |

## Exact blockers (backend / product)

1. Merchant-writable open/close & temporary closure  
2. Prep-time on accept / update prep ETA / delay  
3. Sales/daily/popular aggregates  
4. Staff management  
5. Exceptional hours  
6. Driver call / secure handoff  
7. Catalog create/edit UI (API exists — remaining client work)  
8. Branch cover/logo upload UI (cover API exists)

Status: **implementer reviewed** — not user visually accepted.
