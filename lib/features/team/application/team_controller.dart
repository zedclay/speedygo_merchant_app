import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/team/data/team_models.dart';

Duration? _noAutomaticRetry(int _, Object _) => null;

const teamVersionConflictCode = 'TEAM_VERSION_CONFLICT';

/// French message for a failed team action, keyed on the backend error code
/// (server messages are not localised).
String teamErrorMessage(Object error) {
  if (error is ApiException) {
    switch (error.code) {
      case 'TEAM_VERSION_CONFLICT':
        return AppStrings.teamErrorConflict;
      case 'TEAM_DUPLICATE_MEMBER':
        return AppStrings.teamErrorDuplicateMember;
      case 'TEAM_DUPLICATE_INVITE':
        return AppStrings.teamErrorDuplicateInvite;
      case 'TEAM_OWNER_PROTECTED':
        return AppStrings.teamErrorOwnerProtected;
      case 'TEAM_SELF_FORBIDDEN':
        return AppStrings.teamErrorSelf;
      case 'TEAM_INVITE_NOT_FOUND':
        return AppStrings.teamErrorInviteGone;
      case 'TEAM_INVITE_EXPIRED':
        return AppStrings.teamErrorInviteExpired;
      case 'TEAM_INVITE_CODE_INVALID':
        return AppStrings.teamErrorCodeInvalid;
      case 'TEAM_PHONE_MISMATCH':
        return AppStrings.teamErrorPhoneMismatch;
      case 'TEAM_INVALID_INPUT':
        return AppStrings.teamErrorInvalidInput;
      case 'MERCHANT_ROLE_FORBIDDEN':
        return AppStrings.permissionDenied;
    }
    if (error.statusCode == 403) return AppStrings.permissionDenied;
    if (error.statusCode == 409) return AppStrings.teamErrorConflict;
  }
  if (error is NetworkException) return AppStrings.networkError;
  return AppStrings.teamErrorGeneric;
}

bool teamIsForbidden(Object error) =>
    error is ApiException &&
    (error.code == 'MERCHANT_ROLE_FORBIDDEN' || error.statusCode == 403);

/// Roster and pending invitations of the active Merchant.
///
/// STAFF never calls the API (`TEAM_READ` is OWNER/MANAGER); the screen shows
/// its forbidden state from the role. Mutations refresh the roster in place
/// (no loading flash) and re-read it after a version conflict.
class TeamController extends AsyncNotifier<MerchantTeam?> {
  @override
  Future<MerchantTeam?> build() async {
    final scope = ref.watch(merchantDataScopeProvider);
    if (scope == null || !merchantRoleCanReadTeam(scope.role)) return null;
    return ref.read(merchantApiProvider).getTeam(merchantId: scope.merchantId);
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // Rendered through `state` with a retry action.
    }
  }

  Future<TeamInvitationIssued> createInvitation({
    required String phone,
    required String role,
  }) {
    return _mutate(
      (api, merchantId) => api.createTeamInvitation(
        merchantId: merchantId,
        phone: phone,
        role: role,
      ),
    );
  }

  Future<TeamInvitationIssued> regenerateCode(TeamInvitation invitation) {
    return _mutate(
      (api, merchantId) => api.regenerateTeamInvitationCode(
        merchantId: merchantId,
        invitationId: invitation.id,
        expectedVersion: invitation.version,
      ),
    );
  }

  Future<void> cancelInvitation(TeamInvitation invitation) async {
    await _mutate(
      (api, merchantId) => api.cancelTeamInvitation(
        merchantId: merchantId,
        invitationId: invitation.id,
        expectedVersion: invitation.version,
      ),
    );
  }

  Future<void> changeRole(TeamMember member, String role) async {
    await _mutate(
      (api, merchantId) => api.updateTeamMemberRole(
        merchantId: merchantId,
        memberId: member.id,
        role: role,
        expectedVersion: member.version,
      ),
    );
  }

  Future<void> revoke(TeamMember member) async {
    await _mutate(
      (api, merchantId) => api.revokeTeamMember(
        merchantId: merchantId,
        memberId: member.id,
        expectedVersion: member.version,
      ),
    );
  }

  Future<T> _mutate<T>(
    Future<T> Function(MerchantClient api, String merchantId) action,
  ) async {
    final scope = ref.read(merchantDataScopeProvider);
    if (scope == null) {
      throw const ApiException(
        AppStrings.teamErrorGeneric,
        code: 'MERCHANT_NOT_FOUND',
        statusCode: 404,
      );
    }
    final api = ref.read(merchantApiProvider);
    try {
      final result = await action(api, scope.merchantId);
      await _refreshInPlace(scope);
      return result;
    } on ApiException catch (e) {
      if (e.code == teamVersionConflictCode || e.statusCode == 409) {
        await _refreshInPlace(scope);
      }
      rethrow;
    }
  }

  Future<void> _refreshInPlace(MerchantDataScope scope) async {
    try {
      final team = await ref
          .read(merchantApiProvider)
          .getTeam(merchantId: scope.merchantId);
      if (!ref.mounted || ref.read(merchantDataScopeProvider) != scope) return;
      state = AsyncData(team);
    } catch (_) {
      // The mutation outcome is reported by the caller; keep the last roster.
    }
  }
}

final teamControllerProvider =
    AsyncNotifierProvider.autoDispose<TeamController, MerchantTeam?>(
      TeamController.new,
      retry: _noAutomaticRetry,
    );

/// Invitations addressed to the signed-in phone, plus the accept action.
class MyTeamInvitationsController
    extends AsyncNotifier<List<MyTeamInvitation>> {
  @override
  Future<List<MyTeamInvitation>> build() async {
    ref.watch(accessControllerProvider.select((a) => a.membership?.merchantId));
    return ref.read(merchantApiProvider).listMyTeamInvitations();
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // Rendered through `state` with a retry action.
    }
  }

  /// Accepts [invitation] with the manually shared [acceptCode]. The list is
  /// re-read and the access state refreshed in place so the new Merchant is
  /// available without signing out.
  Future<TeamInvitationAccepted> accept(
    MyTeamInvitation invitation,
    String acceptCode,
  ) async {
    final api = ref.read(merchantApiProvider);
    final accepted = await api.acceptTeamInvitation(
      invitationId: invitation.id,
      acceptCode: acceptCode,
    );
    try {
      final list = await api.listMyTeamInvitations();
      if (ref.mounted) state = AsyncData(list);
    } catch (_) {
      if (ref.mounted) {
        final current = state.value ?? const <MyTeamInvitation>[];
        state = AsyncData([
          for (final i in current)
            if (i.id != invitation.id) i,
        ]);
      }
    }
    if (ref.mounted) {
      await ref.read(accessControllerProvider.notifier).refreshInPlace();
    }
    return accepted;
  }
}

final myTeamInvitationsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      MyTeamInvitationsController,
      List<MyTeamInvitation>
    >(MyTeamInvitationsController.new, retry: _noAutomaticRetry);
