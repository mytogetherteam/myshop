import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/presentation/widgets/primary_gradient_switch.dart';
import 'package:my_shop/features/menu/data/models/menu_item_model.dart';
import 'package:my_shop/features/menu/data/models/variant_group_mapper.dart';
import 'menu_item_inline_field.dart';

class VariantGroupsCard extends StatelessWidget {
  final List<MenuItemVariantGroupEditModel> variantGroups;
  final ValueChanged<List<MenuItemVariantGroupEditModel>> onChange;
  final bool isEditMode;

  const VariantGroupsCard({
    super.key,
    required this.variantGroups,
    required this.onChange,
    this.isEditMode = false,
  });

  List<MenuItemVariantGroupEditModel> get _visibleGroups =>
      variantGroups.where((group) => !group.isDeleted).toList();

  void _updateGroups(List<MenuItemVariantGroupEditModel> next) {
    onChange(next);
  }

  void _addGroup(BuildContext context) {
    HapticFeedback.lightImpact();
    _updateGroups([
      ...variantGroups,
      MenuItemVariantGroupEditModel(
        displayOrder: _visibleGroups.length + 1,
        variants: [
          MenuItemVariantModel(
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
    final group = variantGroups[groupIndex];
    if (isEditMode && group.id > 0) {
      final next = [...variantGroups];
      next[groupIndex] = group.copyWith(
        isDeleted: true,
        variants: group.variants
            .map(
              (variant) =>
                  variant.id > 0 ? variant.copyWith(isDeleted: true) : variant,
            )
            .toList(),
      );
      _updateGroups(next);
      final t = AppLocalizations.of(context);
      AppDialog.showToast(
        context,
        t?.translate('variant_group_removed_toast') ??
            'Variant group removed. Save the item to apply.',
      );
      return;
    }

    final next = variantGroups
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

  void _updateGroup(int groupIndex, MenuItemVariantGroupEditModel group) {
    final next = [...variantGroups];
    next[groupIndex] = group;
    _updateGroups(next);
  }

  void _addVariant(int groupIndex) {
    HapticFeedback.lightImpact();
    final group = variantGroups[groupIndex];
    final visibleCount = group.variants.where((v) => !v.isDeleted).length;
    _updateGroup(
      groupIndex,
      group.copyWith(
        variants: [
          ...group.variants,
          MenuItemVariantModel(
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

  void _softDeleteVariant(
    BuildContext context,
    int groupIndex,
    int variantIndex,
  ) {
    HapticFeedback.lightImpact();
    final group = variantGroups[groupIndex];
    final variant = group.variants[variantIndex];
    final nextVariants = List<MenuItemVariantModel>.from(group.variants);

    if (isEditMode && variant.id > 0) {
      nextVariants[variantIndex] = variant.copyWith(isDeleted: true);
      _updateGroup(groupIndex, group.copyWith(variants: nextVariants));
      final t = AppLocalizations.of(context);
      AppDialog.showToast(
        context,
        t?.translate('variant_removed_toast') ??
            'Variant removed. Save the item to apply.',
      );
      return;
    }

    nextVariants.removeAt(variantIndex);
    _updateGroup(
      groupIndex,
      group.copyWith(
        variants: nextVariants
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

    final visible = List<MenuItemVariantGroupEditModel>.from(_visibleGroups);
    final moved = visible.removeAt(oldIndex);
    visible.insert(newIndex, moved);

    final next = <MenuItemVariantGroupEditModel>[];
    var visibleIndex = 0;
    for (final group in variantGroups) {
      if (group.isDeleted) {
        next.add(group);
        continue;
      }
      next.add(visible[visibleIndex].copyWith(displayOrder: visibleIndex + 1));
      visibleIndex++;
    }
    _updateGroups(next);
  }

  void _onReorderVariant(int groupIndex, int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    if (newIndex > oldIndex) newIndex--;

    final group = variantGroups[groupIndex];
    final visible = group.variants.where((v) => !v.isDeleted).toList();
    final deleted = group.variants.where((v) => v.isDeleted).toList();
    final moved = visible.removeAt(oldIndex);
    visible.insert(newIndex, moved);

    final reordered = visible
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(displayOrder: entry.key + 1))
        .toList();

    _updateGroup(groupIndex, group.copyWith(variants: [...reordered, ...deleted]));
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
        border: Border.all(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
        ),
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
                        t?.translate('variants') ?? 'Variants',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t?.translate('variants_description') ??
                            'Group related options such as Size or Temperature, then add choices inside each group.',
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
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Text(
                      t?.translate('no_variant_groups') ??
                          'No variant groups added.',
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
                    onReorderStart: (_) => HapticFeedback.lightImpact(),
                    itemBuilder: (context, visibleIndex) {
                      final group = visibleGroups[visibleIndex];
                      final groupIndex = variantGroups.indexWhere(
                        (g) => g.clientKey == group.clientKey,
                      );
                      final variants = group.variants
                          .where((variant) => !variant.isDeleted)
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
                                            'Group Name (EN) e.g. Size',
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
                                    t?.translate('choices_in_group') ??
                                        'Choices in this group',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _addVariant(groupIndex),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text(
                                      t?.translate('add_variant') ??
                                          'Add Variant',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              if (variants.isEmpty)
                                Text(
                                  t?.translate('no_variants_in_group') ??
                                      'No variants in this group yet.',
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
                                  itemCount: variants.length,
                                  onReorder: (oldIndex, newIndex) =>
                                      _onReorderVariant(
                                    groupIndex,
                                    oldIndex,
                                    newIndex,
                                  ),
                                  itemBuilder: (context, variantVisibleIndex) {
                                    final variant = variants[variantVisibleIndex];
                                    final variantIndex = group.variants
                                        .indexWhere(
                                      (v) => v.clientKey == variant.clientKey,
                                    );

                                    return Padding(
                                      key: ValueKey(variant.clientKey),
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: MenuItemSortableRow(
                                        index: variantVisibleIndex,
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
                                                      hint: t?.translate(
                                                              'variant_name') ??
                                                          'Variant Name (EN)',
                                                      value:
                                                          variant.nameEn ?? '',
                                                      onChanged: (v) {
                                                        final nextVariants =
                                                            List<
                                                                MenuItemVariantModel>.from(
                                                          group.variants,
                                                        );
                                                        nextVariants[
                                                                variantIndex] =
                                                            variant.copyWith(
                                                          nameEn: v,
                                                        );
                                                        _updateGroup(
                                                          groupIndex,
                                                          group.copyWith(
                                                            variants:
                                                                nextVariants,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: MenuItemInlineField(
                                                      hint: 'MM',
                                                      value:
                                                          variant.nameMm ?? '',
                                                      onChanged: (v) {
                                                        final nextVariants =
                                                            List<
                                                                MenuItemVariantModel>.from(
                                                          group.variants,
                                                        );
                                                        nextVariants[
                                                                variantIndex] =
                                                            variant.copyWith(
                                                          nameMm: v,
                                                        );
                                                        _updateGroup(
                                                          groupIndex,
                                                          group.copyWith(
                                                            variants:
                                                                nextVariants,
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
                                                      hint: 'TH',
                                                      value:
                                                          variant.nameTh ?? '',
                                                      onChanged: (v) {
                                                        final nextVariants =
                                                            List<
                                                                MenuItemVariantModel>.from(
                                                          group.variants,
                                                        );
                                                        nextVariants[
                                                                variantIndex] =
                                                            variant.copyWith(
                                                          nameTh: v,
                                                        );
                                                        _updateGroup(
                                                          groupIndex,
                                                          group.copyWith(
                                                            variants:
                                                                nextVariants,
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
                                                      value: variant.price == 0
                                                          ? ''
                                                          : variant.price
                                                              .toString(),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (v) {
                                                        final nextVariants =
                                                            List<
                                                                MenuItemVariantModel>.from(
                                                          group.variants,
                                                        );
                                                        nextVariants[
                                                                variantIndex] =
                                                            variant.copyWith(
                                                          price: double.tryParse(
                                                                  v) ??
                                                              0,
                                                        );
                                                        _updateGroup(
                                                          groupIndex,
                                                          group.copyWith(
                                                            variants:
                                                                nextVariants,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () =>
                                                        _softDeleteVariant(
                                                      context,
                                                      groupIndex,
                                                      variantIndex,
                                                    ),
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Color(0xFFEF4444),
                                                      size: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
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
                                                    value: variant.isAvailable,
                                                    onChanged: (v) {
                                                      final nextVariants = List<
                                                          MenuItemVariantModel>.from(
                                                        group.variants,
                                                      );
                                                      nextVariants[
                                                              variantIndex] =
                                                          variant.copyWith(
                                                        isAvailable: v,
                                                      );
                                                      _updateGroup(
                                                        groupIndex,
                                                        group.copyWith(
                                                          variants: nextVariants,
                                                        ),
                                                      );
                                                    },
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
