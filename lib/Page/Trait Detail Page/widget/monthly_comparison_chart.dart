import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';

/// Monthly comparison chart for trait details
class MonthlyComparisonChart extends StatelessWidget {
  final TraitModel traitModel;
  final Color selectedColor;

  const MonthlyComparisonChart({
    super.key,
    required this.traitModel,
    required this.selectedColor,
  });

  Map<int, Duration> _getMonthlyData() {
    final now = DateTime.now();
    final Map<int, Duration> monthlyData = {};

    // Get last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      monthlyData[month.month] = Duration.zero;
    }

    // Get all logs
    final allLogs = TaskLogProvider().taskLogList;

    for (final log in allLogs) {
      final task = TaskProvider().taskList.firstWhere(
            (t) => t.id == log.id,
            orElse: () => TaskProvider().taskList.first,
          );

      final hasTrait = (task.attributeIDList?.contains(traitModel.id) ?? false) || (task.skillIDList?.contains(traitModel.id) ?? false);

      if (hasTrait) {
        final logMonth = log.logDate.month;
        if (monthlyData.containsKey(logMonth)) {
          monthlyData[logMonth] = monthlyData[logMonth]! + (log.duration ?? Duration.zero);
        }
      }
    }

    return monthlyData;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyData = _getMonthlyData();
    final sortedMonths = monthlyData.keys.toList()..sort();

    // Calculate max hours for scaling
    double maxHours = 0;
    for (final duration in monthlyData.values) {
      final hours = duration.inHours.toDouble();
      if (hours > maxHours) maxHours = hours;
    }

    if (maxHours == 0) maxHours = 10; // Default minimum
    maxHours = (maxHours * 1.2).ceilToDouble(); // Add 20% padding

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panelBackground2,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month = sortedMonths[group.x.toInt()];
                      final duration = monthlyData[month] ?? Duration.zero;
                      final monthName = DateFormat('MMM', context.locale.languageCode).format(DateTime(2024, month));
                      return BarTooltipItem(
                        '$monthName\n${duration.textShort2hour()}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < sortedMonths.length) {
                          final month = sortedMonths[value.toInt()];
                          final monthName = DateFormat('MMM', context.locale.languageCode).format(DateTime(2024, month));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthName.substring(0, 3),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.text.withOpacity(0.7),
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.text.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxHours / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.text.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: selectedColor.withOpacity(0.3), width: 2),
                    left: BorderSide(color: selectedColor.withOpacity(0.3), width: 2),
                  ),
                ),
                barGroups: List.generate(sortedMonths.length, (index) {
                  final month = sortedMonths[index];
                  final duration = monthlyData[month] ?? Duration.zero;
                  final hours = duration.inHours.toDouble();
                  final now = DateTime.now();
                  final isCurrentMonth = month == now.month;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: hours,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: isCurrentMonth ? [selectedColor, selectedColor.withOpacity(0.7)] : [selectedColor.withOpacity(0.7), selectedColor.withOpacity(0.5)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  );
                }),
                maxY: maxHours,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
