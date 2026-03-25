import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsDonutChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                  color: section1Color,
                  value: section1Value,
                  title: '',
                  radius: 16,
                ),
                PieChartSectionData(
                  color: section2Color,
                  value: section2Value,
                  title: '',
                  radius: 16,
                ),
              ],
            ),
          ),
          // We can leave the center empty for now and add a custom overlay, or rely on the UI layout below.
        ],
      ),
    );
  }
}
