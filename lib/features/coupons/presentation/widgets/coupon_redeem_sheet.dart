import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/core/localization/app_localizations.dart';
import 'package:my_shop/core/presentation/widgets/app_dialog.dart';
import 'package:my_shop/core/utils/app_colors.dart';
import 'package:my_shop/features/coupons/data/coupon_redeem_service.dart';

/// Bottom sheet shown after a customer's redeem QR is scanned. Lists the
/// coupons the customer can claim in-store; the admin picks one and redeems it.
class CouponRedeemSheet extends StatefulWidget {
  final ScanResult scan;

  const CouponRedeemSheet({super.key, required this.scan});

  /// Returns true when a coupon was redeemed.
  static Future<bool?> show(BuildContext context, ScanResult scan) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CouponRedeemSheet(scan: scan),
    );
  }

  @override
  State<CouponRedeemSheet> createState() => _CouponRedeemSheetState();
}

class _CouponRedeemSheetState extends State<CouponRedeemSheet> {
  int? _selectedId;
  bool _busy = false;

  String _t(BuildContext context, String key, String fallback) =>
      AppLocalizations.of(context)?.translate(key) ?? fallback;

  String _discountLabel(ShopEligibleCoupon c) {
    if (c.isFreeItem) return _t(context, 'coupon_free', 'FREE');
    final v = c.discountValue == c.discountValue.roundToDouble()
        ? c.discountValue.toInt().toString()
        : c.discountValue.toString();
    return c.isPercentage ? '$v%' : '฿$v';
  }

  Future<void> _redeem() async {
    ShopEligibleCoupon? selected;
    for (final c in widget.scan.coupons) {
      if (c.id == _selectedId) {
        selected = c;
        break;
      }
    }
    if (selected == null || _busy) return;

    setState(() => _busy = true);
    try {
      final message = await CouponRedeemService.instance.apply(
        userId: widget.scan.userId,
        couponCode: selected.code,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppDialog.showToast(context, message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppDialog.showToast(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupons = widget.scan.coupons;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.verified_user_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t(context, 'coupon_customer_verified',
                        'Customer verified'),
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              coupons.isEmpty
                  ? _t(context, 'coupon_none_for_customer',
                      'No coupons available for this customer right now.')
                  : _t(context, 'coupon_pick_to_redeem',
                      'Pick a coupon to redeem at the counter.'),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            if (coupons.isEmpty)
              _buildEmpty(context)
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: coupons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildCouponTile(context, coupons[index]),
                ),
              ),
            if (coupons.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_selectedId == null || _busy) ? null : _redeem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _t(context, 'coupon_redeem', 'Redeem'),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.local_offer_outlined,
                size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_t(context, 'close', 'Close')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponTile(BuildContext context, ShopEligibleCoupon c) {
    final selected = c.id == _selectedId;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selectedId = c.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE5E5E5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  child: Text(
                    _discountLabel(c),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.code,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (c.freeItems.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${_t(context, 'coupon_free_items', 'Free')}: '
                      '${c.freeItems.map((i) => '${i.name} x${i.quantity}').join(', ')}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
