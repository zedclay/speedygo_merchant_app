import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What this installation has seen of one merchant's verification, per
/// signed-in account. Only ever written from confirmed server responses.
enum ApprovalNoticeState { none, observedUnapproved, acknowledged }

abstract class ApprovalNoticeStore {
  Future<ApprovalNoticeState> read(String accountId, String merchantId);
  Future<void> markObservedUnapproved(String accountId, String merchantId);
  Future<void> markAcknowledged(String accountId, String merchantId);
}

class SecureApprovalNoticeStore implements ApprovalNoticeStore {
  SecureApprovalNoticeStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'speedygo.merchant.approval-notice.v1';
  static const _observed = 'observed';
  static const _acknowledged = 'acknowledged';

  final FlutterSecureStorage _storage;

  String _key(String accountId, String merchantId) =>
      '$_prefix.$accountId.$merchantId';

  @override
  Future<ApprovalNoticeState> read(String accountId, String merchantId) async {
    final raw = await _storage.read(key: _key(accountId, merchantId));
    return switch (raw) {
      _observed => ApprovalNoticeState.observedUnapproved,
      _acknowledged => ApprovalNoticeState.acknowledged,
      _ => ApprovalNoticeState.none,
    };
  }

  @override
  Future<void> markObservedUnapproved(String accountId, String merchantId) =>
      _storage.write(key: _key(accountId, merchantId), value: _observed);

  @override
  Future<void> markAcknowledged(String accountId, String merchantId) =>
      _storage.write(key: _key(accountId, merchantId), value: _acknowledged);
}

class MemoryApprovalNoticeStore implements ApprovalNoticeStore {
  final Map<String, ApprovalNoticeState> values = {};

  String _key(String accountId, String merchantId) => '$accountId|$merchantId';

  @override
  Future<ApprovalNoticeState> read(String accountId, String merchantId) async =>
      values[_key(accountId, merchantId)] ?? ApprovalNoticeState.none;

  @override
  Future<void> markObservedUnapproved(
    String accountId,
    String merchantId,
  ) async => values[_key(accountId, merchantId)] =
      ApprovalNoticeState.observedUnapproved;

  @override
  Future<void> markAcknowledged(String accountId, String merchantId) async =>
      values[_key(accountId, merchantId)] = ApprovalNoticeState.acknowledged;
}
