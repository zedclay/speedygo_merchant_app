class AlgeriaWilaya {
  const AlgeriaWilaya({
    required this.code,
    required this.nameFr,
    required this.nameAr,
  });

  final String code;
  final String nameFr;
  final String nameAr;

  String get displayLabel => '$code — $nameFr';

  factory AlgeriaWilaya.fromJson(Map<String, dynamic> json) {
    return AlgeriaWilaya(
      code: json['code']?.toString() ?? '',
      nameFr: json['nameFr']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
    );
  }
}

class AlgeriaCommune {
  const AlgeriaCommune({
    required this.id,
    required this.wilayaCode,
    required this.nameFr,
    required this.nameAr,
    this.aliasesFr = const [],
  });

  final int id;
  final String wilayaCode;
  final String nameFr;
  final String nameAr;
  final List<String> aliasesFr;

  String get displayLabel => nameFr;

  factory AlgeriaCommune.fromJson(Map<String, dynamic> json) {
    final aliasesRaw = json['aliasesFr'];
    return AlgeriaCommune(
      id: (json['id'] as num?)?.toInt() ?? 0,
      wilayaCode: json['wilayaCode']?.toString() ?? '',
      nameFr: json['nameFr']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      aliasesFr: aliasesRaw is List
          ? aliasesRaw.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
