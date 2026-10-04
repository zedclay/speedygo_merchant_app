# Merchant Bottom Navigation Concept V1 — user acceptance

Status: **`user_accepted`**

Accepted date: **2026-10-03** (Africa/Algiers)

Accepted scope (Concept V1 chrome only — **not** the full Merchant app):

- Merchant root five-tab dock
- Active tab state
- Hide / reveal handle
- Horizontal root-tab navigation
- Safe-area and text-scale behaviour

Out of scope for this acceptance: tab body screens (Accueil, Commandes, Catalogue content, Rapports, Profil), top app bars, Catalogue empty/error flows, contract-completion / polish packages, and every other Merchant surface.

---

## 1. Files changed (implementation history)

| Path | Change |
| --- | --- |
| `lib/app/theme/app_theme.dart` | `MerchantNavTokens` plus Concept V1 colours |
| `lib/core/constants/app_strings.dart` | `navReveal` |
| `lib/features/shell/merchant_nav_visibility.dart` | hide / reveal controller |
| `lib/features/shell/merchant_bottom_nav.dart` | floating dock, handle, slot |
| `lib/features/shell/merchant_shell.dart` | persistent pager + dock slot |
| `test/features/merchant_bottom_nav_test.dart` | focused unit / widget tests |
| `test/audit/parity/bottom_nav_v1_capture_test.dart` | mocked captures 1.0 / 1.35 |

Unchanged by Concept V1: `lib/app/router/app_router.dart` route table, tab paths and order,
nested `parentNavigatorKey` pushes, auth, APIs, permissions, Customer, Driver,
backend, previous audit ZIPs.

## 2. Navigation architecture

Root tabs stay **pages inside one persistent shell**, not pushed routes.

- `GoRouter` still uses `ShellRoute` + `context.go` on the five tab paths:
  Accueil, Commandes, Catalogue, Rapports, Profil.
- `MerchantShell` keeps a `PageView` of those five screens with
  `AutomaticKeepAliveClientMixin`. Returning to a tab does not remount it.
- Tab taps call `context.go`, then the shell animates the pager (220 ms,
  `easeOutCubic`, subtle fade).
- Intentional horizontal swipes change the pager, then `context.go` updates
  the URL.
- Nested detail / editor / workflow routes still use `parentNavigatorKey` on
  the root navigator. The dock is not forced onto those screens.
- Deep links to a tab path select that page. Android back from a pushed route
  pops to the shell and shows the dock.

## 3. Hide / reveal rules

Controller: `MerchantNavVisibilityController`.

Only the **selected** root page’s **primary vertical** scroll is used
(`ScrollNotification.depth == 0`, `axis == vertical`). Nested horizontal chips,
carousels and the pager itself are ignored.

| Event | Result |
| --- | --- |
| Finger-driven scroll down, accumulated ≥ 48 px | Hide (slide down + fade, 200 ms) |
| Finger-driven scroll up (any delta < 0) | Reveal immediately |
| `pixels <= minScrollExtent` (top) | Reveal |
| Handle tap | Reveal |
| Root tab change | Reveal |
| Return from a nested route to an exact tab path | Reveal |
| App resume | Reveal |
| Keyboard (`viewInsets.bottom > 0`) | Auto-hide off (stays revealed) |
| Focus inside a `TextField` / `EditableText` | Auto-hide off |
| `accessibleNavigation` | Auto-hide off |
| Shell route not current (dialog / pushed cover) | Auto-hide off |
| Ballistic settle / rebound (`dragDetails == null`) | Ignored (anti-jitter) |

Hidden chrome is a centered 32×4 muted handle above the safe area
(`Key('nav-handle')`).

## 4. Root transition and state preservation

- Duration 220 ms; direction follows tab order.
- Reduced motion (`disableAnimations`) jumps without the fade.
- Scroll offset and in-page widgets survive tab changes because the page stays
  in the `PageView`.
- Riverpod controllers on those pages are not recreated on return.
- Pages are created lazily on first visit (builder), then kept.

## 5. Test / evidence matrix

| Case | Result |
| --- | --- |
| Each active tab state | **PASS** |
| Selected accessibility semantics | **PASS** |
| Scroll-down hide threshold | **PASS** |
| Scroll-up immediate reveal | **PASS** |
| Handle-tap reveal | **PASS** |
| No jitter around the threshold | **PASS** |
| Tab-tap horizontal transition | **PASS** |
| Intentional swipe transition | **PASS** |
| Preserved scroll position | **PASS** |
| Preserved page state | **PASS** |
| Nested horizontal scroll does not change tabs | **PASS** |
| Keyboard / form does not auto-hide | **PASS** |
| Small-screen safe area | **PASS** |
| Text scale 1.35 | **PASS** |
| App background / resume | **PASS** |
| Deep link to a root tab | **PASS** |
| Android back from nested route | **PASS** |
| Last row does not overlap the dock | **PASS** |
| Tab change reveals a hidden dock | **PASS** |
| Mocked captures 1.0 and 1.35 | **PASS** |
| Live Finjan tabs / swipe / labels / chip overscroll | **PASS** |
| Live dock hide/reveal (Finjan Catalogue) | **NOT RUN — insufficient live scroll extent** |
| Live dock hide/reveal (isolated scrollable Catalogue) | **PASS** @ 1.0 / 1.35 |

## 6. Evidence paths

Mocked: `apps/merchant_app/audit/parity/bottom_nav/mocked/` (+ `SHA256SUMS`)

Live Finjan Concept V1:  
`apps/merchant_app/audit/parity/bottom_nav/live_20261003T1517Z/`

Isolated dock hide/reveal evidence:  
`apps/merchant_app/audit/parity/isolated/evidence/fxenv_20261003T143647Z/gap_close/`  
(Review ZIP there also includes Catalogue empty/error captures; those Catalogue
states are **not** part of this Bottom Navigation acceptance.)

Review package (Concept V1 mocked):  
`apps/merchant_app/audit/parity/bottom_nav/review/merchant_bottom_nav_v1_2026-10-03_review.zip`

Review index:  
`apps/merchant_app/audit/parity/bottom_nav/review/INDEX.md`

## 7. Notes retained from implementer review

- `nav_dock_only_*.png` can show a faint extra icon row in an empty-body
  harness; shell captures are the ones that were accepted.
- Tab body content and top app bars were not accepted by this decision.

## 8. Final status

**`user_accepted`** — 2026-10-03 (Africa/Algiers), Concept V1 root dock scope only.
