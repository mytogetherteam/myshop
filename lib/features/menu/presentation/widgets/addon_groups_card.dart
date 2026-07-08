import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_switch.dart';
import 'package:my_shop/features/menu/data/models/menu_item_model.dart';
import 'menu_item_inline_field.dart';

class AddonGroupsCard extends StatelessWidget {
  final List<MenuItemOptionGroupModel> optionGroups;
  final ValueChanged<List<MenuItemOptionGroupModel>> onChange;
  final bool isEditMode;

  const AddonGroupsCard({
    super.key,
    required this.optionGroups,
    required this.onChange,
    this.isEditMode = false,
  });

  List<MenuItemOptionGroupModel> get _visibleGroups =>
      optionGroups.where((group) => !group.isDeleted).toList();

  void _updateGroups(List<MenuItemOptionGroupModel> next) {
    onChange(next);
  }

  void _addGroup(BuildContext context) {
    HapticFeedback.lightImpact();
    _updateGroups([
      ...optionGroups,
      MenuItemOptionGroupModel(
        id: 0,
        nameEn: '',
        isAvailable: true,
        displayOrder: _visibleGroups.length + 1,
        options: [
          MenuItemOptionModel(
            id: 0,
            nameEn: '',
            price: 0.0,
            isAvailable: true,
            displayOrder: 1,
          ),
        ],
      ),
    ]);
  }

