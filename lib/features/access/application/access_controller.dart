import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';

enum AccessDestination {
  loading,
  error,
  noMembership,
  registration,
  verificationPending,
  verificationRejected,
  verificationSuspended,
  verificationApproved,
  needBranch,
  selectBranch,
  home,
  permissionDenied,
}

/// Same branch rule `AccessController.resolve` applies before entering the app.
bool membershipNeedsBranch(MerchantMembership membership) =>
    membership.activeBranches.isEmpty && membership.branches.isEmpty;

class AccessState {
  const AccessState({
    required this.destination,
    this.me,
    this.membership,
    this.selectedBranch,
    this.errorMessage,
    this.busy = false,
    this.requestGeneration = 0,
  });

  static const initial = AccessState(destination: AccessDestination.loading);

  final AccessDestination destination;
  final MerchantMe? me;
  final MerchantMembership? membership;
  final MerchantBranch? selectedBranch;
  final String? errorMessage;
  final bool busy;
  final int requestGeneration;
}

class AccessController extends Notifier<AccessState> {
  late MerchantClient _api;
  late ContextStore _context;
  late ApprovalNoticeStore _approvals;

  @override
  AccessState build() {
    _api = ref.read(merchantApiProvider);
    _context = ref.read(contextStoreProvider);
    _approvals = ref.read(approvalNoticeStoreProvider);
    ref.listen(sessionControllerProvider, (prev, next) {
      if (next.phase == SessionPhase.resolvingAccess) {
        resolve();
      }
      if (next.phase == SessionPhase.signedOut) {
        state = AccessState.initial;
      }
    });
    return AccessState.initial;
  }

  Future<void> resolve({bool inPlace = false}) async {
    final session = ref.read(sessionControllerProvider);
    if (session.phase != SessionPhase.resolvingAccess &&
        session.phase != SessionPhase.ready) {
      return;
    }
    final gen = state.requestGeneration + 1;
    final accountId = session.accountId;
    final previous = state;
    final stayOnScreen =
        inPlace &&
        previous.destination != AccessDestination.loading &&
        previous.destination != AccessDestination.error;
    state = AccessState(
      destination: stayOnScreen
          ? previous.destination
          : AccessDestination.loading,
      me: stayOnScreen ? previous.me : null,
      membership: stayOnScreen ? previous.membership : null,
      selectedBranch: stayOnScreen ? previous.selectedBranch : null,
      requestGeneration: gen,
      busy: true,
    );
    try {
      final me = await _api.me();
      if (!_stillCurrent(gen, accountId)) return;
      if (!me.merchantMembershipExists || me.memberships.isEmpty) {
        state = AccessState(
          destination: AccessDestination.noMembership,
          me: me,
          requestGeneration: gen,
        );
        return;
      }

      final storedMerchantId = await _context.readMerchantId();
      MerchantMembership membership = me.memberships.first;
      if (storedMerchantId != null) {
        membership = me.memberships.firstWhere(
          (m) => m.merchantId == storedMerchantId,
          orElse: () => me.memberships.first,
        );
      }

      final status = membership.merchantStatus.toUpperCase();
      if (status == 'SUSPENDED') {
        state = AccessState(
          destination: AccessDestination.verificationSuspended,
          me: me,
          membership: membership,
          requestGeneration: gen,
        );
        return;
      }
      if (status == 'REJECTED') {
        await _observeUnapproved(accountId, membership.merchantId);
        if (!_stillCurrent(gen, accountId)) return;
        state = AccessState(
          destination: AccessDestination.verificationRejected,
          me: me,
          membership: membership,
          requestGeneration: gen,
        );
        return;
      }
      // Incomplete dossier (not formally submitted) → resume registration.
      if ((status == 'PENDING_REVIEW' || !membership.approved) &&
          !membership.verificationSubmitted) {
        state = AccessState(
          destination: AccessDestination.registration,
          me: me,
          membership: membership,
          requestGeneration: gen,
        );
        return;
      }
      if (status == 'PENDING_REVIEW' || !membership.approved) {
        await _observeUnapproved(accountId, membership.merchantId);
        if (!_stillCurrent(gen, accountId)) return;
        state = AccessState(
          destination: AccessDestination.verificationPending,
          me: me,
          membership: membership,
          requestGeneration: gen,
        );
        return;
      }

      if (await _approvalNoticeDue(accountId, membership)) {
        if (!_stillCurrent(gen, accountId)) return;
        state = AccessState(
          destination: AccessDestination.verificationApproved,
          me: me,
          membership: membership,
          requestGeneration: gen,
        );
        return;
      }
      if (!_stillCurrent(gen, accountId)) return;

      final branches = membership.activeBranches.isNotEmpty
          ? membership.activeBranches
          : membership.branches;
      if (branches.isEmpty) {
        state = AccessState(
          destination: AccessDestination.needBranch,
          me: me,
          membership: membership,
          requestGeneration: gen,
        );
        return;
      }

      await _context.writeMerchantId(membership.merchantId);

      if (branches.length == 1) {
        final branch = branches.first;
        await _context.writeBranchId(branch.id);
        state = AccessState(
          destination: AccessDestination.home,
          me: me,
          membership: membership,
          selectedBranch: branch,
          requestGeneration: gen,
        );
        await ref.read(sessionControllerProvider.notifier).markAccessReady();
        return;
      }

      final storedBranchId = await _context.readBranchId();
      final match = branches.where((b) => b.id == storedBranchId).toList();
      if (match.length == 1) {
        state = AccessState(
          destination: AccessDestination.home,
          me: me,
          membership: membership,
          selectedBranch: match.first,
          requestGeneration: gen,
        );
        await ref.read(sessionControllerProvider.notifier).markAccessReady();
        return;
      }

      state = AccessState(
        destination: AccessDestination.selectBranch,
        me: me,
        membership: membership,
        requestGeneration: gen,
      );
    } on ApiException catch (e) {
      if (!_stillCurrent(gen, accountId)) return;
      if (e.code == 'MERCHANT_ROLE_FORBIDDEN') {
        state = AccessState(
          destination: AccessDestination.permissionDenied,
          errorMessage: AppStrings.permissionDenied,
          requestGeneration: gen,
        );
        return;
      }
      if (e.isAuthFailure) {
        await ref
            .read(sessionControllerProvider.notifier)
            .invalidateLocalSession();
        return;
      }
      if (stayOnScreen) {
        state = AccessState(
          destination: previous.destination,
          me: previous.me,
          membership: previous.membership,
          selectedBranch: previous.selectedBranch,
          errorMessage: AppStrings.errorForCode(e.code),
          requestGeneration: gen,
        );
        return;
      }
      state = AccessState(
        destination: AccessDestination.error,
        errorMessage: AppStrings.errorForCode(e.code),
        requestGeneration: gen,
      );
    } catch (_) {
      if (!_stillCurrent(gen, accountId)) return;
      if (stayOnScreen) {
        state = AccessState(
          destination: previous.destination,
          me: previous.me,
          membership: previous.membership,
          selectedBranch: previous.selectedBranch,
          errorMessage: AppStrings.networkError,
          requestGeneration: gen,
        );
        return;
      }
      state = AccessState(
        destination: AccessDestination.error,
        errorMessage: AppStrings.networkError,
        requestGeneration: gen,
      );
    }
  }

