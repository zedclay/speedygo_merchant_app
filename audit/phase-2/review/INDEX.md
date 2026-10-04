# Merchant Phase 2 — review package

**Status:** `implementer_reviewed` (not `human_accepted`)  
**Design source of truth:** `screens/MerchantScreens/<folder>/screen.png` + `code.html`  
**Inventory:** `../../docs/MERCHANT_UI_SOURCE_OF_TRUTH.md`  
**Pass:** Remaining visual corrections (compact refs, ready status, En cours/Historique + shell)  
**Catalogue:** paused  

Tests and this zip are **evidence**, not visual acceptance.

## How to read this package

| Folder | Kind | Meaning |
| --- | --- | --- |
| `live/` | **Live (historical)** | Prior SE synthetic session — not re-shot this pass |
| `mocked/` | **Mocked** | Widget fixtures SE 375×667 / Pro 402×874 / text scale 1.3 |
| `references/` | Reference | Stitch `screen.png` exports |
| `structure/` | Side-by-sides | Flutter vs reference at equivalent widths |

---

## 1. Corrections this pass

### A. Compact order references
- Secondary typography (bodySmall, muted, weight 500)
- Ellipsis + tap opens sheet with **full canonical** `publicReference` + copy
- Never invents `#SG-…`; routing/API still use order `id`

### B. Ready screen — one status section
- Single “Commande prête” pill with check icon
- Compact order summary below
- Waiting copy when no searching/assigned delivery status
- “Recherche de livreur” **only** if `delivery.status == SEARCHING_DRIVER`

### C. En cours / Historique + shell
| Segment | Chip | API query |
| --- | --- | --- |
| En cours | Nouvelles | `fulfillmentStatus=PENDING_ACCEPTANCE` |
| En cours | Acceptées | `fulfillmentStatus=ACCEPTED` |
| En cours | En préparation | `fulfillmentStatus=PREPARING` |
| En cours | Prêtes | `fulfillmentStatus=READY` |
| Historique | Annulées | `orderStatus=CANCELLED` |
| Historique | Terminées | `orderStatus=COMPLETED` |
| Historique | Échouées | `orderStatus=FAILED` |

Each chip is one supported filter (filter before pagination). Counts use `list.total` for the **active** chip only. Default: En cours → Nouvelles. List captures include five-tab shell.

---

## 2. Mocked captures (this pass)

| File | Notes |
| --- | --- |
| `mocked/se-list-shell.png` / `pro-list-shell.png` / `se-list-shell-text13.png` | List + En cours/Historique + Accueil…Profil |
| `mocked/se-incoming.png` / `se-incoming-scale13.png` | Compact ref + Accept/Reject |
| `mocked/pro-preparing.png` | Articles à préparer |
| `mocked/se-ready-waiting.png` / `pro-ready-waiting.png` / `se-ready-scale13.png` | Single ready status |
| `mocked/se-cancelled.png` / `pro-cancelled.png` | Cancellation first |

Side-by-sides: `structure/side-list-shell-se.png`, `side-incoming-se.png`, `side-preparing-pro.png`, `side-ready-se.png`, `side-cancelled-pro.png`.

---

## 3. Live evidence

| Evidence | Status |
| --- | --- |
| Historical live accept/reject shots in `live/` | **Retained** (labelled historical) |
| Updated live read-only SE smoke (list→detail→scroll→back→refresh) | **NOT RUN** — Finjan session active on iPhone 17 Pro (`Runner` PID preserved); avoided second Merchant boot on SE to prevent session interference. API health **200** (`GET /health`). |
| Mutations / new orders | **Not performed** |

---

## 4. Validation (this pass)

| Command | Exit | Result |
| --- | --- | --- |
| `dart analyze` (orders + strings + shell) | **0** | No issues |
| `flutter test test/features/order_list_visual_corrections_test.dart test/features/order_ops_test.dart` | **0** | **+15** |
| `flutter test test/audit/phase2_visual_review_capture_test.dart` | **0** | **+1** (visual_capture) |

Preserved: labelled Marchandises vs Net; Créée/Annulée timestamps; cancelled finance note; Refuser/Accepter layout; no prep-time disclaimer; DecoratedBox sticky; mutations.

---

## 5. Customer comparison (this pass only)

Baseline recorded at start of this pass → end report:

- `fixtures/customer_pass_baseline_hash.txt` / `customer_pass_baseline_manifest.json`
- `fixtures/customer_pass_end_report.json`

**MATCH** — sha256 `3cf5b81b1e7645edf57a0ec47fa8a8ff8320360f656aedf8e2703c08414708f1` (1398 files, 0 added, 0 removed).

Does **not** claim resolution of the earlier historical Customer hash mismatch from prior phases.

---

## 6. Remaining visual / contract gaps

- Stitch chrome (bell, countdown, loyalty, special-note) absent
- Prep-time picker / driver call / handoff / realtime unsupported
- Short `#SG-` display IDs not used (canonical `sgo_…` only)
