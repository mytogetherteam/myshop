class MenuCategoryModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final int? displayOrder;
  final bool isActive;
  final String? imageUrl;
  final int itemCount;
  final int? masterCategoryId;

  MenuCategoryModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.displayOrder,
    this.isActive = true,
    this.imageUrl,
    this.itemCount = 0,
    this.masterCategoryId,
  });

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      displayOrder: json['displayOrder'],
      isActive: json['isActive'] ?? true,
      imageUrl: json['imageUrl'],
      itemCount: json['itemCount'] ?? 0,
      masterCategoryId: json['masterCategoryId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'nameTh': nameTh,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'masterCategoryId': masterCategoryId,
    };
  }

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
}

