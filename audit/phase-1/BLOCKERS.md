# Merchant Phase 1 — Remaining blockers

1. **Verification document upload UI** — backend routes exist (`/merchant/:id/verification/documents/...`); Phase 1 shows checklist + honest gap, no multipart upload.
2. **Home aggregate metrics API** — absent; Home correctly refuses to invent KPIs.
3. **Live Flutter UI evidence** — mocked captures only; no Merchant integration_test / device pass this session.
4. **76-ecrans analyse report** — file not present in workspace.
5. **OTP verify `platform` enum** — must be lowercase `ios|android|web` (fixed in client after live probe).
6. **Android emulator** — prior Customer work left emulator/disk unreliable; not used for Merchant live UI.

## Next bounded Merchant phase (proposed)

**Phase 2 — Order operations:** accept/reject, preparation timing, handoff readiness against real order mutation contracts — still no catalogue CRUD, reports, or team management.
