/// Server-managed commerce vertical a Branch can be classified under
/// (`GET /merchant/commerce-verticals`). A Branch has zero or one.
class CommerceVertical {
  const CommerceVertical({
    required this.id,
    required this.slug,
    required this.name,
    required this.iconKey,
    required this.sortOrder,
  });

  final String id;
  final String slug;
  final String name;
  final String? iconKey;
  final int sortOrder;

  factory CommerceVertical.fromJson(Map<String, dynamic> json) {
    return CommerceVertical(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconKey: json['iconKey']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The vertical currently assigned to a Branch.
class BranchClassification {
  const BranchClassification({
    required this.verticalId,
    required this.slug,
    required this.name,
    required this.iconKey,
  });

  final String verticalId;
  final String slug;
  final String name;
  final String? iconKey;

  /// Accepts the bare object or a `{ classification: {...} }` wrapper; returns
  /// `null` when nothing is assigned.
  static BranchClassification? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final wrapped = raw['classification'];
    final json = Map<String, dynamic>.from(wrapped is Map ? wrapped : raw);
    final id = json['verticalId']?.toString();
    if (id == null || id.isEmpty) return null;
    return BranchClassification(
      verticalId: id,
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconKey: json['iconKey']?.toString(),
    );
  }
}
