import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class StatusProgressIndicator extends StatefulWidget {
  final String status;

  const StatusProgressIndicator({super.key, required this.status});

  @override
  State<StatusProgressIndicator> createState() => _StatusProgressIndicatorState();
}

class _StatusProgressIndicatorState extends State<StatusProgressIndicator> with TickerProviderStateMixin {
  late AnimationController _lineController;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int activeStep = 0;
    switch (widget.status) {
      case 'PENDING':
      case 'REVISED':
        activeStep = 0;
        break;
      case 'PAYMENT_SLIP_REQUESTED':
      case 'AWAITING_APPROVAL':
      case 'PAYMENT_VERIFIED':
        activeStep = 1;
        break;
      case 'COOKING':
        activeStep = 2;
        break;
      case 'ON_THE_WAY':
        activeStep = 3;
        break;
      case 'DELIVERED':
        activeStep = 4;
        break;
      case 'CANCELED':
        activeStep = 0;
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
          _buildStep(3, activeStep, PhosphorIconsRegular.moped, PhosphorIconsFill.moped, 'On way'),
          _buildLine(3, activeStep),
          _buildStep(4, activeStep, PhosphorIconsRegular.houseLine, PhosphorIconsFill.houseLine, 'Done'),
        ],
      ),
    );
  }

  Widget _buildStep(int step, int activeStep, IconData icon, IconData activeIcon, String label) {
    final bool isActive = step <= activeStep;
    final bool isCurrent = step == activeStep && widget.status != 'DELIVERED' && widget.status != 'CANCELED';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? null : const Color(0xFFF1F5F9),
            gradient: isActive
                ? LinearGradient(
                    colors: AppColors.primaryGradient.colors
                        .map((c) => c.withValues(alpha: 0.15))
                        .toList(),
                  )
                : null,
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
            border: Border.all(
              color: isActive ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: isActive
              ? ShaderMask(
                  shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                  child: Icon(
                    activeIcon,
                    size: 18,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  icon,
                  size: 18,
                  color: const Color(0xFF94A3B8),
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
    final bool isCompleted = step < activeStep;
    final bool isProcessing = step == activeStep && widget.status != 'DELIVERED' && widget.status != 'CANCELED';
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 18.0),
        child: SizedBox(
          height: 3,
          child: Stack(
            children: [
              // Background track
              Container(
                height: 3,
                color: const Color(0xFFE2E8F0),
              ),
              if (isCompleted)
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                ),
              if (isProcessing)
                AnimatedBuilder(
                  animation: _lineController,
                  builder: (context, child) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.loose,
                          children: [
                            // Growing fill line with gradient
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: width * _lineController.value,
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.1),
                                      AppColors.primary,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
