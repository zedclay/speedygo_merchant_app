# Merchant parity inventory — shared brief (read-only task)

Do NOT modify any code, tests or existing docs. The ONLY file you may create is your
batch inventory note in this directory. Do not run git commands that modify anything.

Workspace `/Users/mac/Downloads/speedygo_project` (multi-repo). Flutter app
`apps/merchant_app`; backend (NestJS) `apps/backend`.

References: `screens/MerchantScreens/<folder>/screen.png` (visual) and `code.html`
(layout / Tailwind styles). Tokens: `screens/MerchantScreens/speedygo_merchant_system/DESIGN.md`.
Binding guidance (read first): `apps/merchant_app/docs/MERCHANT_UI_SOURCE_OF_TRUTH.md`
(approved exceptions: splash, current three onboarding pages, phone/OTP aligned with Customer
auth, server-authoritative auth/access states). Audit folders under `apps/merchant_app/audit/`
are evidence, not design truth.

Routes: `apps/merchant_app/lib/core/navigation/app_routes.dart`,
`apps/merchant_app/lib/app/router/app_router.dart`. Shared UI:
`lib/core/widgets/merchant_ui.dart`, `lib/app/theme/app_theme.dart`. API client: search
`apps/merchant_app/lib` for `MerchantClient` / `MerchantApi`.

## For EACH reference folder

1. Open `screen.png` with the Read tool (it renders images) AND read `code.html`. Record the
   exact path of anything missing/unreadable.
2. Design: header/app bar (title, subtitle, icons), section order, cards (bg, border, radius,
   shadow), typography (Tailwind sizes/weights), colors (hex/token), chips/badges, icons
   (Material Symbols names), forms/selectors/menus/dialogs/sheets, charts/lists, sticky
   footer/CTA text + style, bottom nav presence, imagery. Concrete enough to build without
   reopening. French headings/CTAs verbatim.
3. Flutter mapping: route, screen/widget file, state (e.g. `OrderDetailScreen` with
   `fulfillmentStatus=PREPARING`). Read the code. You may view existing mocked/live captures
   under `apps/merchant_app/audit/**` to judge the current look.
4. Current differences (visual + structural). Screens with no Flutter implementation: say so
   and where they would live.
5. Contract: for each unimplemented reference feature, inspect backend controllers/DTOs/
   services (`apps/backend/src/modules/**`, `apps/backend/prisma/contract.prisma`) and the
   Flutter client. State SUPPORTED (endpoint), PARTIAL, or NOT SUPPORTED (contract needed).
   Cite files. Never assume.
6. Alternatives: other folders designing the same state; documented decisions; flag
   unresolved conflicts (do not decide product questions).
7. Required work (concrete; no fake data, fake success, dead actions, invented timers,
   invented driver phones or misleading metrics) and proposed status from:
   `needs_work`, `partial_contract_limited`, `blocked_contract`, `exception_approved`,
   `not_applicable_duplicate`, `matches` (only if truly matching).

Rules: reference names/amounts/timers are example data — never hardcoded. Server authorization
stays (STAFF cannot mutate orders or manage catalogue/store; STAFF sees no commission, merchant
net or merchant discount). Store profile edits are role-gated per
`apps/backend/src/modules/merchants/domain/merchant.policy.ts`.

## Output file format

Start with a summary table: `reference | route/state | proposed status | one-line required work`.
Then one `## <folder>` section per reference with subsections: Design, Flutter mapping,
Differences, Contract, Alternatives, Required work, Proposed status.

## Final response

The summary table (markdown), unreadable files, unresolved product decisions, and cross-cutting
findings (shared components/tokens to fix once: app bar, status chip, card shadow, bottom nav,
buttons, inputs).
