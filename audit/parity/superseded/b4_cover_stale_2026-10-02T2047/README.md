# SUPERSEDED — not review evidence

`b4_cover` mocked captures from 2026-10-02 20:47:59 CET and the panel composed
from them at 20:55. They predate the final logo-button change (20:50:36) that
stacks "Ajouter/Modifier" and "Supprimer" at text scale ≥ 1.25, so the 1.35
panel shows "Supprim/er" broken.

Replaced on 2026-10-03 by a recapture with the final layout:
`audit/parity/mocked/b4_cover_w390.png`, `audit/parity/mocked/b4_cover_w375_t135.png`
and `audit/parity/comparisons/b4_cover.png`
(`flutter test test/audit/parity/batch4_store_capture_test.dart --plain-name 'cover w'`,
then `python3 audit/parity/compose_batch.py b4_cover`).

Kept only as history; excluded from the main review evidence.
