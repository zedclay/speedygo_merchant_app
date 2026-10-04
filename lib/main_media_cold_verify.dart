import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/app/router/app_router.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';

/// Debug-only entrypoint for cold-relaunch media screenshots.
///
/// `flutter run -d UDID -t lib/main_media_cold_verify.dart`
/// with `MEDIA_VERIFY_PRODUCT_ID` and optional `MEDIA_LIVE_PHONE`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: _MediaColdVerifyApp()));
}

class _MediaColdVerifyApp extends ConsumerStatefulWidget {
  const _MediaColdVerifyApp();

  @override
  ConsumerState<_MediaColdVerifyApp> createState() =>
      _MediaColdVerifyAppState();
}

class _MediaColdVerifyAppState extends ConsumerState<_MediaColdVerifyApp> {
  static const _productId = String.fromEnvironment('MEDIA_VERIFY_PRODUCT_ID');
  static const _phaseFile = String.fromEnvironment(
    'MEDIA_VERIFY_PHASE_FILE',
    defaultValue: '/tmp/media_cold_phase.txt',
  );
  static const _openCover = bool.fromEnvironment(
    'MEDIA_VERIFY_OPEN_COVER',
    defaultValue: true,
  );
  static const _phoneLocal = String.fromEnvironment(
    'MEDIA_LIVE_PHONE',
    defaultValue: '550000071',
  );
  static const _otpFile = String.fromEnvironment(
    'MEDIA_OTP_FILE',
    defaultValue: '/Users/mac/.speedygo/dev/otp-last',
  );

  var _started = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionControllerProvider, (prev, next) {
      if (_started) return;
      if (next.phase == SessionPhase.ready) {
        _started = true;
        unawaited(_runVerifyFlow());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_started) return;
      final phase = ref.read(sessionControllerProvider).phase;
      if (phase == SessionPhase.ready) {
        _started = true;
        unawaited(_runVerifyFlow());
      } else if (phase == SessionPhase.signedOut ||
          phase == SessionPhase.awaitingOtp) {
        _started = true;
        unawaited(_loginThenVerify());
      }
    });
    return const SpeedyGoApp();
  }

  Future<void> _loginThenVerify() async {
    _writePhase('login');
    await Future<void>.delayed(const Duration(seconds: 4));
    final session = ref.read(sessionControllerProvider.notifier);
    try {
      await session.setLocale('fr');
    } catch (_) {}
    try {
      await session.completeOnboarding();
    } catch (_) {}
    await Future<void>.delayed(const Duration(seconds: 2));
    final before = DateTime.now().subtract(const Duration(seconds: 1));
    try {
      await session.requestOtp(_phoneLocal);
    } catch (_) {
      _writePhase('login-otp-request-failed');
    }
    final otp = await _waitOtp(before);
    if (otp != null) {
      try {
        await session.verifyOtp(otp);
      } catch (_) {
        _writePhase('login-otp-verify-failed');
      }
    }
    for (var i = 0; i < 90; i++) {
      final phase = ref.read(sessionControllerProvider).phase;
      if (phase == SessionPhase.ready) {
        await _runVerifyFlow();
        return;
      }
      // Access may still be resolving after OTP.
      if (phase == SessionPhase.resolvingAccess) {
        try {
          await session.markAccessReady();
        } catch (_) {}
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    _writePhase('login-timeout');
  }

  Future<String?> _waitOtp(DateTime after) async {
    final file = File(_otpFile);
    for (var i = 0; i < 60; i++) {
      if (file.existsSync() && !file.lastModifiedSync().isBefore(after)) {
        final otp = file.readAsStringSync().trim();
        if (RegExp(r'^\d{4,8}$').hasMatch(otp)) return otp;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  Future<void> _runVerifyFlow() async {
    await Future<void>.delayed(const Duration(seconds: 5));
    final router = ref.read(appRouterProvider);

    if (_productId.isNotEmpty) {
      _writePhase('open-product');
      router.go(AppRoutes.catalogProductEdit(_productId));
      await Future<void>.delayed(const Duration(seconds: 10));
      _writePhase('product-ready');
      await Future<void>.delayed(const Duration(seconds: 5));
      router.go(AppRoutes.home);
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (_openCover) {
      _writePhase('open-cover');
      router.go(AppRoutes.storeCover);
      await Future<void>.delayed(const Duration(seconds: 10));
      _writePhase('cover-ready');
      await Future<void>.delayed(const Duration(seconds: 5));
      router.go(AppRoutes.home);
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    _writePhase('done');
  }

  void _writePhase(String phase) {
    try {
      File(_phaseFile).writeAsStringSync(
        '$phase\n${DateTime.now().toUtc().toIso8601String()}\n',
      );
    } catch (_) {}
  }
}
