class MenuItemModel {
  final int id;
  final int? categoryId;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final String? categoryNameEn;
  final String? categoryNameMm;
  final String? categoryNameTh;
  final String? slug;
  final double price;
  final double? originalPrice;
  final String? currency;
  final String? displayPrice;
  final String? imageUrl;
  final bool isAvailable;
  final bool isPopular;
  final bool isVegetarian;
  final bool isSpicy;
  final bool isRecommended;
  final bool isHotDeal;
  final bool isCombo;
  final int? displayOrder;
  final int? stockQuantity;
  final String? description;
  final String? descriptionMm;
  final String? descriptionTh;
  final String? descriptionEn;
  final List<MenuItemOptionGroupModel> optionGroups;
  final List<MenuItemVariantModel> variants;
  final bool hasVariants;

  MenuItemModel({
    required this.id,
    this.categoryId,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.categoryNameEn,
    this.categoryNameMm,
    this.categoryNameTh,
    this.slug,
    this.price = 0.0,
    this.originalPrice,
    this.currency,
    this.displayPrice,
    this.imageUrl,
    this.isAvailable = true,
    this.isPopular = false,
    this.isVegetarian = false,
    this.isSpicy = false,
    this.isRecommended = false,
    this.isHotDeal = false,
    this.isCombo = false,
    this.displayOrder,
    this.stockQuantity,
    this.description,
    this.descriptionMm,
    this.descriptionTh,
    this.descriptionEn,
    this.optionGroups = const [],
    this.variants = const [],
    this.hasVariants = false,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] ?? 0,
      categoryId: json['categoryId'],
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      categoryNameEn: json['categoryNameEn'],
      categoryNameMm: json['categoryNameMm'],
      categoryNameTh: json['categoryNameTh'],
      slug: json['slug'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      currency: json['currency'],
      displayPrice: json['displayPrice'],
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      isPopular: json['isPopular'] ?? false,
      isVegetarian: json['isVegetarian'] ?? false,
      isSpicy: json['isSpicy'] ?? false,
      isRecommended: json['isRecommended'] ?? false,
      isHotDeal: json['isHotDeal'] ?? false,
      isCombo: json['isCombo'] ?? false,
      displayOrder: json['displayOrder'],
      stockQuantity: json['stockQuantity'],
      description: json['description'],
      descriptionMm: json['descriptionMm'],
      descriptionTh: json['descriptionTh'],
      descriptionEn: json['descriptionEn'],
      optionGroups: (json['optionGroups'] as List?)
              ?.map((o) => MenuItemOptionGroupModel.fromJson(o))
              .toList() ??
          [],
      variants: (json['variants'] as List?)
              ?.map((v) => MenuItemVariantModel.fromJson(v))
              .toList() ??
          [],
      hasVariants: json['hasVariants'] ?? false,
    );
  }

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
  String get displayDescription => descriptionEn ?? descriptionMm ?? descriptionTh ?? description ?? '';
}

class MenuItemVariantModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final double price;
  final String? displayPrice;
  final bool isAvailable;

  MenuItemVariantModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    required this.price,
    this.displayPrice,
    this.isAvailable = true,
  });

  factory MenuItemVariantModel.fromJson(Map<String, dynamic> json) {
    return MenuItemVariantModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      displayPrice: json['displayPrice'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
}

class MenuItemOptionGroupModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final bool isRequired;
  final int? minSelection;
  final int? maxSelection;
  final List<MenuItemOptionModel> options;

  MenuItemOptionGroupModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.isRequired = false,
    this.minSelection,
    this.maxSelection,
    this.options = const [],
  });

  factory MenuItemOptionGroupModel.fromJson(Map<String, dynamic> json) {
    return MenuItemOptionGroupModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      isRequired: json['isRequired'] ?? false,
      minSelection: json['minSelection'],
      maxSelection: json['maxSelection'],
      options: (json['options'] as List?)
              ?.map((o) => MenuItemOptionModel.fromJson(o))
              .toList() ??
          [],
    );
  }

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
}

class MenuItemOptionModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final double price;
  final String? displayPrice;

  MenuItemOptionModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    required this.price,
    this.displayPrice,
  });

  factory MenuItemOptionModel.fromJson(Map<String, dynamic> json) {
    return MenuItemOptionModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      displayPrice: json['displayPrice'],
    );
  }

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
}
