import 'package:flutter/material.dart';

/// Scrollable skeleton placeholder list. Encodes [AlwaysScrollableScrollPhysics]
/// so [RefreshIndicator] works even while loading or with few items.
class SkeletonList extends StatelessWidget {
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final EdgeInsetsGeometry padding;
  final double? separatorHeight;

  const SkeletonList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(16),
    this.separatorHeight,
  });

  @override
  Widget build(BuildContext context) {
    const physics = AlwaysScrollableScrollPhysics();

    if (separatorHeight != null) {
      return ListView.separated(
        physics: physics,
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: separatorHeight),
        itemBuilder: itemBuilder,
      );
    }

    return ListView.builder(
      physics: physics,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
