import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/features/categories/presentation/screens/category_list_screen.dart';
import '../screens/manage_shop_menu_page.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class QuickActionCards extends StatelessWidget {
  final VoidCallback? onRefresh;
  const QuickActionCards({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryListScreen()),
                );
                onRefresh?.call();
              },
              child: _ActionCard(
                topText: t?.translate('manage_category_top') ?? 'Manage',
                bottomText: t?.translate('manage_category_bottom') ?? 'Category',
                imagePath: 'assets/images/Category.png',
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4A2A18) : const Color(0xFFFDE6D2),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageShopMenuPage()),
                );
                onRefresh?.call();
              },
              child: _ActionCard(
                topText: t?.translate('manage_menu_top') ?? 'Manage',
                bottomText: t?.translate('manage_menu_bottom') ?? 'Shop Menu',
                imagePath: 'assets/images/Promotion.png',
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4A1A1D) : const Color(0xFFFBD2D1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String topText;
  final String bottomText;
  final String imagePath;
  final Color backgroundColor;

  const _ActionCard({
    required this.topText,
    required this.bottomText,
    required this.imagePath,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isMyanmar = locale.languageCode == 'my';
    final isThai = locale.languageCode == 'th';
    final hasDiacritics = isMyanmar || isThai;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: hasDiacritics ? 1.5 : 1.3,
                  ),
                ),
                SizedBox(height: hasDiacritics ? 6 : 2),
                Text(
                  bottomText,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: hasDiacritics ? 1.4 : 1.1,
                  ),
                ),
              ],
            ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              imagePath,
              width: 75,
              height: 75,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}
