import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/menu_header.dart';
import '../widgets/quick_action_cards.dart';
import '../widgets/menu_item_card.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const MenuHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Dropdown / Selection Section placeholder from design
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Today’s Recommendation',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1E293B), size: 24),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.search, color: Color(0xFF1E293B), size: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const QuickActionCards(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Today’s Recommendation',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Menu Items
                    const MenuItemCard(
                      title: 'Lat Pan Phyar Fried Chicken',
                      originalPrice: 85,
                      discountedPrice: 75,
                      imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=2070&auto=format&fit=crop',
                    ),
                    const MenuItemCard(
                      title: 'Double Beef Patty Burger',
                      originalPrice: 125,
                      discountedPrice: 110,
                      imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?q=80&w=2070&auto=format&fit=crop',
                    ),
                    const MenuItemCard(
                      title: 'Veggie Delight Burger',
                      originalPrice: 75,
                      discountedPrice: 65,
                      imageUrl: 'https://images.unsplash.com/photo-1520201163981-8cc95007dd2a?q=80&w=1974&auto=format&fit=crop',
                      initialInStock: false,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
