import 'package:flutter/material.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class CustomLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const CustomLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // The order: top-right -> bottom-right -> bottom-left -> top-left -> top-right
    // Positions:
    // TR: (1, 0)
    // BR: (1, 1)
    // BL: (0, 1)
    // TL: (0, 0)
    _animation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(1, 0), end: const Offset(1, 1))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(1, 1), end: const Offset(0, 1))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0, 0), end: const Offset(1, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25.0,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Interpolate between primary (#ED3973) and secondary (#EFA240) gradient colors
  Color _gradientColor(double t) {
    const c1 = AppColors.primary;   // #ED3973 (pink-red)
    const c2 = AppColors.secondary; // #EFA240 (orange)
    return Color.lerp(c1, c2, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.size / 2.2;
    final spacing = widget.size * 0.1;

    // Each background dot gets a gradient-interpolated color:
    // TL = 0.0 (primary pink), TR = 0.33, BL = 0.67, BR = 1.0 (secondary orange)
    final dotColors = [
      _gradientColor(0.0).withValues(alpha: 0.25),  // TL
      _gradientColor(0.33).withValues(alpha: 0.25), // TR
      _gradientColor(0.67).withValues(alpha: 0.25), // BL
      _gradientColor(1.0).withValues(alpha: 0.25),  // BR
    ];

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Background dots with gradient-interpolated colors
          _buildDot(0, 0, dotColors[0], dotSize, spacing), // TL
          _buildDot(1, 0, dotColors[1], dotSize, spacing), // TR
          _buildDot(0, 1, dotColors[2], dotSize, spacing), // BL
          _buildDot(1, 1, dotColors[3], dotSize, spacing), // BR

          // Active dot — moves around with gradient fill + glow shadow
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final t = (_animation.value.dx + _animation.value.dy) / 2.0;
              return Positioned(
                left: _animation.value.dx * (dotSize + spacing),
                top: _animation.value.dy * (dotSize + spacing),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _gradientColor(t),
                        _gradientColor((t + 0.4).clamp(0.0, 1.0)),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(dotSize * 0.3),
                    boxShadow: [
                      BoxShadow(
                        color: _gradientColor(t).withValues(alpha: 0.45),
                        blurRadius: dotSize * 0.6,
                        offset: Offset(0, dotSize * 0.15),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double xIndex, double yIndex, Color color, double size, double spacing) {
    return Positioned(
      left: xIndex * (size + spacing),
      top: yIndex * (size + spacing),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
      ),
    );
  }
}
