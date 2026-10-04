import 'package:speedygo_merchant_app/features/auth/data/models.dart';

enum SessionPhase {
  boot,
  restoring,
  restoreRetryable,
  signedOut,
  awaitingOtp,
  resolvingAccess,
  ready,
}

class SessionState {
  const SessionState({
    required this.phase,
    this.tokens,
    this.pendingPhone,
    this.errorMessage,
    this.busy = false,
    this.otpResendAvailableAt,
    this.locale = 'fr',
    this.languageSeen = false,
    this.onboardingSeen = false,
    this.generation = 0,
    this.accountId,
    this.verifiedPhone,
  });

  static const initial = SessionState(phase: SessionPhase.boot);

  final SessionPhase phase;
  final TokenPair? tokens;
  final String? pendingPhone;
  final String? errorMessage;
  final bool busy;
  final DateTime? otpResendAvailableAt;
  final String locale;
  final bool languageSeen;
  final bool onboardingSeen;
  final int generation;
  final String? accountId;

  /// Verified login phone from auth/me (read-only in registration).
  final String? verifiedPhone;

  bool get canRequestOtp {
    final at = otpResendAvailableAt;
    if (at == null) return true;
    return !DateTime.now().isBefore(at);
  }

  int get otpResendSecondsRemaining {
    final at = otpResendAvailableAt;
    if (at == null) return 0;
    final seconds = at.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  SessionState copyWith({
    SessionPhase? phase,
    TokenPair? tokens,
    String? pendingPhone,
    String? errorMessage,
    bool? busy,
    DateTime? otpResendAvailableAt,
    String? locale,
    bool? languageSeen,
    bool? onboardingSeen,
    int? generation,
    String? accountId,
    String? verifiedPhone,
    bool clearError = false,
    bool clearTokens = false,
    bool clearPendingPhone = false,
    bool clearVerifiedPhone = false,
  }) {
    return SessionState(
      phase: phase ?? this.phase,
      tokens: clearTokens ? null : (tokens ?? this.tokens),
      pendingPhone: clearPendingPhone
          ? null
          : (pendingPhone ?? this.pendingPhone),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
      otpResendAvailableAt: otpResendAvailableAt ?? this.otpResendAvailableAt,
      locale: locale ?? this.locale,
      languageSeen: languageSeen ?? this.languageSeen,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      generation: generation ?? this.generation,
      accountId: accountId ?? this.accountId,
      verifiedPhone: clearVerifiedPhone
          ? null
          : (verifiedPhone ?? this.verifiedPhone),
    );
  }
}
