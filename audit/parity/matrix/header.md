# Merchant screen parity matrix

This matrix maps every Stitch reference in `screens/MerchantScreens/` to its Flutter route or state. For each one it records the current differences, the required work and the status. It is the working tracker for the Merchant UI parity pass and is updated batch by batch.

- **Coverage:** 75 screen folders, the root pair (`screens/MerchantScreens/screen.png` + `code.html`, the Arabic add-product form) and `speedygo_merchant_system/` (only `DESIGN.md`, the token source). Each folder's detailed analysis (design, Flutter mapping, differences, contract, alternatives, required work) is linked in the last column and lives in `../audit/parity/inventory/`.
- **Comparisons:** see `../audit/parity/COMPARISON_INDEX.md`.
- **Sample data:** reference names, amounts, timers and statuses are example data. They are never hardcoded; fixture captures use equivalent representative data.
- **Visual acceptance:** "done (mocked compared)" means implemented and compared side by side by the implementer. It is **not** visual acceptance, which belongs to the product owner (`human_accepted`).

## Status vocabulary

| Status | Meaning |
| --- | --- |
| `needs_work` | Supported by existing contracts; visual or behaviour work required. |
| `partial_contract_limited` | Implementable except for elements with no backend contract, which are omitted (never faked). |
| `blocked_contract` | The screen's core purpose needs a contract that does not exist. Proposal in the gaps section. |
| `not_applicable_duplicate` | Same state as a canonical reference, or merged by a documented decision. |
| `exception_approved` | Covered by a previously agreed exception (`MERCHANT_UI_SOURCE_OF_TRUTH.md` §3/§7). |
| `exception_approved*` | Exception for server-authoritative *state* only; visuals follow the reference (D-G1 decided). |

The **Progress** column records the parity-pass result: `—` (not started), `done (mocked compared)`, `partial (see gaps)`, `no change (blocked)`, `no change (exception)`.

## Unreadable or incomplete reference files

| Path | Problem | Handling |
| --- | --- | --- |
| `screens/MerchantScreens/duplicate_product_french/screen.png` | Solid black image | `code.html` used as the reference |
| `screens/MerchantScreens/commande_en_pr_paration_tat_initial/screen.png` | Dark-mode render, low legibility | `code.html` used |
| `screens/MerchantScreens/store_map_location_french/screen.png` | Cropped to the header | `code.html` used |
| `screens/MerchantScreens/merchant_onboarding_manage_business_unified/screen.png` | Only the left ~40 % rendered | `code.html` used |
| `screens/MerchantScreens/{merchant_reports_overview,sales_summary,daily_summary}_french/screen.png` | Bottom nav cropped or broken | `code.html` used for the nav |
| `screens/MerchantScreens/speedygo_merchant_system/` | No `screen.png` / `code.html` | `DESIGN.md` is the token source |
| `screens/MerchantScreens/merchant_language_french/code.html` | Uses a foreign nav template (Messages tab, Phosphor icons) | Body used; nav ignored |

## Product decisions

Defaults marked **applied** are reversible and follow the references, `DESIGN.md` or the existing source-of-truth doc. Items marked **open** are not implemented until decided.

