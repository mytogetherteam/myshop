import 'package:my_shop/core/utils/localized_display_name.dart';

import 'menu_item_client_key.dart';
import 'option_group_mapper.dart';

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
  final List<MenuItemOptionModel> options;
  final List<MenuItemVariantModel> variants;
  final List<MenuItemVariantGroupModel> variantGroups;
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
    this.options = const [],
    this.variants = const [],
    this.variantGroups = const [],
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
      optionGroups: OptionGroupMapper.fromJson(json),
      options: (json['options'] as List?)
              ?.map(
                (o) => MenuItemOptionModel.fromJson(
                  Map<String, dynamic>.from(o as Map),
                ),
              )
              .toList() ??
          [],
      variantGroups: (json['variantGroups'] as List?)
              ?.map((g) => MenuItemVariantGroupModel.fromJson(g))
              .toList() ??
          [],
      variants: _variantsFromJson(json),
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
      components: ((json['components'] as List?) ??
              (json['comboComponents'] as List?))
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
      'variantGroups': variantGroups.map((g) => g.toJson()).toList(),
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
    List<MenuItemOptionModel>? options,
    List<MenuItemVariantModel>? variants,
    List<MenuItemVariantGroupModel>? variantGroups,
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
      options: options ?? this.options,
      variants: variants ?? this.variants,
      variantGroups: variantGroups ?? this.variantGroups,
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

  String get displayName =>
      localizedDisplayName(nameEn: nameEn, nameMm: nameMm, nameTh: nameTh);
  String get displayDescription => localizedDisplayName(
        nameEn: descriptionEn ?? description,
        nameMm: descriptionMm,
        nameTh: descriptionTh,
      );
}

List<MenuItemVariantModel> _variantsFromJson(Map<String, dynamic> json) {
  final apiGroups = (json['variantGroups'] as List?)
          ?.map((g) => MenuItemVariantGroupModel.fromJson(g))
          .toList() ??
      const <MenuItemVariantGroupModel>[];

  final variants = (json['variants'] as List?)
          ?.map((v) => MenuItemVariantModel.fromJson(v))
          .toList() ??
      const <MenuItemVariantModel>[];

  if (variants.isEmpty) return variants;

  final groupMetaById = {
    for (final group in apiGroups)
      if (group.id > 0) group.id: group,
  };

  final enriched = variants
      .where((variant) => variant.isAvailable)
      .map((variant) {
    final embeddedGroup = variant.variantGroup;
    final groupId = variant.variantGroupId ?? embeddedGroup?.id;
    final group = groupId != null ? groupMetaById[groupId] ?? embeddedGroup : embeddedGroup;
    if (group == null) return variant;
    return variant.copyWith(
      variantGroupId: groupId,
      variantGroupNameEn: variant.variantGroupNameEn ?? group.nameEn,
      variantGroupNameMm: variant.variantGroupNameMm ?? group.nameMm,
      variantGroupNameTh: variant.variantGroupNameTh ?? group.nameTh,
      variantGroupDisplayOrder:
          variant.variantGroupDisplayOrder ?? group.displayOrder,
      variantGroup: group,
    );
  }).toList();

  enriched.sort((a, b) {
    final groupOrder = (a.variantGroupDisplayOrder ?? 0)
        .compareTo(b.variantGroupDisplayOrder ?? 0);
    if (groupOrder != 0) return groupOrder;
    return (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0);
  });

  return enriched;
}

class MenuItemVariantGroupModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final int? displayOrder;

  MenuItemVariantGroupModel({
    required this.id,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.displayOrder,
  });

  factory MenuItemVariantGroupModel.fromJson(Map<String, dynamic> json) {
    return MenuItemVariantGroupModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      displayOrder: json['displayOrder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'nameTh': nameTh,
      'displayOrder': displayOrder,
    };
  }

  String get displayName =>
      localizedDisplayName(nameEn: nameEn, nameMm: nameMm, nameTh: nameTh);
}

class MenuItemVariantModel {
  final int id;
  final String clientKey;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final double price;
  final String? displayPrice;
  final bool isAvailable;
  final int? displayOrder;
  final int? variantGroupId;
  final String? variantGroupNameEn;
  final String? variantGroupNameMm;
  final String? variantGroupNameTh;
  final int? variantGroupDisplayOrder;
  final MenuItemVariantGroupModel? variantGroup;
  final bool isDeleted;

