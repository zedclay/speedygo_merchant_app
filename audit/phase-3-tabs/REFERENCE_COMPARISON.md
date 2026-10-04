# Phase 3 — reference comparison (five tabs)

Design SoT: `screens/MerchantScreens/<folder>/{screen.png,code.html}`.  
Status: **implementer_reviewed** — not human-accepted.

## Accueil ← `merchant_operational_dashboard_french`

| Aspect | Reference | Implementation | Match |
| --- | --- | --- | --- |
| Header name | Establishment title | Branch/merchant name | Partial (branch preferred) |
| Status pill | « Ouvert » | « Actif » for operational ACTIVE | Intentional — ACTIVE≠Ouvert; no hours API |
| Verification banner | Present when needed | Shown when `verificationAttentionRequired` | Yes |
| KPI row (ventes / commandes / temps) | Present | **Omitted** (no invent) | Gap documented |
| Status shortcuts | 4 tiles | Nouveaux / En prép. / Prêts / Livreur(—) | Partial |
| Active orders | Cards + CTA | Cards + Traiter/Ouvrir | Partial (no timer/item list) |
| Bottom nav | 5 tabs | 5 tabs | Yes |

## Commandes ← `active_orders_list_french` + `merchant_order_history_unified`

| Aspect | Reference | Implementation | Match |
| --- | --- | --- | --- |
| En cours / Historique | Segmented | Preserved | Yes |
| Status chips | Per-state | Mapped to AND query | Yes |
| Empty Nouvelles | Filter-specific | « Aucune nouvelle commande » | Yes |
| Cards | Rich | Existing phase-2 cards | Prior work |

## Catalogue ← `liste_des_produits_standardis_e` + `liste_des_cat_gories_standardis_e`

| Aspect | Reference | Implementation | Match |
| --- | --- | --- | --- |
| Produits / Catégories | Segmented | Yes | Yes |
| Search + chips | Yes | Yes (no filter sheet) | Partial |
| Availability switch | Yes | PATCH `available` | Yes |
| FAB Ajouter | Yes | **Omitted** (no create contract wired) | Gap |
| Product photos | Yes | Placeholder icon | Partial |

## Rapports ← `merchant_reports_overview_french`

| Aspect | Reference | Implementation | Match |
| --- | --- | --- | --- |
| Period chips | Interactive | Display-only (no period API) | Partial |
| Finance card | Numbers | Unavailable state | Gap |
| Ratings | In design mix | Real `ratingsSummary` | Yes |
| Settlements | Not in mock | Real list / forbidden / empty | Extra supported |
| Trend / top products | Charts/list | Unavailable states | Gap |

## Profil ← `merchant_settings_french` (+ logout)

| Aspect | Reference | Implementation | Match |
| --- | --- | --- | --- |
| Entry | Paramètres | `ProfileSettingsScreen` | Yes |
| Role label | Human | Propriétaire / … | Yes |
| Merchant name | Real | Finjan preserved | Yes |
| Menu depth | Many rows | Only supported: account info, branch status, switch, logout | Partial by design |
| store_profile_french | Hero store UI | Not tab entry | Correctly not combined |

## Discrepancies screen.png vs code.html

None blocking recorded for these folders in this pass; layout followed `screen.png` hierarchy with `code.html` spacing/typography cues where compatible with real data.