  /// Reloads merchant access without navigating through `/access/loading`.
  Future<void> refreshInPlace() => resolve(inPlace: true);

  /// Records the user's explicit acknowledgement of the approval notice, then
  /// re-runs server-authoritative routing. Returns true when access reached
  /// the app shell (so a follow-up in-app navigation is valid).
  Future<bool> acknowledgeApproval() async {
    final membership = state.membership;
    final accountId = ref.read(sessionControllerProvider).accountId;
    if (state.destination != AccessDestination.verificationApproved ||
        membership == null ||
        accountId == null ||
        state.busy) {
      return false;
    }
    state = AccessState(
      destination: state.destination,
      me: state.me,
      membership: membership,
      requestGeneration: state.requestGeneration,
      busy: true,
    );
    try {
      await _approvals.markAcknowledged(accountId, membership.merchantId);
    } catch (_) {
      // Keychain failure must not trap the user on the notice; it may
      // reappear on a later launch, which is the safe direction.
    }
    await resolve();
    return ref.read(sessionControllerProvider).phase == SessionPhase.ready;
  }

  Future<void> _observeUnapproved(String? accountId, String merchantId) async {
    if (accountId == null || merchantId.isEmpty) return;
    try {
      await _approvals.markObservedUnapproved(accountId, merchantId);
    } catch (_) {
      // Without a persisted observation the notice is simply not shown.
    }
  }

  /// True only for a server-confirmed approval of a merchant this
  /// installation previously saw pending/rejected for the same account.
  Future<bool> _approvalNoticeDue(
    String? accountId,
    MerchantMembership membership,
  ) async {
    final status = membership.merchantStatus.toUpperCase();
    if (accountId == null ||
        membership.merchantId.isEmpty ||
        !membership.approved ||
        status == 'PENDING_REVIEW' ||
        status == 'REJECTED' ||
        status == 'SUSPENDED') {
      return false;
    }
    try {
      final seen = await _approvals.read(accountId, membership.merchantId);
      return seen == ApprovalNoticeState.observedUnapproved;
    } catch (_) {
      return false;
    }
  }

  Future<void> openRegistrationCorrections() async {
    final membership = state.membership;
    if (membership == null) return;
    state = AccessState(
      destination: AccessDestination.registration,
      me: state.me,
      membership: membership,
      requestGeneration: state.requestGeneration + 1,
    );
  }

