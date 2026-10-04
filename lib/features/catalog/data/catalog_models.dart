import 'package:speedygo_merchant_app/core/money/money_format.dart';

class CatalogStats {
  const CatalogStats({
    required this.categoryCount,
    required this.productCount,
    required this.availableProductCount,
  });

  final int categoryCount;
  final int productCount;
  final int availableProductCount;

  factory CatalogStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CatalogStats(
        categoryCount: 0,
        productCount: 0,
        availableProductCount: 0,
      );
    }
    return CatalogStats(
      categoryCount: (json['categoryCount'] as num?)?.toInt() ?? 0,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      availableProductCount:
          (json['availableProductCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.branchId,
    required this.name,
    required this.sortOrder,
    required this.active,
  });

  final String id;
  final String branchId;
  final String name;
  final int sortOrder;
  final bool active;

  CatalogCategory copyWith({String? name, bool? active, int? sortOrder}) =>
      CatalogCategory(
        id: id,
        branchId: branchId,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        active: active ?? this.active,
      );

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: json['id']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      active: json['active'] == true,
    );
  }
}

/// Allowlisted selling units (`sellingUnitCode`). Quantities are integers, so
/// weight units (kg, 500 g, 250 g) are intentionally absent.
enum SellingUnit {
  plat('PLAT', 'Plat'),
  piece('PIECE', 'Pièce'),
  portion('PORTION', 'Portion'),
  boite('BOITE', 'Boîte'),
  pack('PACK', 'Pack'),
  plateau('PLATEAU', 'Plateau'),
  custom('CUSTOM', 'Unité personnalisée');

  const SellingUnit(this.code, this.labelFr);

  final String code;
  final String labelFr;

  static SellingUnit? fromCode(String? code) {
    for (final unit in values) {
      if (unit.code == code) return unit;
    }
    return null;
  }
}

/// Unit label shown to customers: the server `sellingUnitLabelFr` wins, then
/// the allowlist label. `null` when the product has no unit.
String? sellingUnitDisplayLabel(String? code, String? labelFr) {
  if (code == null || code.isEmpty) return null;
  final custom = labelFr?.trim();
  if (custom != null && custom.isNotEmpty) return custom;
  final unit = SellingUnit.fromCode(code);
  if (unit == null || unit == SellingUnit.custom) return null;
  return unit.labelFr;
}

/// A product's selling unit as sent to the API. [none] clears the unit.
class SellingUnitSelection {
  const SellingUnitSelection({this.code, this.labelFr});

  static const none = SellingUnitSelection();

  final String? code;
  final String? labelFr;

  bool get isNone => code == null;

  String? get displayLabel => sellingUnitDisplayLabel(code, labelFr);

  @override
  bool operator ==(Object other) =>
      other is SellingUnitSelection &&
      other.code == code &&
      other.labelFr == labelFr;

  @override
  int get hashCode => Object.hash(code, labelFr);
}

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.branchId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.priceMinor,
    required this.available,
    this.hasImage = false,
    this.updatedAt,
    this.sellingUnitCode,
    this.sellingUnitLabelFr,
  });

  final String id;
  final String branchId;
  final String categoryId;
  final String name;
  final String? description;
  final String priceMinor;
  final bool available;
  final bool hasImage;
  final DateTime? updatedAt;
  final String? sellingUnitCode;
  final String? sellingUnitLabelFr;

  SellingUnitSelection get sellingUnit =>
      SellingUnitSelection(code: sellingUnitCode, labelFr: sellingUnitLabelFr);

  /// Unit suffix for lists and details; `null` when no unit is set.
  String? get sellingUnitLabel =>
      sellingUnitDisplayLabel(sellingUnitCode, sellingUnitLabelFr);

  /// `1 500 DZD / Plat`, or the bare price when the product has no unit.
  String get priceWithUnitLabel {
    final price = MoneyFormat.dzdOrEmpty(priceMinor);
    final unit = sellingUnitLabel;
    if (price.isEmpty || unit == null) return price;
    return '$price / $unit';
  }

  CatalogProduct copyWith({
    bool? available,
    String? name,
    String? description,
    String? categoryId,
    String? priceMinor,
    bool? hasImage,
  }) {
    return CatalogProduct(
      id: id,
      branchId: branchId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      priceMinor: priceMinor ?? this.priceMinor,
      available: available ?? this.available,
      hasImage: hasImage ?? this.hasImage,
      updatedAt: updatedAt,
      sellingUnitCode: sellingUnitCode,
      sellingUnitLabelFr: sellingUnitLabelFr,
    );
  }

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final nested = json['product'];
    final src = nested is Map ? Map<String, dynamic>.from(nested) : json;
    return CatalogProduct(
      id: src['id']?.toString() ?? '',
      branchId: src['branchId']?.toString() ?? '',
      categoryId: src['categoryId']?.toString() ?? '',
      name: src['name']?.toString() ?? '',
      description: src['description']?.toString(),
      priceMinor: src['priceMinor']?.toString() ?? '0',
      available: src['available'] == true,
      hasImage: src['hasImage'] == true,
      updatedAt: DateTime.tryParse(src['updatedAt']?.toString() ?? ''),
      sellingUnitCode: _nonEmpty(src['sellingUnitCode']),
      sellingUnitLabelFr: _nonEmpty(src['sellingUnitLabelFr']),
    );
  }
}

