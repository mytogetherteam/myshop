import 'package:my_shop/core/utils/localized_display_name.dart';

class MasterDataModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;

  /// Nested subcategories returned with a shop category. Empty for master
  /// data types that do not have children (cities, cuisine types, etc.).
  final List<MasterDataModel> subCategories;

  MasterDataModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.subCategories = const [],
  });

  factory MasterDataModel.fromJson(Map<String, dynamic> json) {
    final rawSubCategories = json['subCategories'];
    return MasterDataModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      subCategories: rawSubCategories is List
          ? rawSubCategories
              .whereType<Map<String, dynamic>>()
              .map((e) => MasterDataModel.fromJson(e))
              .toList()
          : const [],
    );
  }

  String get displayName =>
      localizedDisplayName(nameEn: nameEn, nameMm: nameMm, nameTh: nameTh);

  // override equality to compare by id for dropdowns
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MasterDataModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