  MenuItemVariantModel({
    required this.id,
    String? clientKey,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    required this.price,
    this.displayPrice,
    this.isAvailable = true,
    this.displayOrder,
    this.variantGroupId,
    this.variantGroupNameEn,
    this.variantGroupNameMm,
    this.variantGroupNameTh,
    this.variantGroupDisplayOrder,
    this.variantGroup,
    this.isDeleted = false,
  }) : clientKey = clientKey ??
            (id > 0
                ? MenuItemClientKey.forId('v', id)
                : MenuItemClientKey.next('v'));

  MenuItemVariantModel copyWith({
    int? id,
    String? clientKey,
    String? nameEn,
    String? nameMm,
    String? nameTh,
    double? price,
    String? displayPrice,
    bool? isAvailable,
    int? displayOrder,
    int? variantGroupId,
    String? variantGroupNameEn,
    String? variantGroupNameMm,
    String? variantGroupNameTh,
    int? variantGroupDisplayOrder,
    MenuItemVariantGroupModel? variantGroup,
    bool? isDeleted,
  }) {
    return MenuItemVariantModel(
      id: id ?? this.id,
      clientKey: clientKey ?? this.clientKey,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      nameTh: nameTh ?? this.nameTh,
      price: price ?? this.price,
      displayPrice: displayPrice ?? this.displayPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      displayOrder: displayOrder ?? this.displayOrder,
      variantGroupId: variantGroupId ?? this.variantGroupId,
      variantGroupNameEn: variantGroupNameEn ?? this.variantGroupNameEn,
      variantGroupNameMm: variantGroupNameMm ?? this.variantGroupNameMm,
      variantGroupNameTh: variantGroupNameTh ?? this.variantGroupNameTh,
      variantGroupDisplayOrder:
          variantGroupDisplayOrder ?? this.variantGroupDisplayOrder,
      variantGroup: variantGroup ?? this.variantGroup,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory MenuItemVariantModel.fromJson(Map<String, dynamic> json) {
    final embeddedGroup = json['variantGroup'] is Map
        ? MenuItemVariantGroupModel.fromJson(
            Map<String, dynamic>.from(json['variantGroup'] as Map),
          )
        : null;

    return MenuItemVariantModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      displayPrice: json['displayPrice'],
      isAvailable: json['isAvailable'] ?? true,
      displayOrder: json['displayOrder'],
      variantGroupId: json['variantGroupId'],
      variantGroupNameEn:
          json['variantGroupNameEn'] ?? embeddedGroup?.nameEn,
      variantGroupNameMm:
          json['variantGroupNameMm'] ?? embeddedGroup?.nameMm,
      variantGroupNameTh:
          json['variantGroupNameTh'] ?? embeddedGroup?.nameTh,
      variantGroupDisplayOrder: json['variantGroupDisplayOrder'] ??
          embeddedGroup?.displayOrder,
      variantGroup: embeddedGroup,
      isDeleted: json['deleted'] == true ||
          json['isDeleted'] == true ||
          json['deletedAt'] != null,
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
      if (variantGroupId != null) 'variantGroupId': variantGroupId,
      if (variantGroupNameEn != null) 'variantGroupNameEn': variantGroupNameEn,
      if (variantGroupNameMm != null) 'variantGroupNameMm': variantGroupNameMm,
      if (variantGroupNameTh != null) 'variantGroupNameTh': variantGroupNameTh,
      if (variantGroupDisplayOrder != null)
        'variantGroupDisplayOrder': variantGroupDisplayOrder,
      if (variantGroup != null) 'variantGroup': variantGroup!.toJson(),
      if (isDeleted) 'deleted': true,
    };
  }

  String get displayName =>
      localizedDisplayName(nameEn: nameEn, nameMm: nameMm, nameTh: nameTh);
}

class MenuItemOptionGroupModel {
  final int id;
  final String clientKey;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final bool isAvailable;
  final int? displayOrder;
  final double price;
  final List<MenuItemOptionModel> options;
  final bool isDeleted;

  MenuItemOptionGroupModel({
    required this.id,
    String? clientKey,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.isAvailable = true,
    this.displayOrder,
    this.price = 0.0,
    this.options = const [],
    this.isDeleted = false,
  }) : clientKey = clientKey ??
            (id > 0
                ? MenuItemClientKey.forId('og', id)
                : MenuItemClientKey.next('og'));

