# Merchant Bottom Navigation Concept V1 — review index

**Status: `user_accepted`**

| Field | Value |
| --- | --- |
| Accepted date | 2026-10-03 (Africa/Algiers) |
| Accepted scope | Merchant root five-tab dock; active state; hide/reveal handle; horizontal root-tab navigation; safe-area and text-scale behaviour |
| Explicitly not accepted | Full Merchant app; tab body screens; top app bars; Catalogue empty/error/retry content; contract-completion / polish packages |

## Package contents

| Path | Role |
| --- | --- |
| [merchant_bottom_nav_v1_2026-10-03_review.zip](merchant_bottom_nav_v1_2026-10-03_review.zip) | Concept V1 mocked review package (report + mocked 1.0 / 1.35 captures + SHA256SUMS) |
| [../MERCHANT_BOTTOM_NAV_V1_REPORT.md](../MERCHANT_BOTTOM_NAV_V1_REPORT.md) | Authoritative Bottom Navigation Concept V1 report (status `user_accepted`) |
| [../mocked/](../mocked/) | Mocked dock / tab / hidden-handle captures |
| [../live_20261003T1517Z/](../live_20261003T1517Z/) | Live Finjan Concept V1 captures (tabs, swipe, labels, chip overscroll) |
| [../../isolated/evidence/fxenv_20261003T143647Z/gap_close/review_package_gap_close_v1.zip](../../isolated/evidence/fxenv_20261003T143647Z/gap_close/review_package_gap_close_v1.zip) | Isolated dock hide/reveal evidence @ 1.0 / 1.35 (Catalogue empty/error panels in that ZIP are outside this acceptance) |

## Matrix

Parity matrix row 1 (`*(shell)* canonical bottom nav + top app bar`) records Concept V1 **dock chrome** as `user_accepted` on 2026-10-03 (Africa/Algiers). The top app bar and all tab body screens remain not user-accepted.

See `apps/merchant_app/docs/MERCHANT_SCREEN_PARITY_MATRIX.md` and `apps/merchant_app/audit/parity/matrix/progress.json`.
