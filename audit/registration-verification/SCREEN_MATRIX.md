# Screen implementation vs Stitch references

| # | Reference | Flutter status | Notes |
| --- | --- | --- | --- |
| 1 | merchant_registration_french | **Works (supported subset)** | Role + verified phone. Email/consent blocked honestly. |
| 2 | merchant_information_french | **Partial** | Merchant `name` only. NIF/manager/email **blocked**. |
| 3 | business_document_upload_french | **Works** | SpeedyGo evidence types + upload/bind. Not RC/NIF enum aliases. |
| 4 | store_information_french | **Partial** | Branch name/phone. No AR name, ratings, ETA, open state. Preview labeled non-published. |
| 5 | store_category_selection_french | **Blocked** | Admin-only vertical. Honest blocked card. |
| 6 | store_address_french | **Partial** | `addressText` + manual coords. No wilaya/commune taxonomy API. |
| 7 | store_map_location_french | **Blocked** | No map/geocoder config. Cropped PNG not reproduced. Manual coords. |
| 8 | merchant_verification_review_french | **Works (supported)** | Review of saved fields + submit when `verificationReady`. |
| 9 | merchant_verification_pending_french | **Works** | Status + checklist + refresh. No fake SLA/priority/SMS. |
| 10 | merchant_verification_approved_french | **Partial** | ACTIVE → existing home/branch flow (not Stitch congrats marketing). |
| 11 | merchant_verification_rejected_french | **Partial** | Status + checklist + open corrections. **No rejection reasons** from API. |
| 12 | merchant_verification_resubmission_french | **Partial** | Same registration wizard when REJECTED (editable evidence/name/branch) + resubmit. |

## Captures
`captures/` — mocked widget captures @ 375×667 / 402×874 / text 1.3 where noted.

## Live
Finjan read-only: no upload/submit against Finjan in automation. Synthetic merchant live writes: **blocked** this pass (no authorized synthetic fixture provisioned in session). Mocked tests cover create reconcile, upload bind, routing.

## Step 3–4 visual pass (implementer_reviewed)

See `STEP34_VISUAL_CORRECTION.md`. Documents/establishment presentation updated; category selection and interactive map remain **functional gaps** (read-only / manual coords). Evidence status no longer maps `complete` → Validé.

See also `MAP_LOCATION.md` (map picker replaces manual lat/lng).
