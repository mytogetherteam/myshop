import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StatusProgressIndicator extends StatelessWidget {
  final String status;

  const StatusProgressIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    int activeStep = 0;
    switch (status) {
      case 'PENDING':
      case 'CONFIRMED':
      case 'AWAITING_APPROVAL':
        activeStep = 0;
        break;
      case 'PAYMENT_SLIP_REQUESTED':
      case 'PAYMENT_UPLOADED':
      case 'PAYMENT_VERIFIED':
        activeStep = 1;
        break;
      case 'PREPARING':
        activeStep = 2;
        break;
      case 'ON_THE_WAY':
        activeStep = 3;
        break;
      case 'DELIVERED':
        activeStep = 4;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStep(0, activeStep, PhosphorIconsRegular.check, PhosphorIconsFill.check, 'New'),
          _buildLine(0, activeStep),
          _buildStep(1, activeStep, PhosphorIconsRegular.wallet, PhosphorIconsFill.wallet, 'Payment'),
          _buildLine(1, activeStep),
          _buildStep(2, activeStep, PhosphorIconsRegular.cookingPot, PhosphorIconsFill.cookingPot, 'Cooking'),
          _buildLine(2, activeStep),
          _buildStep(3, activeStep, PhosphorIconsRegular.bicycle, PhosphorIconsFill.bicycle, 'On way'),
          _buildLine(3, activeStep),
          _buildStep(4, activeStep, PhosphorIconsRegular.houseLine, PhosphorIconsFill.houseLine, 'Done'),
        ],
      ),
    );
  }

  Widget _buildStep(int step, int activeStep, IconData icon, IconData activeIcon, String label) {
    final bool isActive = step <= activeStep;
    final bool isCurrent = step == activeStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFED3A72) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: const Color(0xFFED3A72).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
            border: Border.all(
              color: isActive ? const Color(0xFFED3A72) : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: Icon(
            isActive ? activeIcon : icon,
            size: 18,
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            color: isCurrent ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildLine(int step, int activeStep) {
    final bool isActive = step < activeStep;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 18.0),
        child: Container(
          height: 2,
          color: isActive ? const Color(0xFFED3A72) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}
