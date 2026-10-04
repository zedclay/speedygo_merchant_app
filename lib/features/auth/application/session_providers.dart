import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SecureSessionStore();
});

final launchStoreProvider = Provider<LaunchStore>((ref) {
  return SecureLaunchStore();
});

final contextStoreProvider = Provider<ContextStore>((ref) {
  return SecureContextStore();
});

final approvalNoticeStoreProvider = Provider<ApprovalNoticeStore>((ref) {
  return SecureApprovalNoticeStore();
});

final splashMinDurationProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 1400);
});

final splashAnimateProvider = Provider<bool>((ref) => true);

final tokenCacheProvider = Provider<TokenCache>((ref) => TokenCache());

final sessionEpochProvider = Provider<SessionEpoch>((ref) => SessionEpoch());

class TokenCache {
  TokenPair? current;
  Future<void> Function()? onAuthFailure;
}

class SessionEpoch {
  int value = 0;
}
