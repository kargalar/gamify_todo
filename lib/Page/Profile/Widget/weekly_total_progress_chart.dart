import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:gamify_todo/Provider/profile_view_model.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';

// This chart shows total weekly progress for all tasks combined
// Displays total time spent on all tasks per day
// Data shows a single line representing total work time per day

class WeeklyTotalProgressChart extends StatefulWidget {
  const WeeklyTotalProgressChart({super.key});

  @override
  State<StatefulWidget> createState() => WeeklyTotalProgressChartState();
}

class WeeklyTotalProgressChartState extends State<WeeklyTotalProgressChart> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ProfileViewModel>();
    final totalDurations = viewModel.getTotalTaskDurations();

    // Calculate total duration for the week
    Duration totalDuration = Duration.zero;
    for (var duration in totalDurations.values) {
      totalDuration += duration;
    }

    // Format total duration
    int totalHours = totalDuration.inHours;
    int remainingMinutes = totalDuration.inMinutes.remainder(60);
    String durationText = context.locale == const Locale('en', 'US') ? "$totalHours ${LocaleKeys.h.tr()} $remainingMinutes ${LocaleKeys.m.tr()}" : "$totalHours ${LocaleKeys.h.tr()} $remainingMinutes ${LocaleKeys.m.tr()}";

    return SizedBox(
      height: 250,
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${LocaleKeys.WeeklyProgress.tr()} ($durationText)",
                    style: TextStyle(
                      color: AppColors.main,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 16, left: 6),
                  child: _LineChart(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ProfileViewModel>();
    final totalDurations = viewModel.getTotalTaskDurations();

    List<LineChartBarData> dataList = [];
    // Calculate max value from all data points
    double maxHours = 0;

    // Create single line chart data for total hours
    dataList.add(
      LineChartBarData(
        isCurved: false,
        color: AppColors.main,
        barWidth: 3,
        isStrokeCapRound: true,
        // dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: AppColors.main.withValues(alpha: 0.2),
        ),
        spots: List.generate(7, (index) {
          DateTime now = DateTime.now();
          DateTime monday = now.subtract(Duration(days: now.weekday - 1));
          DateTime date = monday.add(Duration(days: index));
          date = DateTime(date.year, date.month, date.day);

          double hours = (totalDurations[date]?.inHours.toDouble() ?? 0) + (totalDurations[date]?.inMinutes.remainder(60).toDouble() ?? 0) / 60;
          if (hours > maxHours) {
            maxHours = hours;
          }

          return FlSpot(
            index.toDouble(),
            hours,
          );
        }),
      ),
    );

    // Round up to next multiple of 5 for better readability
    maxHours = ((maxHours + 1.99) ~/ 2) * 2.0;
    maxHours = maxHours < 2 ? 2 : maxHours;

    Widget bottomTitleWidgets(
      double value,
      TitleMeta meta,
    ) {
      late List<String> days;

      if (context.locale == const Locale('en', 'US')) {
        days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      } else {
        days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      }

      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 10,
        child: Text(
          days[value.toInt()],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    Widget leftTitleWidgets(double value, TitleMeta meta) {
      // Show actual hour values based on the value parameter
      String hourText = '${value.toStringAsFixed(0)}${LocaleKeys.h.tr()}';

      return Text(hourText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center);
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              getTitlesWidget: leftTitleWidgets,
              showTitles: true,
              reservedSize: 40,
              interval: (maxHours / 5),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: AppColors.main),
            left: BorderSide(color: AppColors.main),
          ),
        ),
        lineBarsData: dataList,
        minX: 0,
        maxX: 6,
        maxY: dataList.isEmpty ? 5 : maxHours,
        minY: 0,
      ),
    );
  }
}