String? _nonEmpty(Object? raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

/// One selectable choice of a [CatalogOptionGroup]. The price delta is
/// integer minor units (never negative on the server).
class CatalogOption {
  const CatalogOption({
    required this.id,
    required this.name,
    required this.additionalPriceMinor,
    required this.available,
  });

  final String id;
  final String name;
  final String additionalPriceMinor;
  final bool available;

  factory CatalogOption.fromJson(Map<String, dynamic> json) {
    return CatalogOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      additionalPriceMinor: json['additionalPriceMinor']?.toString() ?? '0',
      available: json['available'] == true,
    );
  }
}

/// Product option group. `required` groups are the "variantes obligatoires"
/// (minSelections ≥ 1); optional groups are the "suppléments" (min 0).
class CatalogOptionGroup {
  const CatalogOptionGroup({
    required this.id,
    required this.name,
    required this.required,
    required this.minSelections,
    required this.maxSelections,
    required this.options,
  });

  final String id;
  final String name;
  final bool required;
  final int minSelections;
  final int maxSelections;
  final List<CatalogOption> options;

  factory CatalogOptionGroup.fromJson(Map<String, dynamic> json) {
    final raw = json['options'];
    return CatalogOptionGroup(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      required: json['required'] == true,
      minSelections: (json['minSelections'] as num?)?.toInt() ?? 0,
      maxSelections: (json['maxSelections'] as num?)?.toInt() ?? 1,
      options: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => CatalogOption.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

class CatalogBootstrap {
  const CatalogBootstrap({
    required this.branchId,
    required this.stats,
    required this.categories,
  });

  final String branchId;
  final CatalogStats stats;
  final List<CatalogCategory> categories;

  factory CatalogBootstrap.fromJson(Map<String, dynamic> json) {
    final cats = json['categories'];
    return CatalogBootstrap(
      branchId: json['branchId']?.toString() ?? '',
      stats: CatalogStats.fromJson(
        json['stats'] is Map
            ? Map<String, dynamic>.from(json['stats'] as Map)
            : null,
      ),
      categories: cats is List
          ? cats
                .whereType<Map>()
                .map(
                  (e) => CatalogCategory.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

/// Server result of `POST …/products/:id/duplicate` (one transaction).
class ProductDuplicateResult {
  const ProductDuplicateResult({
    required this.product,
    required this.replayed,
    required this.optionGroupCount,
    required this.optionCount,
    required this.imageCopied,
  });

  /// The created copy (starts unavailable).
  final CatalogProduct product;

  /// True when the same requestId was already applied; nothing new was created.
  final bool replayed;
  final int optionGroupCount;
  final int optionCount;
  final bool imageCopied;

  factory ProductDuplicateResult.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final copied = json['copied'];
    final c = copied is Map ? Map<String, dynamic>.from(copied) : const {};
    return ProductDuplicateResult(
      product: CatalogProduct.fromJson(
        product is Map ? Map<String, dynamic>.from(product) : const {},
      ),
      replayed: json['replayed'] == true,
      optionGroupCount: (c['optionGroupCount'] as num?)?.toInt() ?? 0,
      optionCount: (c['optionCount'] as num?)?.toInt() ?? 0,
      imageCopied: c['imageCopied'] == true,
    );
  }
}
