class MenuCategoryModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final int? displayOrder;
  final bool isActive;
  final String? imageUrl;
  final int itemCount;

  MenuCategoryModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.displayOrder,
    this.isActive = true,
    this.imageUrl,
    this.itemCount = 0,
  });

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'] ?? 'Uncategorized',
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      displayOrder: json['displayOrder'],
      isActive: json['isActive'] ?? true,
      imageUrl: json['imageUrl'] ?? '',
      itemCount: json['itemCount'] ?? 0,
    );
  }

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
}
