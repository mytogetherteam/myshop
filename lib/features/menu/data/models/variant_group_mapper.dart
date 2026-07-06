import 'menu_item_model.dart';
import 'package:my_shop/core/utils/localized_display_name.dart';

/// Editable variant group used on the add/edit item screen.
class MenuItemVariantGroupEditModel {
  final int id;
  final String? nameEn;
  final String? nameMm;
  final String? nameTh;
  final int? displayOrder;
  final bool isDeleted;
  final List<MenuItemVariantModel> variants;

  const MenuItemVariantGroupEditModel({
    this.id = 0,
    this.nameEn,
    this.nameMm,
    this.nameTh,
    this.displayOrder,
    this.isDeleted = false,
    this.variants = const [],
  });

  MenuItemVariantGroupEditModel copyWith({
    int? id,
    String? nameEn,
    String? nameMm,
    String? nameTh,
    int? displayOrder,
    bool? isDeleted,
    List<MenuItemVariantModel>? variants,
  }) {
    return MenuItemVariantGroupEditModel(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameMm: nameMm ?? this.nameMm,
      nameTh: nameTh ?? this.nameTh,
      displayOrder: displayOrder ?? this.displayOrder,
      isDeleted: isDeleted ?? this.isDeleted,
      variants: variants ?? this.variants,
    );
  }

  bool get hasGroupName =>
      (nameEn?.trim().isNotEmpty ?? false) ||
      (nameMm?.trim().isNotEmpty ?? false) ||
      (nameTh?.trim().isNotEmpty ?? false);

  String get displayName =>
      localizedDisplayName(nameEn: nameEn, nameMm: nameMm, nameTh: nameTh);
}

class VariantGroupMapper {
  static List<MenuItemVariantGroupEditModel> fromMenuItem(MenuItemModel item) {
    return fromVariants(
      item.variants,
      item.variantGroups,
    );
  }

  static List<MenuItemVariantGroupEditModel> fromVariants(
    List<MenuItemVariantModel> variants,
    List<MenuItemVariantGroupModel> apiGroups,
  ) {
    final groupsById = <int, MenuItemVariantGroupEditModel>{};

    for (final apiGroup in apiGroups) {
      if (apiGroup.id <= 0) continue;
      groupsById[apiGroup.id] = MenuItemVariantGroupEditModel(
        id: apiGroup.id,
        nameEn: apiGroup.nameEn,
        nameMm: apiGroup.nameMm,
        nameTh: apiGroup.nameTh,
        displayOrder: apiGroup.displayOrder,
        variants: [],
      );
    }

    final ungrouped = <MenuItemVariantModel>[];

    for (final variant in variants.where((v) => !v.isDeleted)) {
      final groupId = variant.variantGroupId ?? variant.variantGroup?.id;
      final embeddedGroup = variant.variantGroup;

      if (groupId != null) {
        groupsById.putIfAbsent(
          groupId,
          () => MenuItemVariantGroupEditModel(
            id: groupId,
            nameEn: variant.variantGroupNameEn ?? embeddedGroup?.nameEn,
            nameMm: variant.variantGroupNameMm ?? embeddedGroup?.nameMm,
            nameTh: variant.variantGroupNameTh ?? embeddedGroup?.nameTh,
            displayOrder:
                variant.variantGroupDisplayOrder ?? embeddedGroup?.displayOrder,
            variants: [],
          ),
        );
        final group = groupsById[groupId]!;
        groupsById[groupId] = group.copyWith(
          variants: [...group.variants, variant],
        );
        continue;
      }

      ungrouped.add(variant);
    }

    final grouped = groupsById.values
        .where((g) => g.variants.isNotEmpty || g.hasGroupName)
        .map(
          (g) => g.copyWith(
            variants: List<MenuItemVariantModel>.from(g.variants)
              ..sort(
                (a, b) =>
                    (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0),
              ),
          ),
        )
        .toList()
      ..sort(
        (a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0),
      );

    if (ungrouped.isNotEmpty) {
      grouped.add(
        MenuItemVariantGroupEditModel(
          displayOrder: grouped.length + 1,
          variants: ungrouped
            ..sort(
              (a, b) =>
                  (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0),
            ),
        ),
      );
    }

    return grouped;
  }
}
