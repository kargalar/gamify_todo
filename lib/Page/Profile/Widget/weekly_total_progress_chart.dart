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
            radius: 4,
            color: AppColors.main,
            strokeWidth: 1,
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

    // Maksimum saat değerini düzgün bir sayıya yuvarla
    if (maxHours <= 1) {
      maxHours = 1.0; // 1 saat veya daha az
    } else if (maxHours <= 2) {
      maxHours = 2.0; // 1-2 saat arası
    } else if (maxHours <= 4) {
      maxHours = 4.0; // 2-4 saat arası
    } else if (maxHours <= 8) {
      maxHours = 8.0; // 4-8 saat arası
    } else if (maxHours <= 12) {
      maxHours = 12.0; // 8-12 saat arası
    } else if (maxHours <= 16) {
      maxHours = 16.0; // 12-16 saat arası
    } else if (maxHours <= 20) {
      maxHours = 20.0; // 16-20 saat arası
    } else {
      maxHours = 24.0; // 20 saatten fazla
    }

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
      // Saat değerini tam sayıya çevir
      int hours = value.round();

      // Saat metnini oluştur
      String hourText = '$hours${LocaleKeys.h.tr()}';

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
          enabled: true,
          // Dokunma hassasiyetini azalt
          touchSpotThreshold: 20,
          // Varsayılan dokunma davranışını kullan
          handleBuiltInTouches: true,
          // Tooltip özelleştirme
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                // Tarih ve süre bilgisini al
                DateTime now = DateTime.now();
                DateTime monday = now.subtract(Duration(days: now.weekday - 1));
                DateTime date = monday.add(Duration(days: barSpot.x.toInt()));
                date = DateTime(date.year, date.month, date.day);

                // Tarih formatı
                final dateFormat = DateFormat('EEE, d MMM', context.locale.languageCode);
                final dateStr = dateFormat.format(date);

                // Süre - temiz format
                final duration = totalDurations[date] ?? Duration.zero;
                // Duration extension kullanarak temiz format
                final durationStr = duration.textShort2hour();

                return LineTooltipItem(
                  "$dateStr\n$durationStr",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: maxHours <= 4 ? 1 : (maxHours / 4),
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
              interval: maxHours <= 4 ? 1 : (maxHours / 4),
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