  void _softDeleteGroup(BuildContext context, int groupIndex) {
    HapticFeedback.lightImpact();
    final group = optionGroups[groupIndex];
    if (isEditMode && group.id > 0) {
      final next = [...optionGroups];
      next[groupIndex] = group.copyWith(
        isDeleted: true,
        options: group.options
            .map(
              (option) =>
                  option.id > 0 ? option.copyWith(isDeleted: true) : option,
            )
            .toList(),
      );
      _updateGroups(next);
      final t = AppLocalizations.of(context);
      AppDialog.showToast(
        context,
        t?.translate('addon_group_removed_toast') ??
            'Add-on group removed. Save the item to apply.',
      );
      return;
    }

    final next = optionGroups
        .asMap()
        .entries
        .where((entry) => entry.key != groupIndex)
        .map((entry) => entry.value)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(displayOrder: entry.key + 1),
        )
        .toList();
    _updateGroups(next);
  }

  void _updateGroup(int groupIndex, MenuItemOptionGroupModel group) {
    final next = [...optionGroups];
    next[groupIndex] = group;
    _updateGroups(next);
  }

  void _addOption(int groupIndex) {
    HapticFeedback.lightImpact();
    final group = optionGroups[groupIndex];
    final visibleCount = group.options.where((o) => !o.isDeleted).length;
    _updateGroup(
      groupIndex,
      group.copyWith(
        options: [
          ...group.options,
          MenuItemOptionModel(
            id: 0,
            nameEn: '',
            price: 0.0,
            isAvailable: true,
            displayOrder: visibleCount + 1,
          ),
        ],
      ),
    );
  }

  void _softDeleteOption(
    BuildContext context,
    int groupIndex,
    int optionIndex,
  ) {
    HapticFeedback.lightImpact();
    final group = optionGroups[groupIndex];
    final option = group.options[optionIndex];
    final nextOptions = List<MenuItemOptionModel>.from(group.options);

    if (isEditMode && option.id > 0) {
      nextOptions[optionIndex] = option.copyWith(isDeleted: true);
      _updateGroup(groupIndex, group.copyWith(options: nextOptions));
      final t = AppLocalizations.of(context);
      AppDialog.showToast(
        context,
        t?.translate('addon_removed_toast') ??
            'Add-on removed. Save the item to apply.',
      );
      return;
    }

    nextOptions.removeAt(optionIndex);
    _updateGroup(
      groupIndex,
      group.copyWith(
        options: nextOptions
            .asMap()
            .entries
            .map(
              (entry) => entry.value.copyWith(displayOrder: entry.key + 1),
            )
            .toList(),
      ),
    );
  }

  void _onReorderGroup(int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    if (newIndex > oldIndex) newIndex--;

    final visible = List<MenuItemOptionGroupModel>.from(_visibleGroups);
    final moved = visible.removeAt(oldIndex);
    visible.insert(newIndex, moved);

    final next = <MenuItemOptionGroupModel>[];
    var visibleIndex = 0;
    for (final group in optionGroups) {
      if (group.isDeleted) {
        next.add(group);
        continue;
      }
      next.add(visible[visibleIndex].copyWith(displayOrder: visibleIndex + 1));
      visibleIndex++;
    }
    _updateGroups(next);
  }

  void _onReorderOption(int groupIndex, int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    if (newIndex > oldIndex) newIndex--;

    final group = optionGroups[groupIndex];
    final visible = group.options.where((o) => !o.isDeleted).toList();
    final deleted = group.options.where((o) => o.isDeleted).toList();
    final moved = visible.removeAt(oldIndex);
    visible.insert(newIndex, moved);

    final reordered = visible
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(displayOrder: entry.key + 1))
        .toList();

    _updateGroup(groupIndex, group.copyWith(options: [...reordered, ...deleted]));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final visibleGroups = _visibleGroups;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t?.translate('addons') ?? 'Add-ons',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t?.translate('addons_description') ??
                            'Group extras such as Toppings or Sauces, then add choices inside each group.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addGroup(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    t?.translate('add_group') ?? 'Add Group',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: visibleGroups.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      t?.translate('no_addon_groups') ??
                          'No add-on groups added.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: visibleGroups.length,
                    onReorder: _onReorderGroup,
                    itemBuilder: (context, visibleIndex) {
                      final group = visibleGroups[visibleIndex];
                      final groupIndex = optionGroups.indexWhere(
                        (g) => g.clientKey == group.clientKey,
                      );
                      final options = group.options
                          .where((option) => !option.isDeleted)
                          .toList();

                      return Padding(
                        key: ValueKey(group.clientKey),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MenuItemSortableRow(
                                index: visibleIndex,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: MenuItemInlineField(
                                        hint: t?.translate('group_name_en') ??
                                            'Group Name (EN) e.g. Toppings',
                                        value: group.nameEn ?? '',
                                        onChanged: (v) => _updateGroup(
                                          groupIndex,
                                          group.copyWith(nameEn: v),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: MenuItemInlineField(
                                        hint: t?.translate('group_name_mm') ??
                                            'Group Name (MM)',
                                        value: group.nameMm ?? '',
                                        onChanged: (v) => _updateGroup(
                                          groupIndex,
                                          group.copyWith(nameMm: v),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const SizedBox(width: 30),
                                  Expanded(
                                    child: MenuItemInlineField(
                                      hint: t?.translate('group_name_th') ??
                                          'Group Name (TH)',
                                      value: group.nameTh ?? '',
                                      onChanged: (v) => _updateGroup(
                                        groupIndex,
                                        group.copyWith(nameTh: v),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _softDeleteGroup(context, groupIndex),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    t?.translate('addons_in_group') ??
                                        'Add-ons in this group',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _addOption(groupIndex),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text(
                                      t?.translate('add_addon_option') ??
                                          'Add add-on',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              if (options.isEmpty)
                                Text(
                                  t?.translate('no_addons_in_group') ??
                                      'No add-ons in this group yet.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                )
                              else
                                ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  buildDefaultDragHandles: false,
                                  itemCount: options.length,
                                  onReorder: (oldIndex, newIndex) =>
                                      _onReorderOption(
                                    groupIndex,
                                    oldIndex,
                                    newIndex,
                                  ),
                                  itemBuilder: (context, optionVisibleIndex) {
                                    final option = options[optionVisibleIndex];
                                    final optionIndex = group.options.indexWhere(
                                      (o) => o.clientKey == option.clientKey,
                                    );

                                    return Padding(
                                      key: ValueKey(option.clientKey),
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: MenuItemSortableRow(
                                        index: optionVisibleIndex,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .dividerColor,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: MenuItemInlineField(
                                                      label: t?.translate(
                                                              'name_english') ??
                                                          'Name (English)',
                                                      value:
                                                          option.nameEn ?? '',
                                                      onChanged: (v) {
                                                        final nextOptions = List<
                                                            MenuItemOptionModel>.from(
                                                          group.options,
                                                        );
                                                        nextOptions[
                                                                optionIndex] =
                                                            option.copyWith(
                                                          nameEn: v,
                                                        );
                                                        _updateGroup(
                                                          groupIndex,
                                                          group.copyWith(
                                                            options: nextOptions,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: MenuItemInlineField(
                                                      label: t?.translate(
                                                              'name_myanmar') ??
                                                          'Name (Myanmar)',
                                                      value:
                                                          option.nameMm ?? '',
                                                      onChanged: (v) {
                                                        final nextOptions = List<
                                                            MenuItemOptionModel>.from(
                                                          group.options,
                                                        );
                                                        nextOptions[
                                                                optionIndex] =
                                                            option.copyWith(
                                                          nameMm: v,
                                                        );
                                                        _updateGroup(
                                                          groupIndex,
                                                          group.copyWith(
                                                            options: nextOptions,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: MenuItemInlineField(
                                                      label: t?.translate(
                                                              'name_thai') ??
                                                          'Name (Thai)',
                                                      value:
                                                          option.nameTh ?? '',
                                                      onChanged: (v) {
                                                        final nextOptions = List<
                                                            MenuItemOptionModel>.from(
                                                          group.options,
                                                        );
                                                        nextOptions[
                                                                optionIndex] =
                                                            option.copyWith(
                                                          nameTh: v,
                                                        );
                                                        _updateGroup(
                                                          groupIndex,
                                                          group.copyWith(
                                                            options: nextOptions,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  SizedBox(
                                                    width: 100,
                                                    child: MenuItemInlineField(
                                                      label: t?.translate(
                                                              'price') ??
                                                          'Price',
                                                      hint: '0',
                                                      value: option.price == 0
                                                          ? ''
                                                          : option.price
                                                              .toString(),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (v) {
                                                        final nextOptions = List<
                                                            MenuItemOptionModel>.from(
                                                          group.options,
                                                        );
                                                        nextOptions[
                                                                optionIndex] =
                                                            option.copyWith(
                                                          price: double.tryParse(
                                                                  v) ??
                                                              0,
                                                        );
                                                        _updateGroup(
                                                          groupIndex,
                                                          group.copyWith(
                                                            options: nextOptions,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Text(
                                                    t?.translate('available') ??
                                                        'Available',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  PrimaryGradientSwitch(
                                                    value: option.isAvailable,
                                                    onChanged: (v) {
                                                      final nextOptions = List<
                                                          MenuItemOptionModel>.from(
                                                        group.options,
                                                      );
                                                      nextOptions[optionIndex] =
                                                          option.copyWith(
                                                        isAvailable: v,
                                                      );
                                                      _updateGroup(
                                                        groupIndex,
                                                        group.copyWith(
                                                          options: nextOptions,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  IconButton(
                                                    onPressed: () =>
                                                        _softDeleteOption(
                                                      context,
                                                      groupIndex,
                                                      optionIndex,
                                                    ),
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Color(0xFFEF4444),
                                                      size: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
