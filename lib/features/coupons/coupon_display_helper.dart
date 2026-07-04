import 'package:flutter/material.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

import 'data/coupon_redeem_service.dart';

/// Read-only coupon labels shared by order detail and in-store redeem UI.
class CouponDisplayHelper {
  CouponDisplayHelper._();

  static String _t(BuildContext context, String key, String fallback) =>
      AppLocalizations.of(context)?.translate(key) ?? fallback;

  static String discountBadge(
    BuildContext context, {
    required bool isFreeItem,
    required bool isBogoAllItems,
    required bool isPercentage,
    required double discountValue,
  }) {
    if (isFreeItem) {
      return isBogoAllItems
          ? _t(context, 'coupon_bogo_all', '1+1')
          : _t(context, 'coupon_free', 'FREE');
    }
    final v = discountValue == discountValue.roundToDouble()
        ? discountValue.toInt().toString()
        : discountValue.toStringAsFixed(2);
    return isPercentage ? '$v%' : '฿ $v';
  }

  static String discountBadgeForCoupon(
    BuildContext context,
    ShopEligibleCoupon coupon,
  ) =>
      discountBadge(
        context,
        isFreeItem: coupon.isFreeItem,
        isBogoAllItems: coupon.isBogoAllItems,
        isPercentage: coupon.isPercentage,
        discountValue: coupon.discountValue,
      );

  static String bogoGiftSummary(
    BuildContext context, {
    required bool isFreeItem,
    required bool isBogoAllItems,
    required List<ShopCouponItem> buyItems,
    required List<ShopCouponItem> freeItems,
  }) {
    if (!isFreeItem) return '';
    if (isBogoAllItems) {
      if (freeItems.isNotEmpty) {
        final items = freeItems
            .map((i) =>
                i.quantity > 1 ? '${i.displayName} x${i.quantity}' : i.displayName)
            .join(', ');
        return '${_t(context, 'coupon_free_items', 'Free')}: $items';
      }
      return _t(context, 'coupon_bogo_on_order', 'Buy 1 get 1 free on order');
    }

    final buy = buyItems.map((e) => e.displayName).where((e) => e.isNotEmpty);
    final free = freeItems.map((e) => e.displayName).where((e) => e.isNotEmpty);

    if (buy.isNotEmpty && free.isNotEmpty) {
      return _t(context, 'coupon_buy_get_summary', 'Buy {buy} → Free {free}')
          .replaceAll('{buy}', buy.join(', '))
          .replaceAll('{free}', free.join(', '));
    }
    if (freeItems.isNotEmpty) {
      final items = freeItems
          .map((i) =>
              i.quantity > 1 ? '${i.displayName} x${i.quantity}' : i.displayName)
          .join(', ');
      return '${_t(context, 'coupon_free_items', 'Free')}: $items';
    }
    if (buy.isNotEmpty) {
      return '${_t(context, 'coupon_buy_items', 'Buy')}: ${buy.join(', ')}';
    }
    return _t(context, 'coupon_free_item_generic', 'Free item included');
  }

  static String orderModalMessage(
    BuildContext context, {
    required String? couponName,
    required double discountAmount,
    required bool isFreeItem,
    required bool isBogoAllItems,
    required bool isPercentage,
    required double discountValue,
    required List<ShopCouponItem> buyItems,
    required List<ShopCouponItem> freeItems,
  }) {
    final name = (couponName ?? '').trim().isNotEmpty
        ? couponName!.trim()
        : _t(context, 'coupon_applied_generic', 'a coupon');

    if (isFreeItem) {
      final detail = bogoGiftSummary(
        context,
        isFreeItem: true,
        isBogoAllItems: isBogoAllItems,
        buyItems: buyItems,
        freeItems: freeItems,
      );
      if (detail.isNotEmpty) {
        return 'This customer used $name — $detail.';
      }
      return 'This customer used $name for a free item promotion.';
    }

    if (discountAmount > 0) {
      return 'This customer used $name for a discount on this order.';
    }

    if (isPercentage) {
      return 'This customer has $name (${discountValue.toStringAsFixed(0)}% off).';
    }

    return 'This customer has $name (฿${discountValue.toStringAsFixed(2)} off).';
  }
}
