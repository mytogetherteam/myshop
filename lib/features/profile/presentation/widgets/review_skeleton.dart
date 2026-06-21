import 'package:flutter/material.dart';
import 'package:my_shop/core/presentation/widgets/skeleton.dart';

class ReviewSkeleton extends StatelessWidget {
  const ReviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSummarySkeleton(context),
        SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 5,
            separatorBuilder: (_, _) => SizedBox(height: 16),
            itemBuilder: (_, _) => const _ReviewCardSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 24, width: 200),
          SizedBox(height: 16),
          Row(
            children: [
              const Skeleton(height: 48, width: 100),
              SizedBox(width: 16),
              const Expanded(child: Skeleton(height: 24)),
            ],
          ),
          SizedBox(height: 24),
          ...List.generate(5, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Skeleton(height: 12, width: 60),
                SizedBox(width: 12),
                const Expanded(child: Skeleton(height: 12)),
                SizedBox(width: 12),
                const Skeleton(height: 12, width: 80),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ReviewCardSkeleton extends StatelessWidget {
  const _ReviewCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : (Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9)))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Skeleton.circle(width: 40, height: 40),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(height: 14, width: 120),
                  SizedBox(height: 4),
                  const Skeleton(height: 10, width: 80),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          const Skeleton(height: 16, width: 100),
          SizedBox(height: 8),
          const Skeleton(height: 12, width: 120),
          SizedBox(height: 12),
          const Skeleton(height: 12, width: double.infinity),
          SizedBox(height: 6),
          const Skeleton(height: 12, width: double.infinity),
          SizedBox(height: 6),
          const Skeleton(height: 12, width: 200),
        ],
      ),
    );
  }
}
