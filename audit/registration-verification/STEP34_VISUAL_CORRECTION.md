# Step 3–4 visual correction (implementer_reviewed)

**Status:** `implementer_reviewed` — not pixel-perfect; not registration-accepted.  
**Scope:** Merchant app only. Finjan untouched. No commit/push. Customer porcelain unchanged vs baseline.

## Concrete differences addressed

### Documents (`business_document_upload_french`)
| Reference | Before Flutter | After Flutter |
| --- | --- | --- |
| Compact progress + “Étape 3 sur 4” + % | Progress + **dev nav disclaimer** | Compact progress + %; disclaimer removed |
| Title + establishment context line | API/RC-NIF explanatory body | “Ajoutez les documents demandés.” + `Établissement : {name}` |
| Horizontal cards: thumb, title, status, compact action | Tall stacked cards + full-width “Ajouter un fichier” | Compact row cards + `+ Ajouter` / edit replace |
| Tips + formats | Missing / buried in API copy | Tips card + formats line |
| Sticky continue | Present | Sticky continue + scroll clearance |

**Not copied from prototype:** RC/NIF statutory titles; 5 Mo limit (contract remains 10 Mo); locked-doc padlock sequencing.

### Establishment (`store_information` / category / address / map)
| Reference | Before Flutter | After Flutter |
| --- | --- | --- |
| Section cards with icons | Flat fields + **large API limitation cards** | Identity / contact / category / address sections |
| Bilingual name + description + email | Unsupported fields shown as API notes | Omitted (cannot save) |
| Category picker route | “blocked” explanation card | Read-only section (gap tracked) |
| Map confirm route | “map not configured” card | Manual address + lat/lng (gap tracked) |
| Customer preview with rating/ETA/open | Fake-prone preview used merchant name as branch | Truthful preview of **entered** branch/address/phone only |

**Name empty vs Finjan:** merchant `name` ≠ branch `name`. Commerce shown read-only; branch field labeled separately and hydrated only from branch entity.

## “Validé” mapping

Backend checklist fields (read-only semantics used):

| Field | Meaning | UI label |
| --- | --- | --- |
| `present=false` | No bound evidence | **Manquant** |
| `present=true`, `status` ≠ SUBMITTED | File bound / attached | **Ajouté** |
| `status=SUBMITTED` | Submitted with dossier for review | **En examen** |
| `complete=true` | Technical readiness for submit (bound + optional expiry OK) | **Not** approval — still **Ajouté** or **En examen** |

There is **no** document-level admin-approved flag. **Validé** is never shown for evidence items.

Regression: `test/features/evidence_presentation_test.dart` — `item states never treat complete/present as administrative Validé`.

## Remaining functional gaps (not visual defects)

1. Merchant **cannot select** commercial category (admin attribution).
2. **No interactive map** / geocoder / confirm endpoint in Merchant contract — manual coordinates only.
3. No Arabic branch name, establishment description, or branch email fields on API.
4. Distinct category/address/map **routes** from reference are not separate navigators; sections live on step 4 with truthful read-only/manual substitutes.
5. Widget-test captures may still show a washed primary-button label glyph (test rendering); live app uses Inter + explicit onPrimary text.

## Captures

- Before: `captures/before-step34/`
- After: `captures/reg-documents-*.png`, `reg-establishment-*.png`, `reg-documents-mixed-*.png`, `reg-location-manual-*.png`, …
- Comparisons: `captures/comparisons/` (`before_after_*`, `docs_*`, `estab_*`)

## Verification

| Check | Result |
| --- | --- |
| `dart analyze lib test` | exit **0** — **0** errors, **0** warnings, **22** infos |
| `flutter test` evidence + registration_flow + registration_capture | exit **0** |
| Customer `git status --porcelain` vs `/tmp/customer_porcelain_viz.txt` | **unchanged** (diff exit 0) |
