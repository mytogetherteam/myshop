import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsDonutChart extends StatefulWidget {
  final double section1Value;
  final double section2Value;
  final Color section1Color;
  final Color section2Color;
  final String section1Label;
  final String section2Label;
  final String centerTitle;
  final String centerSubtitle;

  const AnalyticsDonutChart({
    super.key,
    required this.section1Value,
    required this.section2Value,
    required this.section1Color,
    required this.section2Color,
    required this.section1Label,
    required this.section2Label,
    required this.centerTitle,
    required this.centerSubtitle,
  });

  @override
  State<AnalyticsDonutChart> createState() => _AnalyticsDonutChartState();
}

class _AnalyticsDonutChartState extends State<AnalyticsDonutChart> {
  // Start with all values at 0, then animate to real values after build
  bool _animated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _animated = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s1 = _animated ? widget.section1Value : 0.001;
    final s2 = _animated ? widget.section2Value : 0.001;

    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: widget.section1Color,
                  value: s1,
                  title: '',
                  radius: 16,
                ),
                PieChartSectionData(
                  color: widget.section2Color,
                  value: s2,
                  title: '',
                  radius: 16,
                ),
              ],
            ),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
