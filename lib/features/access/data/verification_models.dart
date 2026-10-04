/// Legal document kinds the backend requires on every verification submit.
class LegalKind {
  const LegalKind._();

  static const merchantTerms = 'MERCHANT_TERMS';
  static const dossierAccuracyDeclaration = 'DOSSIER_ACCURACY_DECLARATION';
}

/// One active legal version from `GET /merchant/legal/current`.
class LegalVersion {
  const LegalVersion({
    required this.kind,
    required this.version,
    this.contentUrl,
    this.contentSha256,
    this.effectiveFrom,
  });

  final String kind;
  final String version;
  final String? contentUrl;
  final String? contentSha256;
  final String? effectiveFrom;

  factory LegalVersion.fromJson(Map<String, dynamic> json) {
    return LegalVersion(
      kind: json['kind']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      contentUrl: json['contentUrl']?.toString(),
      contentSha256: json['contentSha256']?.toString(),
      effectiveFrom: json['effectiveFrom']?.toString(),
    );
  }

  LegalAcceptance toAcceptance() =>
      LegalAcceptance(kind: kind, version: version);
}

class LegalCurrent {
  const LegalCurrent({required this.versions});

  final List<LegalVersion> versions;

  factory LegalCurrent.fromJson(Map<String, dynamic> json) {
    final raw = json['versions'];
    return LegalCurrent(
      versions: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => LegalVersion.fromJson(Map<String, dynamic>.from(e)))
                .where((v) => v.kind.isNotEmpty && v.version.isNotEmpty)
                .toList()
          : const [],
    );
  }

  LegalVersion? versionOf(String kind) {
    for (final v in versions) {
      if (v.kind == kind) return v;
    }
    return null;
  }

  LegalVersion? get terms => versionOf(LegalKind.merchantTerms);
  LegalVersion? get declaration =>
      versionOf(LegalKind.dossierAccuracyDeclaration);

  /// Both consents the backend requires are published.
  bool get isComplete => terms != null && declaration != null;
}

/// Entry of the `acceptances` body sent with verification submit.
class LegalAcceptance {
  const LegalAcceptance({required this.kind, required this.version});

  final String kind;
  final String version;

  Map<String, dynamic> toJson() => {'kind': kind, 'version': version};
}

/// OWNER-only record of the consent given with the latest submission.
class MerchantLegalAcceptanceRecord {
  const MerchantLegalAcceptanceRecord({
    required this.termsVersion,
    required this.declarationVersion,
    this.acceptedAt,
  });

  final String termsVersion;
  final String declarationVersion;
  final String? acceptedAt;

  static MerchantLegalAcceptanceRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    return MerchantLegalAcceptanceRecord(
      termsVersion: json['termsVersion']?.toString() ?? '',
      declarationVersion: json['declarationVersion']?.toString() ?? '',
      acceptedAt: json['acceptedAt']?.toString(),
    );
  }
}

class VerificationIssueScope {
  const VerificationIssueScope._();

  static const application = 'APPLICATION';
  static const document = 'DOCUMENT';
}

/// Structured rejection issue. [messageFr] is the primary user-facing text.
class VerificationIssue {
  const VerificationIssue({
    required this.scope,
    required this.code,
    required this.messageFr,
    this.documentType,
    this.resolvedAt,
  });

  final String scope;
  final String code;
  final String messageFr;
  final String? documentType;
  final String? resolvedAt;

  bool get isDocument => scope.toUpperCase() == VerificationIssueScope.document;
  bool get isResolved => resolvedAt != null && resolvedAt!.isNotEmpty;

  factory VerificationIssue.fromJson(Map<String, dynamic> json) {
    final documentType = json['documentType']?.toString();
    return VerificationIssue(
      scope: json['scope']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      messageFr: json['messageFr']?.toString() ?? '',
      documentType: documentType == null || documentType.isEmpty
          ? null
          : documentType,
      resolvedAt: json['resolvedAt']?.toString(),
    );
  }
}
