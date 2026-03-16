import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/features/notifications/presentation/widgets/notification_badge_icon.dart';

class MenuHeader extends StatefulWidget {
  const MenuHeader({super.key});

  @override
  State<MenuHeader> createState() => _MenuHeaderState();
}

class _MenuHeaderState extends State<MenuHeader> {
  bool _isFavorited = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // KFC Logo Placeholder/Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFED1C24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/app_logo.png', // Fallback to app logo for now
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.restaurant, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Shop Menu',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          // Action Icons
          const NotificationBadgeIcon(),
          IconButton(
            onPressed: () {},
            icon: PhosphorIcon(
              PhosphorIconsRegular.shareNetwork,
              color: const Color(0xFF1E293B),
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isFavorited = !_isFavorited;
              });
            },
            icon: PhosphorIcon(
              _isFavorited ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
              color: _isFavorited ? const Color(0xFFED3A72) : const Color(0xFF1E293B),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
