import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shop/core/localization/app_localizations.dart';


class ShopProfileImageHeader extends StatelessWidget {
  final XFile? pickedCover;
  final XFile? pickedLogo;
  final String? coverUrl;
  final String? logoUrl;
  final String shopName;
  final VoidCallback onPickCover;
  final VoidCallback onPickLogo;

  const ShopProfileImageHeader({
    super.key,
    required this.pickedCover,
    required this.pickedLogo,
    required this.coverUrl,
    required this.logoUrl,
    required this.shopName,
    required this.onPickCover,
    required this.onPickLogo,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    const heroHeight = 360.0;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Full hero image ───────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
              child: GestureDetector(
                onTap: onPickCover,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image or gradient fallback
                    if (pickedCover != null)
                      kIsWeb
                          ? Image.network(pickedCover!.path, fit: BoxFit.cover)
                          : Image.file(
                              File(pickedCover!.path),
                              fit: BoxFit.cover,
                            )
                                        else if (coverUrl != null && coverUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _buildCoverGradient(),
                        errorWidget: (_, _, _) => _buildCoverGradient(),
                      )
                    else
                      _buildCoverGradient(),

                    // Dark overlay at top for back button contrast
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 90,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Camera hint when no cover photo
                    if (pickedCover == null &&
                        (coverUrl == null || coverUrl!.isEmpty))
                      Container(
                        color: Colors.black.withValues(alpha: 0.15),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const PhosphorIcon(
                                  PhosphorIconsRegular.camera,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                t?.translate('tap_to_add_cover_photo') ?? 'Tap to Add Cover Photo',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating info card (inside hero image) ──────
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Logo (tap to change)
                  GestureDetector(
                    onTap: onPickLogo,
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: pickedLogo != null
                                ? (kIsWeb
                                      ? Image.network(
                                          pickedLogo!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(pickedLogo!.path),
                                          fit: BoxFit.cover,
                                        ))
                                : logoUrl != null && logoUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: logoUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) =>
                                        _buildLogoPlaceholder(),
                                    errorWidget: (_, _, _) =>
                                        _buildLogoPlaceholder(),
                                  )
                                : _buildLogoPlaceholder(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFED3973),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      shopName,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFED3973), Color(0xFFFF8C69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFED3973), Color(0xFFFF8C69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: PhosphorIcon(
          PhosphorIconsRegular.storefront,
          size: 26,
          color: Colors.white,
        ),
      ),
    );
  }
}
