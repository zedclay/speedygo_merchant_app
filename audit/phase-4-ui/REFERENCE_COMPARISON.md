# Phase 4 — reference vs implementation notes

Viewport for comparisons: 402×874 (Pro logical). Live captures on iPhone 17 Pro sim.
PNG = intended visual; HTML = layout evidence. Material conflicts recorded below.

## Home (`merchant_operational_dashboard_french`)
- Match: compact header, Actif pill (not Ouvert), 4 shortcut tiles, active-orders section, 5-tab bar.
- Diff: reference shows sample KPIs / “Ouvert” / sync clock — omitted (no contract / Actif≠Ouvert policy).
- Diff: Livreur tile shows "—" (unavailable), not a fabricated courier count.

## Orders (`active_orders_list_french`)
- Match: En cours / Historique, status chips, empty copy, Finjan branch subtitle.
- Diff: no search / Urgent; Acceptées chip retained (API-backed beyond some Stitch variants).

## Catalog (`liste_des_produits_standardis_e`)
- Match: Produits/Catégories, search, Tous chip, empty/populated rows.
- Diff: no FAB create; thumbs are placeholders (no product image field in model).

## Reports (`merchant_reports_overview_french`)
- Match: title, period chips chrome, section hierarchy, ratings + settlements.
- Diff: finance values are "—" with explicit unavailable copy (no aggregate API). Period chips non-interactive.

## Profile (`store_profile_french`)
- Match: cover+identity overlap, verified mark, Actif pill, grouped management rows, settings gear.
- Diff: cover is gradient placeholder (no live cover media); aperçu client unavailable; media/prep rows disabled with concise copy.
- Conflict PNG vs HTML: prototype food/cover photos are illustrative — never used as Finjan live media.

## PNG vs HTML conflicts (recorded)
- Several HTML stubs embed stock photography URLs absent from product; PNG compositions use those assets. Implementation uses placeholders / real branch data only.
