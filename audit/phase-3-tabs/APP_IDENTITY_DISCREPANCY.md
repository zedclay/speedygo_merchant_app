# Phase 3 — app identity discrepancy (14:18 Customer vs Merchant report)

**Status:** resolved (identity). Visual acceptance still pending.

## Verified launch targets (read-only)

| App | Working directory | Entrypoint | Bundle ID | Display name | Scheme |
| --- | --- | --- | --- | --- | --- |
| Merchant | `apps/merchant_app` | `lib/main.dart` | `com.speedygo.speedygoMerchantApp` | Speedygo Merchant App | `Runner.xcscheme` |
| Customer | `apps/customer_app` | `lib/main.dart` | `com.speedygo.speedygoCustomerApp` | Speedygo Customer App | `Runner.xcscheme` |

Bundle IDs are **distinct**. No collision. Do not infer identity from Xcode product name `Runner`.

Simulator used: **iPhone 17 Pro** `4A1C3481-8B8E-48BD-983D-03896884EF09` (iOS 26.0).

## What produced the 14:18 Desktop screenshots

Files on Desktop (`Simulator Screenshot - iPhone 17 Pro - 2026-09-19 at 14.18.*.png`):

- Tabs: Accueil / **Recherche** / Commandes / **Alertes** / Profil  
- Home: **Livrer à**, commerce search, store browsing  
- Alertes / Profil customer surfaces  

→ **Customer** (`com.speedygo.speedygoCustomerApp`).  
Copied for separation to: `audit/phase-3-tabs/customer-desktop-14.18/`.

Finjan naming on Customer (“Bonjour, Finjan”, store card “Finjan Coffer”) is **not** Merchant identity.

## Root cause

1. **Foreground / active Flutter session was Customer.**  
   At ~14:04+, `flutter run` for `speedygo_customer_app` held iPhone 17 Pro (VM service package name confirmed). Merchant `flutter run` attempts hung/failed while that session owned the device.

2. **No bundle-ID collision.** Wrong **which app was open**, not shared identifiers.

3. **`flutter test` integration uninstalls Merchant on exit.**  
   After the earlier phase-3 live capture test finished, `com.speedygo.speedygoMerchantApp` was no longer installed; only Customer remained. Opening the simulator at 14:18 therefore showed Customer.

## Prior `audit/phase-3-tabs/live/` evidence

Those PNGs **are genuine Merchant** (tabs Catalogue / Rapports; Paramètres + Propriétaire; empty “Aucune nouvelle commande”).  
They were taken during `integration_test/phase3_tabs_live_capture_test.dart` while Merchant briefly ran.  
Status-bar “Speedygo Custo…” was app-switcher back-link to Customer still installed behind Merchant — **not** proof the capture was Customer.

Kept as historical Merchant evidence. Prefer **`live-verified/`** going forward (with `PROVENANCE.json`).

## Verified Merchant re-launch (this pass)

- Built from `apps/merchant_app` (`flutter build ios --simulator`).  
- Installed via `xcrun simctl install` (Customer not uninstalled).  
- Launched `com.speedygo.speedygoMerchantApp`.  
- Captured five tabs → `audit/phase-3-tabs/live-verified/live-*-pro.png`.  
- Identity assertions in test: Catalogue + Rapports present; Recherche/Alertes absent.  
- Customer container preserved throughout.

## Five Merchant captures (verified)

| Tab | File |
| --- | --- |
| Accueil | `live-verified/live-home-pro.png` |
| Commandes | `live-verified/live-orders-pro.png` |
| Catalogue | `live-verified/live-catalog-pro.png` |
| Rapports | `live-verified/live-reports-pro.png` |
| Profil | `live-verified/live-profile-pro.png` |

Provenance: `live-verified/PROVENANCE.json`.

## Note for operators

After `flutter test` / integration_test, **reinstall Merchant** from `build/ios/iphonesimulator/Runner.app` if you need both apps side by side; the test harness removes the tested app when done.