  Future<void> selectBranch(MerchantBranch branch) async {
    final membership = state.membership;
    if (membership == null) return;
    await _context.writeMerchantId(membership.merchantId);
    await _context.writeBranchId(branch.id);
    state = AccessState(
      destination: AccessDestination.home,
      me: state.me,
      membership: membership,
      selectedBranch: branch,
      requestGeneration: state.requestGeneration + 1,
    );
    await ref.read(sessionControllerProvider.notifier).markAccessReady();
  }

  Future<void> createMerchantProfile(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWithError(AppStrings.merchantNameHint);
      return;
    }
    final gen = state.requestGeneration + 1;
    final accountId = ref.read(sessionControllerProvider).accountId;
    state = AccessState(
      destination: AccessDestination.loading,
      requestGeneration: gen,
      busy: true,
    );
    try {
      await _api.createProfile(name: trimmed);
      if (!_stillCurrent(gen, accountId)) return;
      await resolve();
    } on ApiException catch (e) {
      if (!_stillCurrent(gen, accountId)) return;
      state = AccessState(
        destination: AccessDestination.noMembership,
        errorMessage: AppStrings.errorForCode(e.code),
        requestGeneration: gen,
      );
    } catch (_) {
      if (!_stillCurrent(gen, accountId)) return;
      state = AccessState(
        destination: AccessDestination.noMembership,
        errorMessage: AppStrings.networkError,
        requestGeneration: gen,
      );
    }
  }

  Future<void> createBranch({
    required String name,
    required String phone,
    required String addressText,
    required double latitude,
    required double longitude,
    required String wilayaCode,
    required int communeId,
  }) async {
    final membership = state.membership;
    if (membership == null) return;
    final gen = state.requestGeneration + 1;
    final accountId = ref.read(sessionControllerProvider).accountId;
    state = AccessState(
      destination: AccessDestination.loading,
      me: state.me,
      membership: membership,
      requestGeneration: gen,
      busy: true,
    );
    try {
      await _api.createBranch(
        merchantId: membership.merchantId,
        name: name.trim(),
        phone: phone.trim(),
        addressText: addressText.trim(),
        latitude: latitude,
        longitude: longitude,
        wilayaCode: wilayaCode,
        communeId: communeId,
      );
      if (!_stillCurrent(gen, accountId)) return;
      await resolve();
    } on ApiException catch (e) {
      if (!_stillCurrent(gen, accountId)) return;
      state = AccessState(
        destination: AccessDestination.needBranch,
        me: state.me,
        membership: membership,
        errorMessage: AppStrings.errorForCode(e.code),
        requestGeneration: gen,
      );
    } catch (_) {
      if (!_stillCurrent(gen, accountId)) return;
      state = AccessState(
        destination: AccessDestination.needBranch,
        me: state.me,
        membership: membership,
        errorMessage: AppStrings.networkError,
        requestGeneration: gen,
      );
    }
  }

  bool _stillCurrent(int gen, String? accountId) {
    if (state.requestGeneration != gen) return false;
    final session = ref.read(sessionControllerProvider);
    if (session.phase == SessionPhase.signedOut) return false;
    if (accountId != null &&
        session.accountId != null &&
        session.accountId != accountId) {
      return false;
    }
    return true;
  }
}

extension on AccessState {
  AccessState copyWithError(String message) {
    return AccessState(
      destination: destination,
      me: me,
      membership: membership,
      selectedBranch: selectedBranch,
      errorMessage: message,
      busy: busy,
      requestGeneration: requestGeneration,
    );
  }
}

final accessControllerProvider =
    NotifierProvider<AccessController, AccessState>(AccessController.new);

/// Identity that protected Merchant data (orders, reports) belongs to.
///
/// Protected controllers watch this so an account, merchant or role change
/// rebuilds them; the rebuild surfaces as a reload (loading UI), never the
/// previous identity's values.
class MerchantDataScope {
  const MerchantDataScope({
    required this.accountId,
    required this.merchantId,
    required this.role,
  });

  final String? accountId;
  final String merchantId;
  final String role;

  @override
  bool operator ==(Object other) =>
      other is MerchantDataScope &&
      other.accountId == accountId &&
      other.merchantId == merchantId &&
      other.role == role;

  @override
  int get hashCode => Object.hash(accountId, merchantId, role);
}

final merchantDataScopeProvider = Provider<MerchantDataScope?>((ref) {
  final accountId = ref.watch(
    sessionControllerProvider.select((s) => s.accountId),
  );
  final membership = ref.watch(
    accessControllerProvider.select((a) => a.membership),
  );
  if (membership == null) return null;
  return MerchantDataScope(
    accountId: accountId,
    merchantId: membership.merchantId,
    role: membership.role,
  );
});
