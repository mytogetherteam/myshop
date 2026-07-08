import 'menu_item_model.dart';
import 'variant_group_mapper.dart';

/// Builds create/update payloads for menu item variants and option groups,
/// aligned with the admin panel and NestJS soft-delete semantics.
class MenuItemRelationPayload {
  final List<Map<String, dynamic>> variants;
  final List<int> deletedVariantGroupIds;
  final List<Map<String, dynamic>> optionGroups;
  final List<int> deletedOptionGroupIds;

  const MenuItemRelationPayload({
    required this.variants,
    this.deletedVariantGroupIds = const [],
    required this.optionGroups,
    this.deletedOptionGroupIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'variants': variants,
      if (deletedVariantGroupIds.isNotEmpty)
        'deletedVariantGroupIds': deletedVariantGroupIds,
      'optionGroups': optionGroups,
      if (deletedOptionGroupIds.isNotEmpty)
        'deletedOptionGroupIds': deletedOptionGroupIds,
    };
  }
}

class MenuItemPayloadBuilder {
  static MenuItemRelationPayload build({
    required List<MenuItemVariantGroupEditModel> variantGroups,
    required List<MenuItemOptionGroupModel> optionGroups,
    required bool editingExistingItem,
  }) {
    final activeVariantGroups =
        variantGroups.where((group) => !group.isDeleted).toList();

    final activeVariants = <Map<String, dynamic>>[];
    for (var groupIndex = 0; groupIndex < activeVariantGroups.length; groupIndex++) {
      final group = activeVariantGroups[groupIndex];
      final activeVariantsInGroup = group.variants
          .where((variant) => !variant.isDeleted)
          .toList();
      for (var variantIndex = 0;
          variantIndex < activeVariantsInGroup.length;
          variantIndex++) {
        activeVariants.add(
          _variantRow(
            group: group,
            groupIndex: groupIndex,
            variant: activeVariantsInGroup[variantIndex],
            variantIndex: variantIndex,
            editingExistingItem: editingExistingItem,
          ),
        );
      }
    }

    final deletedVariantRows = editingExistingItem
        ? variantGroups
            .where((group) => !group.isDeleted)
            .expand((group) => group.variants)
            .where((variant) => variant.isDeleted && variant.id > 0)
            .map((variant) => {'id': variant.id, 'deleted': true})
            .toList()
        : <Map<String, dynamic>>[];

    final deletedVariantGroupIds = editingExistingItem
        ? variantGroups
            .where((group) => group.isDeleted && group.id > 0)
            .map((group) => group.id)
            .toList()
        : <int>[];

    final activeOptionGroups = optionGroups
        .where((group) => !group.isDeleted)
        .toList();

    final optionGroupRows = activeOptionGroups
        .asMap()
        .entries
        .map(
          (entry) => _optionGroupRow(
            entry.value,
            entry.key,
            editingExistingItem,
          ),
        )
        .toList();

    final deletedOptionGroupIds = editingExistingItem
        ? optionGroups
            .where((group) => group.isDeleted && group.id > 0)
            .map((group) => group.id)
            .toList()
        : <int>[];

    return MenuItemRelationPayload(
      variants: [...activeVariants, ...deletedVariantRows],
      deletedVariantGroupIds: deletedVariantGroupIds,
      optionGroups: optionGroupRows,
      deletedOptionGroupIds: deletedOptionGroupIds,
    );
  }

  static Map<String, dynamic> _variantRow({
    required MenuItemVariantGroupEditModel group,
    required int groupIndex,
    required MenuItemVariantModel variant,
    required int variantIndex,
    required bool editingExistingItem,
  }) {
    final row = <String, dynamic>{
      if (editingExistingItem && variant.id > 0) 'id': variant.id,
      'nameEn': variant.nameEn ?? '',
      'nameMm': variant.nameMm ?? '',
      'nameTh': variant.nameTh ?? '',
      'price': variant.price,
      'isAvailable': variant.isAvailable,
      'displayOrder': variant.displayOrder ?? variantIndex + 1,
      'variantGroupDisplayOrder': group.displayOrder ?? groupIndex + 1,
    };

    if (editingExistingItem && group.id > 0) {
      row['variantGroupId'] = group.id;
    }

    final groupNameEn = group.nameEn?.trim();
    if (groupNameEn != null && groupNameEn.isNotEmpty) {
      row['variantGroupName'] = groupNameEn;
      row['variantGroupNameEn'] = groupNameEn;
      final groupNameMm = group.nameMm?.trim();
      if (groupNameMm != null && groupNameMm.isNotEmpty) {
        row['variantGroupNameMm'] = groupNameMm;
      }
      final groupNameTh = group.nameTh?.trim();
      if (groupNameTh != null && groupNameTh.isNotEmpty) {
        row['variantGroupNameTh'] = groupNameTh;
      }
    }

    return row;
  }

  static Map<String, dynamic> _optionGroupRow(
    MenuItemOptionGroupModel group,
    int groupIndex,
    bool editingExistingItem,
  ) {
    final activeOptions = group.options
        .where((o) => !o.isDeleted)
        .toList()
        .asMap()
        .entries
        .map((entry) => _optionRow(entry.value, entry.key, editingExistingItem))
        .toList();

    final deletedOptions = editingExistingItem
        ? group.options
            .where((o) => o.isDeleted && o.id > 0)
            .map((o) => {'id': o.id, 'deleted': true})
            .toList()
        : <Map<String, dynamic>>[];

    return {
      if (editingExistingItem && group.id > 0) 'id': group.id,
      'nameEn': group.nameEn ?? '',
      'nameMm': group.nameMm ?? '',
      'nameTh': group.nameTh ?? '',
      'displayOrder': group.displayOrder ?? groupIndex + 1,
      'minSelection': 0,
      'maxSelection': 99,
      'isAvailable': group.isAvailable,
      'price': group.price,
      'options': [...activeOptions, ...deletedOptions],
    };
  }

  static Map<String, dynamic> _optionRow(
    MenuItemOptionModel option,
    int optionIndex,
    bool editingExistingItem,
  ) {
    return {
      if (editingExistingItem && option.id > 0) 'id': option.id,
      'nameEn': option.nameEn ?? '',
      'nameMm': option.nameMm ?? '',
      'nameTh': option.nameTh ?? '',
      'price': option.price,
      'isAvailable': option.isAvailable,
      'displayOrder': option.displayOrder ?? optionIndex + 1,
      if (option.linkedMenuItemId != null)
        'linkedMenuItemId': option.linkedMenuItemId,
    };
  }
}
