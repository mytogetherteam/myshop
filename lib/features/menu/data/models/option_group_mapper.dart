import 'menu_item_model.dart';

/// Rebuilds editable option groups from API detail/list payloads.
///
/// When admin/shop soft-deletes or unlinks a group, nested `optionGroups` may be
/// empty while flat `options` still contains the add-ons.
class OptionGroupMapper {
  static List<MenuItemOptionGroupModel> fromMenuItem(MenuItemModel item) {
    return fromPayload(
      nestedGroups: item.optionGroups,
      flatOptions: item.options,
    );
  }

  static List<MenuItemOptionGroupModel> fromPayload({
    required List<MenuItemOptionGroupModel> nestedGroups,
    required List<MenuItemOptionModel> flatOptions,
  }) {
    final groupsById = <int, MenuItemOptionGroupModel>{};
    final groupOrder = <int>[];

    for (final group in nestedGroups.where((g) => !g.isDeleted)) {
      final activeOptions =
          group.options.where((o) => !o.isDeleted).toList();
      if (!group.isAvailable && activeOptions.isEmpty) continue;
      groupsById[group.id] = group.copyWith(options: activeOptions);
      groupOrder.add(group.id);
    }

    final nestedOptionIds = <int>{
      for (final group in groupsById.values)
        for (final option in group.options)
          if (option.id > 0) option.id,
    };

    final ungrouped = <MenuItemOptionModel>[];

    for (final option in flatOptions.where((o) => !o.isDeleted)) {
      if (option.id > 0 && nestedOptionIds.contains(option.id)) continue;

      final groupId = option.optionGroupId;
      final embedded = option.optionGroup;
      final activeGroupId = embedded != null && !embedded.isDeleted
          ? embedded.id
          : groupId;

      if (activeGroupId != null &&
          activeGroupId > 0 &&
          groupsById.containsKey(activeGroupId)) {
        final group = groupsById[activeGroupId]!;
        if (group.options.any((o) => o.id == option.id)) continue;
        groupsById[activeGroupId] = group.copyWith(
          options: [...group.options, option]
            ..sort(
              (a, b) =>
                  (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0),
            ),
        );
        continue;
      }

      ungrouped.add(option);
    }

    if (ungrouped.isNotEmpty) {
      ungrouped.sort(
        (a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0),
      );
      groupsById[0] = MenuItemOptionGroupModel(
        id: 0,
        options: ungrouped,
      );
      groupOrder.add(0);
    }

    return groupOrder.map((id) => groupsById[id]!).toList();
  }

  static List<MenuItemOptionGroupModel> fromJson(Map<String, dynamic> json) {
    final nested = (json['optionGroups'] as List?)
            ?.map(
              (g) => MenuItemOptionGroupModel.fromJson(
                Map<String, dynamic>.from(g as Map),
              ),
            )
            .toList() ??
        const <MenuItemOptionGroupModel>[];

    final flat = (json['options'] as List?)
            ?.map(
              (o) => MenuItemOptionModel.fromJson(
                Map<String, dynamic>.from(o as Map),
              ),
            )
            .toList() ??
        const <MenuItemOptionModel>[];

    return fromPayload(nestedGroups: nested, flatOptions: flat);
  }
}
