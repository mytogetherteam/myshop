import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_shop/features/categories/presentation/screens/category_list_screen.dart';
import '../screens/manage_shop_menu_page.dart';

class QuickActionCards extends StatelessWidget {
  final VoidCallback? onRefresh;
  const QuickActionCards({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
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
                title: 'Manage\nCategory',
                imagePath: 'assets/images/Category.png',
                backgroundColor: const Color(0xFFFDE6D2), // Soft cream/orange
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                title: 'Manage\nShop Menu',
                imagePath: 'assets/images/Promotion.png',
                backgroundColor: const Color(0xFFFBD2D1), // Soft pink/red
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color backgroundColor;

  const _ActionCard({
    required this.title,
    required this.imagePath,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                Text(
                  title.split('\n').last,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 5,
            child: Image.asset(
              imagePath,
              width: 53,
              height: 53,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}
