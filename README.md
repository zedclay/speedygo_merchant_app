# SpeedyGo Merchant App

Flutter application for SpeedyGo merchants.

GitHub: https://github.com/zedclay/speedygo_merchant_app.git

This app consumes backend APIs. It must never independently calculate authoritative financial values.

## Stack

- Flutter / Dart
- Riverpod 3
- go_router
- Dio
- Freezed + json_serializable (code generation ready, unused until models exist)

## Architecture

```
lib/
  app/        # router, theme, providers, shell
  core/       # constants, errors, network, storage, utils, widgets
  features/   # product features (empty during foundation)
```

Do not implement catalog, order management, reports, or commission screens yet.

## Local setup

```bash
flutter pub get
flutter run
```

Firebase, Maps, payments, and production signing are not configured yet.

## Scripts

| Command | Purpose |
| --- | --- |
| `flutter pub get` | Install packages |
| `flutter analyze` | Static analysis |
| `flutter test` | Tests |
| `dart run build_runner build --delete-conflicting-outputs` | Codegen when models exist |
