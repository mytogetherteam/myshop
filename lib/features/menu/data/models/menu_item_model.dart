class MenuItemModel {
  final int id;
  final int? categoryId;
  final int? masterItemId;
  final int? masterCategoryId;
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
  final List<String> mealTypes;
  final List<String> tags;
  final double? discountAmount;
  final double? discountPercentage;
  final List<MenuItemOptionGroupModel> optionGroups;
  final List<MenuItemVariantModel> variants;
  final bool hasVariants;

  MenuItemModel({
    required this.id,
    this.categoryId,
    this.masterItemId,
    this.masterCategoryId,
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
    this.mealTypes = const [],
    this.tags = const [],
    this.discountAmount,
    this.discountPercentage,
    this.optionGroups = const [],
    this.variants = const [],
    this.hasVariants = false,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] ?? 0,
      categoryId: json['categoryId'],
      masterItemId: json['masterItemId'],
      masterCategoryId: json['masterCategoryId'],
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
      mealTypes: (json['mealTypes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: (json['tagIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'masterItemId': masterItemId,
      'masterCategoryId': masterCategoryId,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'nameTh': nameTh,
      'categoryNameEn': categoryNameEn,
      'categoryNameMm': categoryNameMm,
      'categoryNameTh': categoryNameTh,
      'slug': slug,
      'price': price,
      'originalPrice': originalPrice,
      'currency': currency,
      'displayPrice': displayPrice,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'isVegetarian': isVegetarian,
      'isSpicy': isSpicy,
      'isRecommended': isRecommended,
      'isHotDeal': isHotDeal,
      'isCombo': isCombo,
      'displayOrder': displayOrder,
      'stockQuantity': stockQuantity,
      'description': description,
      'descriptionMm': descriptionMm,
      'descriptionTh': descriptionTh,
      'descriptionEn': descriptionEn,
      'mealTypes': mealTypes,
      'tagIds': tags,
      'discountAmount': discountAmount,
      'discountPercentage': discountPercentage,
      'optionGroups': optionGroups.map((e) => e.toJson()).toList(),
      'variants': variants.map((e) => e.toJson()).toList(),
      'hasVariants': hasVariants,
    };
  }

  MenuItemModel copyWith({
    int? id,
    int? categoryId,
    int? masterItemId,
    int? masterCategoryId,
    String? nameEn,
    String? nameMm,
    String? nameTh,
    String? categoryNameEn,
    String? categoryNameMm,
    String? categoryNameTh,
    String? slug,
    double? price,
    double? originalPrice,
    String? currency,
    String? displayPrice,
    String? imageUrl,
    bool? isAvailable,
    bool? isPopular,
    bool? isVegetarian,
    bool? isSpicy,
    bool? isRecommended,
    bool? isHotDeal,
    bool? isCombo,
    int? displayOrder,
    int? stockQuantity,
    String? description,
    String? descriptionMm,
    String? descriptionTh,
    String? descriptionEn,
    List<String>? mealTypes,
    List<String>? tags,
    double? discountAmount,
    double? discountPercentage,
    List<MenuItemOptionGroupModel>? optionGroups,
    List<MenuItemVariantModel>? variants,
    bool? hasVariants,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      masterItemId: masterItemId ?? this.masterItemId,
      masterCategoryId: masterCategoryId ?? this.masterCategoryId,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      nameTh: nameTh ?? this.nameTh,
      categoryNameEn: categoryNameEn ?? this.categoryNameEn,
      categoryNameMm: categoryNameMm ?? this.categoryNameMm,
      categoryNameTh: categoryNameTh ?? this.categoryNameTh,
      slug: slug ?? this.slug,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      currency: currency ?? this.currency,
      displayPrice: displayPrice ?? this.displayPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isPopular: isPopular ?? this.isPopular,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isSpicy: isSpicy ?? this.isSpicy,
      isRecommended: isRecommended ?? this.isRecommended,
      isHotDeal: isHotDeal ?? this.isHotDeal,
      isCombo: isCombo ?? this.isCombo,
      displayOrder: displayOrder ?? this.displayOrder,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      description: description ?? this.description,
      descriptionMm: descriptionMm ?? this.descriptionMm,
      descriptionTh: descriptionTh ?? this.descriptionTh,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      mealTypes: mealTypes ?? this.mealTypes,
      tags: tags ?? this.tags,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      optionGroups: optionGroups ?? this.optionGroups,
      variants: variants ?? this.variants,
      hasVariants: hasVariants ?? this.hasVariants,
    );
  }

  List<int> get tagIds => tags.map((e) => int.tryParse(e) ?? 0).where((e) => e != 0).toList();

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
  String get displayDescription =>
      descriptionEn ?? descriptionMm ?? descriptionTh ?? description ?? '';
}

class MenuItemVariantModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final double price;
  final String? displayPrice;
  final bool isAvailable;
  final int? displayOrder;

  MenuItemVariantModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    required this.price,
    this.displayPrice,
    this.isAvailable = true,
    this.displayOrder,
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
      displayOrder: json['displayOrder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'nameTh': nameTh,
      'price': price,
      'displayPrice': displayPrice,
      'isAvailable': isAvailable,
      'displayOrder': displayOrder,
    };
  }

  MenuItemVariantModel copyWith({
    int? id,
    String? nameEn,
    String? nameMm,
    String? nameTh,
    double? price,
    String? displayPrice,
    bool? isAvailable,
    int? displayOrder,
  }) {
    return MenuItemVariantModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      nameTh: nameTh ?? this.nameTh,
      price: price ?? this.price,
      displayPrice: displayPrice ?? this.displayPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      displayOrder: displayOrder ?? this.displayOrder,
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
  final int? displayOrder;
  final double price;
  final List<MenuItemOptionModel> options;

  MenuItemOptionGroupModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.isRequired = false,
    this.minSelection,
    this.maxSelection,
    this.displayOrder,
    this.price = 0.0,
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
      displayOrder: json['displayOrder'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      options: (json['options'] as List?)
              ?.map((o) => MenuItemOptionModel.fromJson(o))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'nameTh': nameTh,
      'isRequired': isRequired,
      'minSelection': minSelection,
      'maxSelection': maxSelection,
      'displayOrder': displayOrder,
      'price': price,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }

  MenuItemOptionGroupModel copyWith({
    int? id,
    String? nameEn,
    String? nameMm,
    String? nameTh,
    bool? isRequired,
    int? minSelection,
    int? maxSelection,
    int? displayOrder,
    double? price,
    List<MenuItemOptionModel>? options,
  }) {
    return MenuItemOptionGroupModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      nameTh: nameTh ?? this.nameTh,
      isRequired: isRequired ?? this.isRequired,
      minSelection: minSelection ?? this.minSelection,
      maxSelection: maxSelection ?? this.maxSelection,
      displayOrder: displayOrder ?? this.displayOrder,
      price: price ?? this.price,
      options: options ?? this.options,
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
  final int? displayOrder;
  final int? linkedMenuItemId;

  MenuItemOptionModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    required this.price,
    this.displayPrice,
    this.displayOrder,
    this.linkedMenuItemId,
  });

  factory MenuItemOptionModel.fromJson(Map<String, dynamic> json) {
    return MenuItemOptionModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      displayPrice: json['displayPrice'],
      displayOrder: json['displayOrder'],
      linkedMenuItemId: json['linkedMenuItemId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'nameTh': nameTh,
      'price': price,
      'displayPrice': displayPrice,
      'displayOrder': displayOrder,
      'linkedMenuItemId': linkedMenuItemId,
    };
  }

  MenuItemOptionModel copyWith({
    int? id,
    String? nameEn,
    String? nameMm,
    String? nameTh,
    double? price,
    String? displayPrice,
    int? displayOrder,
    int? linkedMenuItemId,
  }) {
    return MenuItemOptionModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      nameTh: nameTh ?? this.nameTh,
      price: price ?? this.price,
      displayPrice: displayPrice ?? this.displayPrice,
      displayOrder: displayOrder ?? this.displayOrder,
      linkedMenuItemId: linkedMenuItemId ?? this.linkedMenuItemId,
    );
  }

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
}
