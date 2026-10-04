import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/core/utils/phone_input.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/auth/data/auth_api.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/notifications/application/merchant_push_controller.dart';

class SessionController extends Notifier<SessionState> {
  late SessionStore _store;
  late LaunchStore _launch;
  late ContextStore _context;
  late AuthClient _authApi;
  var _restoreInFlight = false;

  @override
  SessionState build() {
    _store = ref.read(sessionStoreProvider);
    _launch = ref.read(launchStoreProvider);
    _context = ref.read(contextStoreProvider);
    _authApi = ref.read(authApiProvider);
    ref.read(tokenCacheProvider).onAuthFailure = () async {
      if (!ref.mounted) return;
      await invalidateLocalSession();
    };
    return SessionState.initial;
  }

  Future<void> restore() async {
    if (_restoreInFlight) return;
    if (state.phase == SessionPhase.restoring ||
        state.phase == SessionPhase.resolvingAccess ||
        state.phase == SessionPhase.ready ||
        state.phase == SessionPhase.awaitingOtp) {
      return;
    }
    _restoreInFlight = true;
    final generation = state.generation;
    try {
      final languageSeen = await _launch.readLanguageSeen();
      final locale = await _launch.readLocale();
      final onboardingSeen = await _launch.readOnboardingSeen();
      final stored = await _store.read();
      if (!_isCurrent(generation)) return;
      if (stored == null) {
        state = SessionState(
          phase: SessionPhase.signedOut,
          generation: generation,
          languageSeen: languageSeen,
          onboardingSeen: onboardingSeen,
          locale: locale,
        );
        return;
      }
      ref.read(tokenCacheProvider).current = stored;
      state = state.copyWith(
        phase: SessionPhase.restoring,
        tokens: stored,
        languageSeen: true,
        onboardingSeen: onboardingSeen,
        locale: locale,
        busy: true,
        clearError: true,
      );
      try {
        final me = await _authApi.me();
        if (!_isCurrent(generation)) return;
        state = state.copyWith(
          phase: SessionPhase.resolvingAccess,
          accountId: me.accountId,
          verifiedPhone: me.phone,
          busy: false,
          clearError: true,
        );
      } on NetworkException catch (e) {
        if (!_isCurrent(generation)) return;
        state = state.copyWith(
          phase: SessionPhase.restoreRetryable,
          busy: false,
          errorMessage: e.message,
        );
      } on ApiException catch (e) {
        if (!_isCurrent(generation)) return;
        if (e.isAuthFailure || e.isAccountBlocked) {
          await invalidateLocalSession();
          return;
        }
        state = state.copyWith(
          phase: SessionPhase.restoreRetryable,
          busy: false,
          errorMessage: AppStrings.errorForCode(e.code),
        );
      } catch (_) {
        if (!_isCurrent(generation)) return;
        state = state.copyWith(
          phase: SessionPhase.restoreRetryable,
          busy: false,
          errorMessage: AppStrings.networkError,
        );
      }
    } catch (_) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        phase: SessionPhase.restoreRetryable,
        busy: false,
        errorMessage: AppStrings.networkError,
      );
    } finally {
      _restoreInFlight = false;
    }
  }

  Future<void> retryRestore() => restore();

  Future<void> requestOtp(String rawPhone) async {
    if (state.busy) return;
    if (!PhoneInput.isValid(rawPhone)) {
      state = state.copyWith(errorMessage: AppStrings.phoneInvalid);
      return;
    }
    if (!state.canRequestOtp) {
      state = state.copyWith(
        errorMessage: AppStrings.errorForCode('AUTH_RATE_LIMITED'),
      );
      return;
    }
    final identifier = PhoneInput.toIdentifier(rawPhone);
    final generation = state.generation;
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _authApi.requestOtp(identifier);
      if (!_isCurrent(generation)) return;
      final cooldown = AppConstants.otpResendCooldownSeconds;
      state = state.copyWith(
        phase: SessionPhase.awaitingOtp,
        pendingPhone: identifier,
        busy: false,
        clearError: true,
        otpResendAvailableAt: DateTime.now().add(Duration(seconds: cooldown)),
      );
    } on ApiException catch (e) {
      if (!_isCurrent(generation)) return;
      final retry =
          e.retryAfterSeconds ?? AppConstants.otpResendCooldownSeconds;
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.errorForCode(e.code),
        otpResendAvailableAt: e.code == 'AUTH_RATE_LIMITED'
            ? DateTime.now().add(Duration(seconds: retry))
            : state.otpResendAvailableAt,
      );
    } catch (_) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.networkError,
      );
    }
  }

  Future<void> verifyOtp(String code) async {
    if (state.busy) return;
    final phone = state.pendingPhone;
    if (phone == null || phone.isEmpty) return;
    if (code.trim().length != 6) {
      state = state.copyWith(
        errorMessage: AppStrings.errorForCode('AUTH_INVALID_OTP'),
      );
      return;
    }
    final generation = state.generation;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final pair = await _authApi.verifyOtp(
        OtpVerifyBody(identifier: phone, code: code.trim()),
      );
      if (!_isCurrent(generation)) return;
      await _store.write(pair);
      ref.read(tokenCacheProvider).current = pair;
      final me = await _authApi.me();
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        phase: SessionPhase.resolvingAccess,
        tokens: pair,
        accountId: me.accountId,
        verifiedPhone: me.phone ?? phone,
        busy: false,
        clearPendingPhone: true,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.errorForCode(e.code),
      );
    } catch (_) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.networkError,
      );
    }
  }

  Future<void> markAccessReady() async {
    if (state.phase != SessionPhase.resolvingAccess &&
        state.phase != SessionPhase.ready) {
      return;
    }
    state = state.copyWith(phase: SessionPhase.ready, clearError: true);
  }

  Future<void> completeOnboarding() async {
    if (state.busy) return;
    if (state.onboardingSeen) return;
    final generation = state.generation;
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _launch.markOnboardingSeen();
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        onboardingSeen: true,
        busy: false,
        clearError: true,
      );
    } catch (_) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.onboardingSaveFailed,
      );
    }
  }

  Future<void> setLocale(String locale) async {
    final sanitized = locale == 'ar' ? 'ar' : 'fr';
    if (state.busy) return;
    final generation = state.generation;
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _launch.writeLocale(sanitized);
      await _launch.markLanguageSeen();
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        locale: sanitized,
        languageSeen: true,
        busy: false,
        clearError: true,
      );
    } catch (_) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.languageSaveFailed,
      );
    }
  }

  Future<void> logout() async {
    final generation = state.generation;
    try {
      // Must run while the session is still authenticated so the DELETE is
      // scoped to this Account + this install's token.
      await ref
          .read(merchantPushControllerProvider.notifier)
          .deactivateForSignOut(callServer: true);
      await _authApi.logout();
    } catch (_) {
      // Local sign-out is authoritative for UX consistency.
    }
    if (!_isCurrent(generation)) return;
    await invalidateLocalSession();
  }

  Future<void> invalidateLocalSession() async {
    final generation = state.generation + 1;
    ref.read(tokenCacheProvider).current = null;
    ref.read(sessionEpochProvider).value = generation;
    await _store.clear();
    await _context.clear();
    // Session is gone (expired/revoked): the server token cannot be deleted
    // with this Account's auth, so invalidate it at the provider instead.
    unawaited(
      ref
          .read(merchantPushControllerProvider.notifier)
          .deactivateForSignOut(callServer: false),
    );
    state = SessionState(
      phase: SessionPhase.signedOut,
      generation: generation,
      languageSeen: state.languageSeen,
      onboardingSeen: state.onboardingSeen,
      locale: state.locale,
    );
  }

  void dismissError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(clearError: true);
  }

  bool _isCurrent(int generation) => state.generation == generation;
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
