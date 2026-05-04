class MenuItemModel {
  final int id;
  final int? menuCategoryId;
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
  final String? pendingStatus;
  final String? rejectReason;
  final String? description;
  final String? descriptionMm;
  final String? descriptionTh;
  final String? descriptionEn;
  final List<MenuItemOptionGroupModel> optionGroups;
  final List<MenuItemVariantModel> variants;
  final bool hasVariants;
  final int? masterItemId;
  final int? masterCategoryId;
  final String? masterItemNameEn;
  final String? masterItemNameMm;
  final String? masterCategoryNameEn;
  final String? masterCategoryNameMm;
  final String? masterCategoryImageUrl;
  final List<int> tagIds;
  final List<String> mealTypes;
  final double? discountAmount;
  final double? discountPercentage;
  final List<MenuComboComponentModel> components;
  final String? publishStatus;


  MenuItemModel({
    required this.id,
    this.menuCategoryId,
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
    this.pendingStatus,
    this.rejectReason,
    this.description,
    this.descriptionMm,
    this.descriptionTh,
    this.descriptionEn,
    this.optionGroups = const [],
    this.variants = const [],
    this.hasVariants = false,
    this.masterItemId,
    this.masterCategoryId,
    this.masterItemNameEn,
    this.masterItemNameMm,
    this.masterCategoryNameEn,
    this.masterCategoryNameMm,
    this.masterCategoryImageUrl,
    this.tagIds = const [],
    this.mealTypes = const [],
    this.discountAmount,
    this.discountPercentage,
    this.components = const [],
    this.publishStatus,
  });


  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] ?? 0,
      menuCategoryId: json['menuCategoryId'] ?? json['categoryId'],
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
      pendingStatus: json['pendingStatus'] ?? json['pending_status'],
      rejectReason: json['rejectReason'],
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
      masterItemId: json['masterItemId'],
      masterCategoryId: json['masterCategoryId'],
      masterItemNameEn: json['masterItemNameEn'],
      masterItemNameMm: json['masterItemNameMm'],
      masterCategoryNameEn: json['masterCategoryNameEn'],
      masterCategoryNameMm: json['masterCategoryNameMm'],
      masterCategoryImageUrl: json['masterCategoryImageUrl'],
      tagIds: (json['tagIds'] as List?)?.cast<int>() ?? [],
      mealTypes: (json['mealTypes'] as List?)?.cast<String>() ?? [],
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      components: (json['components'] as List?)
              ?.map((c) => MenuComboComponentModel.fromJson(c))
              .toList() ??
          [],
      publishStatus: json['publishStatus'] ?? json['publish_status'],
    );

  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': menuCategoryId,
      'menuCategoryId': menuCategoryId,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'nameTh': nameTh,
      'price': price,
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
      'pendingStatus': pendingStatus,
      'rejectReason': rejectReason,
      'descriptionEn': descriptionEn,
      'descriptionMm': descriptionMm,
      'descriptionTh': descriptionTh,
      'optionGroups': optionGroups.map((o) => o.toJson()).toList(),
      'variants': variants.map((v) => v.toJson()).toList(),
      'masterItemId': masterItemId,
      'masterCategoryId': masterCategoryId,
      'masterItemNameEn': masterItemNameEn,
      'masterItemNameMm': masterItemNameMm,
      'masterCategoryNameEn': masterCategoryNameEn,
      'masterCategoryNameMm': masterCategoryNameMm,
      'masterCategoryImageUrl': masterCategoryImageUrl,
      'tagIds': tagIds,
      'mealTypes': mealTypes,
      'discountAmount': discountAmount,
      'discountPercentage': discountPercentage,
      'components': components.map((c) => c.toJson()).toList(),
      'publishStatus': publishStatus,
    };

  }

  MenuItemModel copyWith({
    int? id,
    int? menuCategoryId,
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
    String? pendingStatus,
    String? rejectReason,
    String? description,
    String? descriptionMm,
    String? descriptionTh,
    String? descriptionEn,
    List<MenuItemOptionGroupModel>? optionGroups,
    List<MenuItemVariantModel>? variants,
    bool? hasVariants,
    int? masterItemId,
    int? masterCategoryId,
    String? masterItemNameEn,
    String? masterItemNameMm,
    String? masterCategoryNameEn,
    String? masterCategoryNameMm,
    String? masterCategoryImageUrl,
    List<int>? tagIds,
    List<String>? mealTypes,
    double? discountAmount,
    double? discountPercentage,
    List<MenuComboComponentModel>? components,
    String? publishStatus,
  }) {

    return MenuItemModel(
      id: id ?? this.id,
      menuCategoryId: menuCategoryId ?? this.menuCategoryId,
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
      pendingStatus: pendingStatus ?? this.pendingStatus,
      rejectReason: rejectReason ?? this.rejectReason,
      description: description ?? this.description,
      descriptionMm: descriptionMm ?? this.descriptionMm,
      descriptionTh: descriptionTh ?? this.descriptionTh,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      optionGroups: optionGroups ?? this.optionGroups,
      variants: variants ?? this.variants,
      hasVariants: hasVariants ?? this.hasVariants,
      masterItemId: masterItemId ?? this.masterItemId,
      masterCategoryId: masterCategoryId ?? this.masterCategoryId,
      masterItemNameEn: masterItemNameEn ?? this.masterItemNameEn,
      masterItemNameMm: masterItemNameMm ?? this.masterItemNameMm,
      masterCategoryNameEn: masterCategoryNameEn ?? this.masterCategoryNameEn,
      masterCategoryNameMm: masterCategoryNameMm ?? this.masterCategoryNameMm,
      masterCategoryImageUrl: masterCategoryImageUrl ?? this.masterCategoryImageUrl,
      tagIds: tagIds ?? this.tagIds,
      mealTypes: mealTypes ?? this.mealTypes,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      components: components ?? this.components,
      publishStatus: publishStatus ?? this.publishStatus,
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

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
}

class MenuItemOptionGroupModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final bool isAvailable;
  final int? minSelection;
  final int? maxSelection;
  final int? displayOrder;
  final String? groupType;
  final double price;
  final List<MenuItemOptionModel> options;

  MenuItemOptionGroupModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.isAvailable = true,
    this.minSelection,
    this.maxSelection,
    this.displayOrder,
    this.groupType,
    this.price = 0.0,
    this.options = const [],
  });

  MenuItemOptionGroupModel copyWith({
    int? id,
    String? nameEn,
    String? nameMm,
    String? nameTh,
    bool? isAvailable,
    int? minSelection,
    int? maxSelection,
    int? displayOrder,
    String? groupType,
    double? price,
    List<MenuItemOptionModel>? options,
  }) {
    return MenuItemOptionGroupModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      nameTh: nameTh ?? this.nameTh,
      isAvailable: isAvailable ?? this.isAvailable,
      minSelection: minSelection ?? this.minSelection,
      maxSelection: maxSelection ?? this.maxSelection,
      displayOrder: displayOrder ?? this.displayOrder,
      groupType: groupType ?? this.groupType,
      price: price ?? this.price,
      options: options ?? this.options,
    );
  }

  factory MenuItemOptionGroupModel.fromJson(Map<String, dynamic> json) {
    return MenuItemOptionGroupModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      isAvailable: json['isAvailable'] ?? json['isRequired'] ?? true,
      minSelection: json['minSelection'],
      maxSelection: json['maxSelection'],
      displayOrder: json['displayOrder'],
      groupType: json['groupType'],
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
      'isAvailable': isAvailable,
      'minSelection': minSelection,
      'maxSelection': maxSelection,
      'displayOrder': displayOrder,
      'groupType': groupType,
      'price': price,
      'options': options.map((o) => o.toJson()).toList(),
    };
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

  String get displayName => nameEn ?? nameMm ?? nameTh ?? '';
}

class MenuComboComponentModel {
  final int? id;
  final int? includedItemId;
  final int quantity;
  final int? displayOrder;
  final String? includedItemNameEn;

  MenuComboComponentModel({
    this.id,
    this.includedItemId,
    this.quantity = 1,
    this.displayOrder,
    this.includedItemNameEn,
  });

  factory MenuComboComponentModel.fromJson(Map<String, dynamic> json) {
    return MenuComboComponentModel(
      id: json['id'],
      includedItemId: json['includedItemId'],
      quantity: json['quantity'] ?? 1,
      displayOrder: json['displayOrder'],
      includedItemNameEn: json['includedItemNameEn'] ?? json['itemNameEn'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'includedItemId': includedItemId,
      'quantity': quantity,
      'displayOrder': displayOrder,
      'includedItemNameEn': includedItemNameEn,
    };
  }
}
