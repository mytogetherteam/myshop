import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_shop/core/utils/app_colors.dart';

class AnalyticsLineChart extends StatefulWidget {
  final List<FlSpot> spots;
  final List<String> bottomLabels;
  final double maxY;
  final double minY;

  const AnalyticsLineChart({
    super.key,
    required this.spots,
    required this.bottomLabels,
    required this.maxY,
    this.minY = 0,
  });

  @override
  State<AnalyticsLineChart> createState() => _AnalyticsLineChartState();
}

class _AnalyticsLineChartState extends State<AnalyticsLineChart> {
  // We animate by replacing a flat (zero-value) dataset with the real one
  bool _animated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _animated = true);
    });
  }

  List<FlSpot> get _displaySpots {
    if (!_animated) {
      // All spots at minY so the line animates from a flat baseline upward
      return widget.spots
          .map((s) => FlSpot(s.x, widget.minY))
          .toList();
    }
    return widget.spots;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2000,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xFFE2E8F0),
                strokeWidth: 1,
                dashArray: [4, 4],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < widget.bottomLabels.length) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        widget.bottomLabels[index],
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2000,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == widget.minY) {
                    return SideTitleWidget(
                      meta: meta,
                      child: const Text(
                        '0',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '฿ ${(value / 1000).toStringAsFixed(0)},000',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (widget.spots.length - 1).toDouble(),
          minY: widget.minY,
          maxY: widget.maxY,
          lineBarsData: [
            LineChartBarData(
              spots: _displaySpots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