  MenuItemOptionGroupModel copyWith({
    int? id,
    String? clientKey,
    String? nameEn,
    String? nameMm,
    String? nameTh,
    bool? isAvailable,
    int? displayOrder,
    double? price,
    List<MenuItemOptionModel>? options,
    bool? isDeleted,
  }) {
    return MenuItemOptionGroupModel(
      id: id ?? this.id,
      clientKey: clientKey ?? this.clientKey,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      nameTh: nameTh ?? this.nameTh,
      isAvailable: isAvailable ?? this.isAvailable,
      displayOrder: displayOrder ?? this.displayOrder,
      price: price ?? this.price,
      options: options ?? this.options,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory MenuItemOptionGroupModel.fromJson(Map<String, dynamic> json) {
    return MenuItemOptionGroupModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      isAvailable: json['isAvailable'] ?? json['isRequired'] ?? true,
      displayOrder: json['displayOrder'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      options: (json['options'] as List?)
              ?.map((o) => MenuItemOptionModel.fromJson(o))
              .toList()
              .where((o) => !o.isDeleted)
              .toList() ??
          [],
      isDeleted: json['deleted'] == true ||
          json['isDeleted'] == true ||
          json['deletedAt'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameMm': nameMm,
      'nameTh': nameTh,
      'isAvailable': isAvailable,
      'displayOrder': displayOrder,
      'price': price,
      'options': options.map((o) => o.toJson()).toList(),
      if (isDeleted) 'deleted': true,
    };
  }

  String get displayName =>
      localizedDisplayName(nameEn: nameEn, nameMm: nameMm, nameTh: nameTh);
}

class MenuItemOptionModel {
  final int id;
  final String clientKey;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final double price;
  final String? displayPrice;
  final bool isAvailable;
  final int? displayOrder;
  final int? linkedMenuItemId;
  final int? optionGroupId;
  final MenuItemOptionGroupModel? optionGroup;
  final bool isDeleted;

  MenuItemOptionModel({
    required this.id,
    String? clientKey,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    required this.price,
    this.displayPrice,
    this.isAvailable = true,
    this.displayOrder,
    this.linkedMenuItemId,
    this.optionGroupId,
    this.optionGroup,
    this.isDeleted = false,
  }) : clientKey = clientKey ??
            (id > 0
                ? MenuItemClientKey.forId('o', id)
                : MenuItemClientKey.next('o'));

  MenuItemOptionModel copyWith({
    int? id,
    String? clientKey,
    String? nameEn,
    String? nameMm,
    String? nameTh,
    double? price,
    String? displayPrice,
    bool? isAvailable,
    int? displayOrder,
    int? linkedMenuItemId,
    int? optionGroupId,
    MenuItemOptionGroupModel? optionGroup,
    bool? isDeleted,
  }) {
    return MenuItemOptionModel(
      id: id ?? this.id,
      clientKey: clientKey ?? this.clientKey,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      nameTh: nameTh ?? this.nameTh,
      price: price ?? this.price,
      displayPrice: displayPrice ?? this.displayPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      displayOrder: displayOrder ?? this.displayOrder,
      linkedMenuItemId: linkedMenuItemId ?? this.linkedMenuItemId,
      optionGroupId: optionGroupId ?? this.optionGroupId,
      optionGroup: optionGroup ?? this.optionGroup,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory MenuItemOptionModel.fromJson(Map<String, dynamic> json) {
    final embeddedGroupRaw = json['optionGroup'] ?? json['group'];
    final embeddedGroup = embeddedGroupRaw is Map
        ? MenuItemOptionGroupModel.fromJson(
            Map<String, dynamic>.from(embeddedGroupRaw),
          )
        : null;

    return MenuItemOptionModel(
      id: json['id'] ?? 0,
      nameEn: json['nameEn'],
      nameMm: json['nameMm'],
      nameTh: json['nameTh'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      displayPrice: json['displayPrice'],
      isAvailable: json['isAvailable'] ?? true,
      displayOrder: json['displayOrder'],
      linkedMenuItemId: json['linkedMenuItemId'],
      optionGroupId: json['optionGroupId'] ?? embeddedGroup?.id,
      optionGroup: embeddedGroup,
      isDeleted: json['deleted'] == true ||
          json['isDeleted'] == true ||
          json['deletedAt'] != null,
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
      'linkedMenuItemId': linkedMenuItemId,
      if (optionGroupId != null) 'optionGroupId': optionGroupId,
      if (optionGroup != null) 'optionGroup': optionGroup!.toJson(),
      if (isDeleted) 'deleted': true,
    };
  }

  String get displayName =>
      localizedDisplayName(nameEn: nameEn, nameMm: nameMm, nameTh: nameTh);
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
