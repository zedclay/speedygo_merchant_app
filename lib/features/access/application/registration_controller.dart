import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';

enum RegistrationStep { account, activity, documents, establishment, review }

enum RegistrationIntent { undecided, owner, operatorJoinUnsupported }

class LocalEvidenceDraft {
  const LocalEvidenceDraft({
    required this.type,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    this.uploading = false,
    this.error,
  });

  final String type;
  final String filename;
  final String contentType;
  final int sizeBytes;
  final bool uploading;
  final String? error;

  LocalEvidenceDraft copyWith({
    bool? uploading,
    String? error,
    bool clearError = false,
  }) {
    return LocalEvidenceDraft(
      type: type,
      filename: filename,
      contentType: contentType,
      sizeBytes: sizeBytes,
      uploading: uploading ?? this.uploading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RegistrationState {
  const RegistrationState({
    this.step = RegistrationStep.account,
    this.intent = RegistrationIntent.undecided,
    this.merchantNameDraft = '',
    this.branchNameDraft = '',
    this.branchPhoneDraft = '',
    this.branchAddressDraft = '',
    this.branchLatDraft = '',
    this.branchLngDraft = '',
    this.branchWilayaCodeDraft,
    this.branchCommuneIdDraft,
    this.branchWilayaLabelDraft,
    this.branchCommuneLabelDraft,
    this.locationConfirmed = false,
    this.membership,
    this.localEvidence = const {},
    this.busy = false,
    this.errorMessage,
    this.createInFlight = false,
    this.legal,
    this.legalLoading = false,
    this.legalLoadFailed = false,
    this.termsAccepted = false,
    this.declarationAccepted = false,
  });

  final RegistrationStep step;
  final RegistrationIntent intent;
  final String merchantNameDraft;
  final String branchNameDraft;
  final String branchPhoneDraft;
  final String branchAddressDraft;
  final String branchLatDraft;
  final String branchLngDraft;
  final String? branchWilayaCodeDraft;
  final int? branchCommuneIdDraft;
  final String? branchWilayaLabelDraft;
  final String? branchCommuneLabelDraft;

  /// True only after explicit map confirmation or hydrate from saved branch coords.
  final bool locationConfirmed;
  final MerchantMembership? membership;
  final Map<String, LocalEvidenceDraft> localEvidence;
  final bool busy;
  final String? errorMessage;
  final bool createInFlight;

  /// Active legal versions; consents are only valid for these exact versions.
  final LegalCurrent? legal;
  final bool legalLoading;
  final bool legalLoadFailed;
  final bool termsAccepted;
  final bool declarationAccepted;

  bool get consentsComplete =>
      legal?.isComplete == true && termsAccepted && declarationAccepted;

  /// Acceptances to send, from the loaded versions; null until both are
  /// published and ticked.
  List<LegalAcceptance>? get acceptancesToSubmit {
    if (!consentsComplete) return null;
    return [legal!.terms!.toAcceptance(), legal!.declaration!.toAcceptance()];
  }

  bool get hasServerMerchant =>
      membership != null && membership!.merchantId.isNotEmpty;

  bool get hasValidConfirmedLocation {
    if (!locationConfirmed) return false;
    final lat = double.tryParse(branchLatDraft.trim());
    final lng = double.tryParse(branchLngDraft.trim());
    return lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  int get sectionIndex => switch (step) {
    RegistrationStep.account => 1,
    RegistrationStep.activity => 2,
    RegistrationStep.documents => 3,
    RegistrationStep.establishment => 4,
    RegistrationStep.review => 4,
  };

  RegistrationState copyWith({
    RegistrationStep? step,
    RegistrationIntent? intent,
    String? merchantNameDraft,
    String? branchNameDraft,
    String? branchPhoneDraft,
    String? branchAddressDraft,
    String? branchLatDraft,
    String? branchLngDraft,
    String? branchWilayaCodeDraft,
    int? branchCommuneIdDraft,
    String? branchWilayaLabelDraft,
    String? branchCommuneLabelDraft,
    bool? locationConfirmed,
    MerchantMembership? membership,
    Map<String, LocalEvidenceDraft>? localEvidence,
    bool? busy,
    String? errorMessage,
    bool? createInFlight,
    LegalCurrent? legal,
    bool? legalLoading,
    bool? legalLoadFailed,
    bool? termsAccepted,
    bool? declarationAccepted,
    bool clearError = false,
    bool clearMembership = false,
    bool clearAdminLocation = false,
    bool clearCommune = false,
  }) {
    return RegistrationState(
      step: step ?? this.step,
      intent: intent ?? this.intent,
      merchantNameDraft: merchantNameDraft ?? this.merchantNameDraft,
      branchNameDraft: branchNameDraft ?? this.branchNameDraft,
      branchPhoneDraft: branchPhoneDraft ?? this.branchPhoneDraft,
      branchAddressDraft: branchAddressDraft ?? this.branchAddressDraft,
      branchLatDraft: branchLatDraft ?? this.branchLatDraft,
      branchLngDraft: branchLngDraft ?? this.branchLngDraft,
      branchWilayaCodeDraft: clearAdminLocation
          ? null
          : (branchWilayaCodeDraft ?? this.branchWilayaCodeDraft),
      branchCommuneIdDraft: clearAdminLocation || clearCommune
          ? null
          : (branchCommuneIdDraft ?? this.branchCommuneIdDraft),
      branchWilayaLabelDraft: clearAdminLocation
          ? null
          : (branchWilayaLabelDraft ?? this.branchWilayaLabelDraft),
      branchCommuneLabelDraft: clearAdminLocation || clearCommune
          ? null
          : (branchCommuneLabelDraft ?? this.branchCommuneLabelDraft),
      locationConfirmed: locationConfirmed ?? this.locationConfirmed,
      membership: clearMembership ? null : (membership ?? this.membership),
      localEvidence: localEvidence ?? this.localEvidence,
      busy: busy ?? this.busy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createInFlight: createInFlight ?? this.createInFlight,
      legal: legal ?? this.legal,
      legalLoading: legalLoading ?? this.legalLoading,
      legalLoadFailed: legalLoadFailed ?? this.legalLoadFailed,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      declarationAccepted: declarationAccepted ?? this.declarationAccepted,
    );
  }
}

class RegistrationController extends Notifier<RegistrationState> {
  late MerchantClient _api;
  var _mutationGeneration = 0;

  @override
  RegistrationState build() {
    _api = ref.read(merchantApiProvider);
    ref.listen(sessionControllerProvider, (prev, next) {
      if (prev?.accountId != null &&
          next.accountId != null &&
          prev!.accountId != next.accountId) {
        state = const RegistrationState();
      }
      if (next.phase == SessionPhase.signedOut) {
        state = const RegistrationState();
      }
    });
    ref.listen(accessControllerProvider, (prev, next) {
      if (next.destination == AccessDestination.registration ||
          next.destination == AccessDestination.noMembership ||
          next.destination == AccessDestination.verificationRejected) {
        hydrateFromAccess(next.membership);
      }
    });
    return const RegistrationState();
  }

  void hydrateFromAccess(MerchantMembership? membership) {
    if (membership == null) {
      if (state.hasServerMerchant) return;
      return;
    }
    final branch = membership.branches.isNotEmpty
        ? membership.branches.first
        : null;
    final hasSavedCoords =
        branch != null &&
        branch.latitude.isFinite &&
        branch.longitude.isFinite &&
        branch.latitude >= -90 &&
        branch.latitude <= 90 &&
        branch.longitude >= -180 &&
        branch.longitude <= 180 &&
        !(branch.latitude == 0 && branch.longitude == 0);
    state = state.copyWith(
      intent: RegistrationIntent.owner,
      membership: membership,
      merchantNameDraft: membership.merchantName.isNotEmpty
          ? membership.merchantName
          : state.merchantNameDraft,
      branchNameDraft: branch?.name ?? state.branchNameDraft,
      branchPhoneDraft: branch?.phone ?? state.branchPhoneDraft,
      branchAddressDraft: branch?.addressText ?? state.branchAddressDraft,
      branchLatDraft: hasSavedCoords
          ? branch.latitude.toString()
          : state.branchLatDraft,
      branchLngDraft: hasSavedCoords
          ? branch.longitude.toString()
          : state.branchLngDraft,
      branchWilayaCodeDraft: branch?.wilayaCode ?? state.branchWilayaCodeDraft,
      branchCommuneIdDraft: branch?.communeId ?? state.branchCommuneIdDraft,
      branchWilayaLabelDraft:
          branch?.wilayaNameFr ?? state.branchWilayaLabelDraft,
      branchCommuneLabelDraft:
          branch?.communeNameFr ?? state.branchCommuneLabelDraft,
      locationConfirmed: hasSavedCoords ? true : state.locationConfirmed,
      step: _resumeStep(membership),
      clearError: true,
    );
  }

  RegistrationStep _resumeStep(MerchantMembership m) {
    if (!m.profileComplete && m.merchantName.isEmpty) {
      return RegistrationStep.activity;
    }
    final missingDocs = m.evidenceChecklist.any(
      (e) => e.required && !e.complete,
    );
    if (missingDocs) return RegistrationStep.documents;
    if (!m.hasBranch || m.branches.isEmpty) {
      return RegistrationStep.establishment;
    }
    if (!m.verificationSubmitted) return RegistrationStep.review;
    return RegistrationStep.review;
  }

  void setIntent(RegistrationIntent intent) {
    state = state.copyWith(intent: intent, clearError: true);
  }

  void goTo(RegistrationStep step) {
    state = state.copyWith(step: step, clearError: true);
  }

  void reportUiError(String message) {
    state = state.copyWith(busy: false, errorMessage: message);
  }

  void updateMerchantNameDraft(String value) {
    state = state.copyWith(merchantNameDraft: value);
  }

  void updateBranchDraft({
    String? name,
    String? phone,
    String? address,
    String? lat,
    String? lng,
  }) {
    state = state.copyWith(
      branchNameDraft: name ?? state.branchNameDraft,
      branchPhoneDraft: phone ?? state.branchPhoneDraft,
      branchAddressDraft: address ?? state.branchAddressDraft,
      branchLatDraft: lat ?? state.branchLatDraft,
      branchLngDraft: lng ?? state.branchLngDraft,
    );
  }

  void setWilayaDraft({required String code, required String label}) {
    state = state.copyWith(
      branchWilayaCodeDraft: code,
      branchWilayaLabelDraft: label,
      clearCommune: true,
      clearError: true,
    );
  }

  void setCommuneDraft({required int id, required String label}) {
    state = state.copyWith(
      branchCommuneIdDraft: id,
      branchCommuneLabelDraft: label,
      clearError: true,
    );
  }

  /// Applies an explicitly confirmed map selection to the local draft only.
  void confirmLocationDraft({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      state = state.copyWith(errorMessage: AppStrings.regCoordsInvalid);
      return;
    }
    state = state.copyWith(
      branchLatDraft: latitude.toString(),
      branchLngDraft: longitude.toString(),
      locationConfirmed: true,
      clearError: true,
    );
  }

  Future<void> continueFromAccount() async {
    if (state.intent == RegistrationIntent.undecided) {
      state = state.copyWith(errorMessage: AppStrings.regSelectRole);
      return;
    }
    if (state.intent == RegistrationIntent.operatorJoinUnsupported) {
      state = state.copyWith(errorMessage: AppStrings.regOperatorUnsupported);
      return;
    }
    state = state.copyWith(step: RegistrationStep.activity, clearError: true);
  }

  /// Creates merchant once. Never recreates when identity already known.
  Future<void> saveActivityAndContinue() async {
    if (state.busy || state.createInFlight) return;
    final name = state.merchantNameDraft.trim();
    if (name.isEmpty) {
      state = state.copyWith(errorMessage: AppStrings.merchantNameHint);
      return;
    }
    final gen = ++_mutationGeneration;
    final accountId = ref.read(sessionControllerProvider).accountId;

    if (state.hasServerMerchant) {
      final merchantId = state.membership!.merchantId;
      if (name == state.membership!.merchantName) {
        state = state.copyWith(
          step: RegistrationStep.documents,
          clearError: true,
        );
        return;
      }
      state = state.copyWith(busy: true, clearError: true);
      try {
        final updated = await _api.updateProfile(
          merchantId: merchantId,
          name: name,
        );
        if (!_ok(gen, accountId)) return;
        state = state.copyWith(
          membership: updated,
          merchantNameDraft: updated.merchantName,
          step: RegistrationStep.documents,
          busy: false,
          clearError: true,
        );
      } on ApiException catch (e) {
        if (!_ok(gen, accountId)) return;
        state = state.copyWith(
          busy: false,
          errorMessage: AppStrings.errorForCode(e.code),
        );
      } catch (_) {
        if (!_ok(gen, accountId)) return;
        state = state.copyWith(
          busy: false,
          errorMessage: AppStrings.networkError,
        );
      }
      return;
    }

    state = state.copyWith(busy: true, createInFlight: true, clearError: true);
    try {
      // Reconcile before create — avoid duplicate merchants.
      final me = await _api.me();
      if (!_ok(gen, accountId)) return;
      if (me.merchantMembershipExists && me.memberships.isNotEmpty) {
        final existing = me.memberships.first;
        state = state.copyWith(
          membership: existing,
          merchantNameDraft: existing.merchantName.isNotEmpty
              ? existing.merchantName
              : name,
          step: _resumeStep(existing),
          busy: false,
          createInFlight: false,
          clearError: true,
        );
        return;
      }
      final created = await _api.createProfile(name: name);
      if (!_ok(gen, accountId)) return;
      state = state.copyWith(
        membership: created,
        merchantNameDraft: created.merchantName,
        step: RegistrationStep.documents,
        busy: false,
        createInFlight: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!_ok(gen, accountId)) return;
      // Conflict / already exists → reconcile.
      try {
        final me = await _api.me();
        if (!_ok(gen, accountId)) return;
        if (me.memberships.isNotEmpty) {
          final existing = me.memberships.first;
          state = state.copyWith(
            membership: existing,
            merchantNameDraft: existing.merchantName,
            step: _resumeStep(existing),
            busy: false,
            createInFlight: false,
            clearError: true,
          );
          return;
        }
      } catch (_) {}
      state = state.copyWith(
        busy: false,
        createInFlight: false,
        errorMessage: AppStrings.errorForCode(e.code),
      );
    } catch (_) {
      if (!_ok(gen, accountId)) return;
      state = state.copyWith(
        busy: false,
        createInFlight: false,
        errorMessage: AppStrings.networkError,
      );
    }
  }

  Future<void> uploadAndBindEvidence({
    required String type,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final membership = state.membership;
    if (membership == null) return;
    if (state.busy) return;
    if (bytes.length > 10 * 1024 * 1024) {
      state = state.copyWith(errorMessage: AppStrings.regFileTooLarge);
      return;
    }
    final allowed = {'application/pdf', 'image/jpeg', 'image/png', 'image/jpg'};
    if (!allowed.contains(contentType.toLowerCase())) {
      state = state.copyWith(errorMessage: AppStrings.regFileTypeUnsupported);
      return;
    }

    final gen = ++_mutationGeneration;
    final accountId = ref.read(sessionControllerProvider).accountId;
    final draft = LocalEvidenceDraft(
      type: type,
      filename: filename,
      contentType: contentType,
      sizeBytes: bytes.length,
      uploading: true,
    );
    state = state.copyWith(
      localEvidence: {...state.localEvidence, type: draft},
      busy: true,
      clearError: true,
    );
    try {
      final uploaded = await _api.uploadEvidenceContent(
        merchantId: membership.merchantId,
        type: type,
        filename: filename,
        contentType: contentType,
        bytes: bytes,
      );
      if (!_ok(gen, accountId)) return;
      if (uploaded.uploadReference.isEmpty) {
        throw const ApiException(
          'Upload incomplete',
          code: 'UPLOAD_INCOMPLETE',
        );
      }
      final bound = await _api.bindEvidence(
        merchantId: membership.merchantId,
        type: type,
        uploadReference: uploaded.uploadReference,
      );
      if (!_ok(gen, accountId)) return;
      final nextLocal = Map<String, LocalEvidenceDraft>.from(
        state.localEvidence,
      )..[type] = draft.copyWith(uploading: false, clearError: true);
      state = state.copyWith(
        membership: bound,
        localEvidence: nextLocal,
        busy: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!_ok(gen, accountId)) return;
      final nextLocal =
          Map<String, LocalEvidenceDraft>.from(state.localEvidence)
            ..[type] = draft.copyWith(
              uploading: false,
              error: AppStrings.errorForCode(e.code),
            );
      state = state.copyWith(
        localEvidence: nextLocal,
        busy: false,
        errorMessage: AppStrings.errorForCode(e.code),
      );
    } catch (_) {
      if (!_ok(gen, accountId)) return;
      final nextLocal =
          Map<String, LocalEvidenceDraft>.from(state.localEvidence)
            ..[type] = draft.copyWith(
              uploading: false,
              error: AppStrings.networkError,
            );
      state = state.copyWith(
        localEvidence: nextLocal,
        busy: false,
        errorMessage: AppStrings.networkError,
      );
    }
  }

  Future<void> continueFromDocuments() async {
    final m = state.membership;
    if (m == null) return;
    final missing = m.evidenceChecklist
        .where((e) => e.required && !e.complete)
        .toList();
    if (missing.isNotEmpty) {
      state = state.copyWith(errorMessage: AppStrings.regDocsRequired);
      return;
    }
    state = state.copyWith(
      step: RegistrationStep.establishment,
      clearError: true,
    );
  }

  Future<void> saveEstablishmentAndContinue() async {
    if (state.busy) return;
    final m = state.membership;
    if (m == null) return;
    final name = state.branchNameDraft.trim();
    final phone = state.branchPhoneDraft.trim();
    final address = state.branchAddressDraft.trim();
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      state = state.copyWith(errorMessage: AppStrings.regBranchIncomplete);
      return;
    }
    if (!state.hasValidConfirmedLocation) {
      state = state.copyWith(errorMessage: AppStrings.regLocationRequired);
      return;
    }
    final wilayaCode = state.branchWilayaCodeDraft?.trim();
    final communeId = state.branchCommuneIdDraft;
    if (wilayaCode == null || wilayaCode.isEmpty || communeId == null) {
      state = state.copyWith(
        errorMessage: AppStrings.adminLocationPairRequired,
      );
      return;
    }
    final lat = double.parse(state.branchLatDraft.trim());
    final lng = double.parse(state.branchLngDraft.trim());
    final gen = ++_mutationGeneration;
    final accountId = ref.read(sessionControllerProvider).accountId;
    state = state.copyWith(busy: true, clearError: true);
    try {
      if (m.branches.isEmpty) {
        await _api.createBranch(
          merchantId: m.merchantId,
          name: name,
          phone: phone,
          addressText: address,
          latitude: lat,
          longitude: lng,
          wilayaCode: wilayaCode,
          communeId: communeId,
        );
      } else {
        await _api.updateBranch(
          merchantId: m.merchantId,
          branchId: m.branches.first.id,
          name: name,
          phone: phone,
          addressText: address,
          latitude: lat,
          longitude: lng,
          wilayaCode: wilayaCode,
          communeId: communeId,
        );
      }
      if (!_ok(gen, accountId)) return;
      final me = await _api.me();
      if (!_ok(gen, accountId)) return;
      final refreshed = me.memberships.firstWhere(
        (x) => x.merchantId == m.merchantId,
        orElse: () => me.memberships.isNotEmpty ? me.memberships.first : m,
      );
      state = state.copyWith(
        membership: refreshed,
        step: RegistrationStep.review,
        busy: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!_ok(gen, accountId)) return;
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.errorForCode(e.code),
      );
    } catch (_) {
      if (!_ok(gen, accountId)) return;
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.networkError,
      );
    }
  }

  void setTermsAccepted(bool value) {
    state = state.copyWith(termsAccepted: value, clearError: true);
  }

  void setDeclarationAccepted(bool value) {
    state = state.copyWith(declarationAccepted: value, clearError: true);
  }

  /// Loads the active legal versions. When the published versions differ from
  /// the ones already shown, any ticked consent is dropped so the Merchant
  /// re-accepts the new text.
  Future<void> loadLegal({bool force = false}) async {
    if (state.legalLoading) return;
    if (!force && state.legal != null) return;
    final accountId = ref.read(sessionControllerProvider).accountId;
    state = state.copyWith(legalLoading: true, legalLoadFailed: false);
    try {
      final legal = await _api.getLegalCurrent();
      if (!_sessionStillCurrent(accountId)) return;
      final changed = !_sameLegalVersions(state.legal, legal);
      state = state.copyWith(
        legal: legal,
        legalLoading: false,
        legalLoadFailed: false,
        termsAccepted: changed ? false : state.termsAccepted,
        declarationAccepted: changed ? false : state.declarationAccepted,
      );
    } catch (_) {
      if (!_sessionStillCurrent(accountId)) return;
      state = state.copyWith(legalLoading: false, legalLoadFailed: true);
    }
  }

  static bool _sameLegalVersions(LegalCurrent? a, LegalCurrent b) {
    if (a == null) return false;
    return a.terms?.version == b.terms?.version &&
        a.declaration?.version == b.declaration?.version;
  }

  Future<void> submitForReview() async {
    if (state.busy) return;
    final m = state.membership;
    if (m == null) return;
    // A REJECTED dossier is always resubmittable (documents may be unchanged
    // and still read as formally submitted).
    final resubmitting = m.merchantStatus.toUpperCase() == 'REJECTED';
    if (!m.verificationReady) {
      state = state.copyWith(
        errorMessage: AppStrings.submitVerificationUnavailable,
      );
      return;
    }
    if (m.verificationSubmitted && !resubmitting) {
      await ref.read(accessControllerProvider.notifier).resolve();
      return;
    }
    final acceptances = state.acceptancesToSubmit;
    if (acceptances == null) {
      state = state.copyWith(errorMessage: AppStrings.legalConsentRequired);
      return;
    }
    final gen = ++_mutationGeneration;
    final accountId = ref.read(sessionControllerProvider).accountId;
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _api.submitVerification(m.merchantId, acceptances: acceptances);
      if (!_ok(gen, accountId)) return;
      state = state.copyWith(
        busy: false,
        termsAccepted: false,
        declarationAccepted: false,
      );
      await ref.read(accessControllerProvider.notifier).resolve();
    } on ApiException catch (e) {
      if (!_ok(gen, accountId)) return;
      if (e.code == 'LEGAL_VERSION_OUTDATED' ||
          e.code == 'LEGAL_ACCEPTANCE_REQUIRED') {
        // Nothing was submitted: refresh versions and require a new consent.
        final outdated = e.code == 'LEGAL_VERSION_OUTDATED';
        state = state.copyWith(
          busy: false,
          termsAccepted: outdated ? false : null,
          declarationAccepted: outdated ? false : null,
          errorMessage: AppStrings.errorForCode(e.code),
        );
        await loadLegal(force: true);
        return;
      }
      // Reconcile ambiguous submit.
      try {
        final me = await _api.me();
        if (!_ok(gen, accountId)) return;
        final refreshed = me.memberships
            .where((x) => x.merchantId == m.merchantId)
            .cast<MerchantMembership?>()
            .followedBy([null])
            .first;
        final submitted = resubmitting
            ? refreshed != null &&
                  refreshed.merchantStatus.toUpperCase() != 'REJECTED'
            : refreshed?.verificationSubmitted == true;
        if (submitted) {
          state = state.copyWith(membership: refreshed, busy: false);
          await ref.read(accessControllerProvider.notifier).resolve();
          return;
        }
      } catch (_) {}
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.errorForCode(e.code),
      );
    } catch (_) {
      if (!_ok(gen, accountId)) return;
      state = state.copyWith(
        busy: false,
        errorMessage: AppStrings.networkError,
      );
    }
  }

  bool _sessionStillCurrent(String? accountId) {
    final session = ref.read(sessionControllerProvider);
    if (session.phase == SessionPhase.signedOut) return false;
    return accountId == null ||
        session.accountId == null ||
        session.accountId == accountId;
  }

  bool _ok(int gen, String? accountId) {
    if (gen != _mutationGeneration) return false;
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

final registrationControllerProvider =
    NotifierProvider<RegistrationController, RegistrationState>(
      RegistrationController.new,
    );
