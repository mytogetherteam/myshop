import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedEllipsisText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const AnimatedEllipsisText({
    super.key,
    required this.text,
    this.style,
  });

  @override
  State<AnimatedEllipsisText> createState() => _AnimatedEllipsisTextState();
}

class _AnimatedEllipsisTextState extends State<AnimatedEllipsisText> {
  int _dotCount = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 5; // 0, 1, 2, 3, 4
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dots = '.' * _dotCount;
    // Add invisible dots to maintain constant width and prevent layout shift
    String invisibleDots = '.' * (4 - _dotCount);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start, // Align to start so dots append naturally
      children: [
        Text(
          widget.text,
          style: widget.style,
        ),
        Text(
          dots,
          style: widget.style,
        ),
        Opacity(
          opacity: 0,
          child: Text(
            invisibleDots,
            style: widget.style,
          ),
        ),
      ],
    );
  }
}
