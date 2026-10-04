import 'package:speedygo_merchant_app/features/access/data/verification_models.dart';
import 'package:speedygo_merchant_app/features/store/data/classification_models.dart';

export 'package:speedygo_merchant_app/features/orders/data/order_models.dart'
    show
        AssignedDriverSummary,
        AssignedDriverVehicleSummary,
        MerchantDeliverySummary,
        MerchantOrderAction,
        MerchantOrderDetail,
        MerchantOrderListFilter,
        MerchantOrderListFilterX,
        MerchantOrderListPage,
        MerchantOrderSummary,
        MerchantPickupHandoff,
        merchantActionsFor,
        merchantRoleCanMutateOrders;
export 'package:speedygo_merchant_app/features/access/data/verification_models.dart';

class MerchantBranch {
  const MerchantBranch({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    required this.operationalStatus,
    this.wilayaCode,
    this.communeId,
    this.wilayaNameFr,
    this.communeNameFr,
    this.description,
    this.nameAr,
    this.publicEmail,
    this.classification,
  });

  final String id;
  final String name;
  final String phone;
  final String addressText;
  final double latitude;
  final double longitude;
  final String operationalStatus;
  final String? wilayaCode;
  final int? communeId;
  final String? wilayaNameFr;
  final String? communeNameFr;
  final String? description;
  final String? nameAr;
  final String? publicEmail;
  final BranchClassification? classification;

  factory MerchantBranch.fromJson(Map<String, dynamic> json) {
    return MerchantBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressText: json['addressText']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      operationalStatus: json['operationalStatus']?.toString() ?? '',
      wilayaCode: json['wilayaCode']?.toString(),
      communeId: (json['communeId'] as num?)?.toInt(),
      wilayaNameFr: json['wilayaNameFr']?.toString(),
      communeNameFr: json['communeNameFr']?.toString(),
      description: _optionalText(json['description']),
      nameAr: _optionalText(json['nameAr']),
      publicEmail: _optionalText(json['publicEmail']),
      classification: BranchClassification.tryParse(json['classification']),
    );
  }
}

String? _optionalText(Object? raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

class MerchantEvidenceItem {
  const MerchantEvidenceItem({
    required this.type,
    required this.required,
    required this.present,
    required this.complete,
    this.status,
  });

  final String type;
  final bool required;
  final bool present;
  final bool complete;
  final String? status;

  factory MerchantEvidenceItem.fromJson(Map<String, dynamic> json) {
    return MerchantEvidenceItem(
      type: json['type']?.toString() ?? '',
      required: json['required'] == true,
      present: json['present'] == true,
      complete: json['complete'] == true,
      status: json['status']?.toString(),
    );
  }
}

class MerchantMembership {
  const MerchantMembership({
    required this.merchantId,
    required this.role,
    required this.profileComplete,
    required this.hasBranch,
    required this.branchReady,
    required this.approved,
    required this.operationalReady,
    required this.verificationReady,
    required this.verificationSubmitted,
    required this.verificationAttentionRequired,
    required this.merchantName,
    required this.merchantStatus,
    required this.merchantPublicReference,
    required this.verifiedAt,
    required this.branches,
    required this.evidenceChecklist,
    this.submittedAt,
    this.reviewedAt,
    this.attemptNumber,
    this.legalAcceptance,
    this.currentIssues = const [],
    this.unresolvedIssueCount = 0,
  });

  final String merchantId;
  final String role;
  final bool profileComplete;
  final bool hasBranch;
  final bool branchReady;
  final bool approved;
  final bool operationalReady;
  final bool verificationReady;
  final bool verificationSubmitted;
  final bool verificationAttentionRequired;
  final String merchantName;
  final String merchantStatus;
  final String merchantPublicReference;
  final String? verifiedAt;
  final List<MerchantBranch> branches;
  final List<MerchantEvidenceItem> evidenceChecklist;

  /// Latest submission time; null for legacy Merchants.
  final String? submittedAt;
  final String? reviewedAt;
  final int? attemptNumber;

  /// OWNER only; null for legacy Merchants or non-owner roles.
  final MerchantLegalAcceptanceRecord? legalAcceptance;

  /// OWNER only; unresolved issues of the latest REJECTED submission.
  final List<VerificationIssue> currentIssues;
  final int unresolvedIssueCount;

  List<VerificationIssue> get unresolvedIssues =>
      currentIssues.where((i) => !i.isResolved).toList();

  factory MerchantMembership.fromJson(Map<String, dynamic> json) {
    final merchant = json['merchant'];
    final branchesRaw = json['branches'];
    final checklistRaw = json['evidenceChecklist'];
    final issuesRaw = json['currentIssues'];
    final issues = issuesRaw is List
        ? issuesRaw
              .whereType<Map>()
              .map(
                (e) => VerificationIssue.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const <VerificationIssue>[];
    return MerchantMembership(
      submittedAt: json['submittedAt']?.toString(),
      reviewedAt: json['reviewedAt']?.toString(),
      attemptNumber: (json['attemptNumber'] as num?)?.toInt(),
      legalAcceptance: MerchantLegalAcceptanceRecord.fromJson(
        json['legalAcceptance'],
      ),
      currentIssues: issues,
      unresolvedIssueCount:
          (json['unresolvedIssueCount'] as num?)?.toInt() ??
          issues.where((i) => !i.isResolved).length,
      merchantId: json['merchantId']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profileComplete: json['profileComplete'] == true,
      hasBranch: json['hasBranch'] == true,
      branchReady: json['branchReady'] == true,
      approved: json['approved'] == true,
      operationalReady: json['operationalReady'] == true,
      verificationReady: json['verificationReady'] == true,
      verificationSubmitted: json['verificationSubmitted'] == true,
      verificationAttentionRequired:
          json['verificationAttentionRequired'] == true,
      merchantName: merchant is Map ? merchant['name']?.toString() ?? '' : '',
      merchantStatus: merchant is Map
          ? merchant['status']?.toString() ?? ''
          : '',
      merchantPublicReference: merchant is Map
          ? merchant['publicReference']?.toString() ?? ''
          : '',
      verifiedAt: merchant is Map ? merchant['verifiedAt']?.toString() : null,
      branches: branchesRaw is List
          ? branchesRaw
                .whereType<Map>()
                .map(
                  (e) => MerchantBranch.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      evidenceChecklist: checklistRaw is List
          ? checklistRaw
                .whereType<Map>()
                .map(
                  (e) => MerchantEvidenceItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const [],
    );
  }

  List<MerchantBranch> get activeBranches => branches
      .where((b) => b.operationalStatus.toUpperCase() == 'ACTIVE')
      .toList();
}

class MerchantMe {
  const MerchantMe({
    required this.merchantMembershipExists,
    required this.memberships,
  });

  final bool merchantMembershipExists;
  final List<MerchantMembership> memberships;

  factory MerchantMe.fromJson(Map<String, dynamic> json) {
    final list = json['memberships'];
    return MerchantMe(
      merchantMembershipExists: json['merchantMembershipExists'] == true,
      memberships: list is List
          ? list
                .whereType<Map>()
                .map(
                  (e) =>
                      MerchantMembership.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}
