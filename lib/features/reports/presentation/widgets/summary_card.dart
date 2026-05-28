import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:my_shop/core/localization/app_localizations.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool isPositive;
  final bool? isTrendPositive;
  final String? unit;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
    this.isTrendPositive,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        color: (isPositive && (label == "Completed" || label == (AppLocalizations.of(context)?.translate('completed') ?? "Completed")))
                            ? const Color(0xFF22C55E)
                            : ((label == "Cancelled" || label == (AppLocalizations.of(context)?.translate('cancelled') ?? "Cancelled"))
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF1E293B)),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit!,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PhosphorIcon(
                      isPositive ? PhosphorIconsRegular.arrowUp : PhosphorIconsRegular.arrowDown,
                      size: 12,
                      color: (isTrendPositive ?? isPositive) ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          trend,
                          style: GoogleFonts.poppins(
                            color: (isTrendPositive ?? isPositive) ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