| ID | Question | Resolution |
| --- | --- | --- |
| D-A1 | Bottom-nav active pill colour (4–4 tie in the references) | **Applied:** pill style (8/11 refs), `primary-container #2F59AF` with `on-primary-container #C7D5FF`, because `DESIGN.md` ties active navigation to `#2F59AF`. One constant to swap. |
| D-A2 | Home header shows "Ouvert" and "Actif" | **Applied:** the availability pill (reference) always; the operational pill only when the status is not ACTIVE, so warnings are never hidden. |
| D-A3 | Home KPI "Commandes" semantics | **Applied:** `completedOrderCount` for TODAY with the unit "terminées", so it is not read as "received". "Temps moyen" is omitted (no contract). |
| D-A4 | Verification banner destination | **Applied:** non-interactive (the empty tap is removed); no chevron, because there is no destination. Open for a future route. |
| D-A5 | Reports "Temps prép. moy." card | Open. Kept as today ("Non suivi"). |
| D-A6 | Top-products rows open the product editor | Open. Not interactive. |
| D-B1 | Canonical duplicates in orders (`preparing_order_french_1/2`, `update_preparation_time_french`) | **Applied:** the standardised French folders are canonical; duplicates are `not_applicable_duplicate`. |
| D-B2 | Inline accept/reject on list cards | Open. Cards open the detail, where actions live. |
| D-B3 | Delay reasons | Open. No reason taxonomy contract; not shown. |
| D-B4 | Handoff model (secure code) | Open, `blocked_contract`. |
| D-C1 | "Archiver" wording | **Applied:** "Rendre indisponible" (the contract only has `available=false`). |
| D-C2 | Duplicate product | Open. The dead "Dupliquer" menu item is removed until decided. |
| D-C3 | Row tap destination | **Applied:** keep current (row opens the editor). |
| D-C4 | Unsupported fields (Arabic names, prep time, units) | **Applied:** omitted, per source-of-truth §4. |
| D-C5 | Money shows ",00" | Open (cross-app formatting). Current formatter kept. |
| D-C6 | Arabic root design | Open. Recorded as `not_applicable_duplicate` (pending). |
| D-D1 | "Informations générales" editor (branch vs merchant name) | **Implemented (2026-10-04):** Branch name + description + nameAr + publicEmail; verified Merchant name read-only; phone on address screen. |
| D-D2 | Store category self-selection | Open, `blocked_contract`. |
| D-D3 | Store logo | Open, `blocked_contract`. |
| D-D4 | Exceptional hours | **exception_approved (2026-10-04):** one civil date at a time is Merchant MVP; Stitch ranges/batch are non-goals. Customer UI unchanged. |
| D-D5 | "Demain à l'ouverture" closure mode | Open. Not shown. |
| D-D6 | Week start day | **Applied:** keep Monday (ISO, current). |
| D-D7 | Address search (geocoding) | Open; external service, deferred. |
| D-G1 | Do the §7 registration/verification exceptions cover visuals? | **Decided (user): no.** The exception covers server-authoritative state and flow only; registration, document upload and verification screens get visual parity with their references. |
| D-G2 | Should a merchant whose dossier has just been approved see a one-time "Félicitations" screen (`merchant_verification_approved_french`) before Accueil or need-branch? | **Decided (user): yes. Implemented** (`/verification/approved`, `VerificationApprovedScreen`). Shown only when this installation previously observed the same account + merchant as pending or rejected (from a successful server response) and the server now confirms approval (`approved`, status not PENDING_REVIEW/REJECTED/SUSPENDED). The observation and acknowledgement are stored per account + merchant in the Keychain (`speedygo.merchant.approval-notice.v1.<account>.<merchant>`). Rendering never acknowledges; only the CTA or a setup link does, and then the normal server routing runs again (Accueil, branch selection or need-branch). API errors, storage failures or a local flag alone never show it. Approval does not mean the store is open: the screen says so. Horaires / Catalogue / Alertes need the app shell; with no branch they are disabled with a hint and the CTA leads to the existing need-branch step. Mocked evidence only; live verification pending (see gaps). |
| D-G3 | Arabic option in the language screen before Arabic strings exist | Open. |
| D-G4 | Repeat alerts / volume | Open. Omitted. |
| D-G5 | Should registration and review show the consent and "Je déclare…" checkboxes that must be ticked before submitting, although the backend neither receives nor stores the acceptance? | **Decided (user, 2026-10-03): implement with server-recorded consent.** Contract Completion v1.1 (`MERCHANT_VERIFICATION_CONTRACT_COMPLETION_FOUNDATION.md`): versioned `MERCHANT_TERMS` + `DOSSIER_ACCURACY_DECLARATION`, append-only acceptances on submit, structured rejection issues, resubmission + approval stamps. Merchant review UI requires both checkboxes; submit sends exact active versions. Not visually accepted yet. |
| D-G6 | Support topic cards as body prefill | **Implemented (2026-10-04):** server topics + persisted topicCode/subject; FAQ articles from backend. |
| D-G7 | Settings shows the bottom tab bar | **Applied:** keep current (pushed screens have no bar; references are inconsistent). |

## Matrix

| # | Batch | Reference | Route / state | Current differences (baseline) | Required work | Baseline status | Progress | Inventory |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
