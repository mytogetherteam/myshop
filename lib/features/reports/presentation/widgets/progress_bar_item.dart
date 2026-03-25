import 'package:flutter/material.dart';

class ProgressBarItem extends StatelessWidget {
  final String label;
  final String value;
  final double percentage; // 0.0 to 1.0
  final Color backgroundColor;
  final Color? barColor;
  final Gradient? barGradient;

  const ProgressBarItem({
    super.key,
    required this.label,
    required this.value,
    this.percentage = 0.0,
    this.backgroundColor = const Color(0xFFF1F5F9), // Slate 100
    this.barColor,
    this.barGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                gradient: barGradient,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
