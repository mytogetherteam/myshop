import 'package:flutter/material.dart';

class ProgressBarItem extends StatefulWidget {
  final String label;
  final String value;
  final double percentage; // 0.0 to 1.0
  final Color? backgroundColor;
  final Color? barColor;
  final Gradient? barGradient;

  const ProgressBarItem({
    super.key,
    required this.label,
    required this.value,
    this.percentage = 0.0,
    this.backgroundColor,
    this.barColor,
    this.barGradient,
  });

  @override
  State<ProgressBarItem> createState() => _ProgressBarItemState();
}

class _ProgressBarItemState extends State<ProgressBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    // Small delay so the widget is laid out before animating
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor:
                    (widget.percentage.clamp(0.0, 1.0) * _animation.value),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.barColor,
                    gradient: widget.barGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
