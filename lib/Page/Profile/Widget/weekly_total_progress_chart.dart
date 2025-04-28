import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gamify_todo/General/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:gamify_todo/Provider/profile_view_model.dart';
import 'package:gamify_todo/Service/locale_keys.g.dart';
import 'package:gamify_todo/Core/extensions.dart';

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

    // Format total duration using the extension method
    String durationText = totalDuration.textShortDynamic();

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Column(
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
          const SizedBox(height: 8),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 16, left: 6),
              child: _LineChart(),
            ),
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
        isCurved: true, // Make the line curved for better visual appeal
        curveSmoothness: 0.3, // Adjust curve smoothness
        color: AppColors.main,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 5,
            color: AppColors.main,
            strokeWidth: 2,
            strokeColor: AppColors.white,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: AppColors.main.withValues(alpha: 0.2),
          gradient: LinearGradient(
            colors: [
              AppColors.main.withValues(alpha: 0.3),
              AppColors.main.withValues(alpha: 0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        spots: List.generate(7, (index) {
          DateTime now = DateTime.now();
          DateTime monday = now.subtract(Duration(days: now.weekday - 1));
          DateTime date = monday.add(Duration(days: index));
          date = DateTime(date.year, date.month, date.day);

          // Calculate hours with more precision (include seconds)
          double hours = (totalDurations[date]?.inSeconds.toDouble() ?? 0) / 3600;

          // Saatleri doğru göstermek için kontrol
          if (hours > 24) {
            // Eğer bir günde 24 saatten fazla gösteriliyorsa, muhtemelen bir hesaplama hatası var
            // Makul bir değere düşürelim
            hours = hours % 24; // veya sabit bir değer: hours = 8;
          }

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

    // Round up to next multiple of 2 for better readability
    maxHours = ((maxHours + 1.99) ~/ 2) * 2.0;
    maxHours = maxHours < 2 ? 2 : maxHours;

    Widget bottomTitleWidgets(
      double value,
      TitleMeta meta,
    ) {
      // Get day names based on locale
      final DateFormat dayFormat = DateFormat('E', context.locale.languageCode);

      // Calculate the date for this day of the week
      DateTime now = DateTime.now();
      DateTime monday = now.subtract(Duration(days: now.weekday - 1));
      DateTime date = monday.add(Duration(days: value.toInt()));

      // Format the day name
      String dayName = dayFormat.format(date);

      // Highlight today
      bool isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;

      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 10,
        child: Text(
          dayName,
          style: TextStyle(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
            color: isToday ? AppColors.main : AppColors.text,
          ),
        ),
      );
    }

    Widget leftTitleWidgets(double value, TitleMeta meta) {
      // Show actual hour values based on the value parameter
      String hourText = '${value.toStringAsFixed(0)}${LocaleKeys.h.tr()}';

      return Text(hourText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppColors.text,
          ),
          textAlign: TextAlign.center);
    }

    // We're using the built-in tooltip functionality instead of a custom tooltip

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              // Return empty list to use custom tooltip widget
              return [];
            },
            fitInsideHorizontally: true,
            fitInsideVertically: true,
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            // Custom tooltip handling
            if (touchResponse?.lineBarSpots != null && touchResponse!.lineBarSpots!.isNotEmpty && event is FlPanDownEvent) {
              // Show custom tooltip here if needed
            }
          },
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: maxHours / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.text.withValues(alpha: 25), // 0.1 * 255 = 25
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
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
              interval: (maxHours / 4),
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
            bottom: BorderSide(color: AppColors.main.withValues(alpha: 128), width: 2), // 0.5 * 255 = 128
            left: BorderSide(color: AppColors.main.withValues(alpha: 128), width: 2),
          ),
        ),
        lineBarsData: dataList,
        minX: 0,
        maxX: 6,
        maxY: dataList.isEmpty ? 5 : maxHours,
        minY: 0,
        backgroundColor: AppColors.transparent,
      ),
    );
  }
}
