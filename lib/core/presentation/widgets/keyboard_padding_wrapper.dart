import 'package:flutter/material.dart';

class KeyboardPaddingWrapper extends StatefulWidget {
  final Widget child;

  const KeyboardPaddingWrapper({super.key, required this.child});

  @override
  State<KeyboardPaddingWrapper> createState() => _KeyboardPaddingWrapperState();
}

class _KeyboardPaddingWrapperState extends State<KeyboardPaddingWrapper> with WidgetsBindingObserver {
  double _bottomPadding = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize with current padding
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    _bottomPadding = view.viewInsets.bottom / view.devicePixelRatio;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (mounted) {
      // Avoid View.of(context) here because during Navigator.pop, 
      // this widget is unmounting and calling InheritedWidgets throws an error.
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      setState(() {
        _bottomPadding = view.viewInsets.bottom / view.devicePixelRatio;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: _bottomPadding),
      child: widget.child,
    );
  }
}
