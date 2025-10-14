import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/profile_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/task_log_model.dart';

// This chart shows total weekly progress for all tasks combined
// Displays total time spent on all tasks per day
// Data shows a single line representing total work time per day

enum ProgressPeriod { week, month, year }

class WeeklyTotalProgressChart extends StatefulWidget {
  const WeeklyTotalProgressChart({super.key});

  @override
  State<StatefulWidget> createState() => _WeeklyTotalProgressChartState();
}

class _WeeklyTotalProgressChartState extends State<WeeklyTotalProgressChart> {
  ProgressPeriod _period = ProgressPeriod.week;

  Map<DateTime, Duration> _aggregateDaily(DateTime start, DateTime endInclusive) {
    Map<DateTime, Duration> totals = {};
    List<TaskLogModel> logs = TaskLogProvider().taskLogList;
    Set<String> processedTaskDates = {};
    for (var log in logs) {
      if (log.logDate.isBefore(start) || log.logDate.isAfter(endInclusive)) continue;
      DateTime dateKey = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      String taskDateKey = "${log.taskId}_${dateKey.toIso8601String()}";
      totals[dateKey] ??= Duration.zero;
      if (log.duration != null) {
        totals[dateKey] = totals[dateKey]! + log.duration!;
      } else if (log.count != null && log.count! > 0) {
        try {
          var task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
          if (task.remainingDuration != null) {
            Duration countDuration = task.remainingDuration!;
            totals[dateKey] = totals[dateKey]! + (countDuration * (log.count! <= 100 ? log.count! : 5));
          }
        } catch (_) {}
      } else if (log.status == TaskStatusEnum.DONE) {
        if (!processedTaskDates.contains(taskDateKey)) {
          try {
            var task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
            if (task.remainingDuration != null) {
              totals[dateKey] = totals[dateKey]! + task.remainingDuration!;
              processedTaskDates.add(taskDateKey);
            }
          } catch (_) {}
        }
      }
    }
    return totals;
  }

  Map<DateTime, Duration> _weeklyData() {
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    monday = DateTime(monday.year, monday.month, monday.day);
    DateTime sunday = monday.add(const Duration(days: 6));
    return _aggregateDaily(monday, DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59));
  }

  Map<DateTime, Duration> _monthlyData() {
    DateTime now = DateTime.now();
    DateTime first = DateTime(now.year, now.month, 1);
    DateTime last = DateTime(now.year, now.month + 1, 0);
    return _aggregateDaily(first, DateTime(last.year, last.month, last.day, 23, 59, 59));
  }

  Map<DateTime, Duration> _yearlyMonthlyData() {
    DateTime now = DateTime.now();
    Map<DateTime, Duration> monthTotals = {};
    List<TaskLogModel> logs = TaskLogProvider().taskLogList;
    Set<String> processedTaskMonth = {};
    for (var log in logs) {
      if (log.logDate.year != now.year) continue;
      DateTime monthKey = DateTime(log.logDate.year, log.logDate.month, 1);
      monthTotals[monthKey] ??= Duration.zero;
      if (log.duration != null) {
        monthTotals[monthKey] = monthTotals[monthKey]! + log.duration!;
      } else if (log.count != null && log.count! > 0) {
        try {
          var task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
          if (task.remainingDuration != null) {
            Duration countDuration = task.remainingDuration!;
            monthTotals[monthKey] = monthTotals[monthKey]! + (countDuration * (log.count! <= 100 ? log.count! : 5));
          }
        } catch (_) {}
      } else if (log.status == TaskStatusEnum.DONE) {
        String taskMonthKey = "${log.taskId}_${monthKey.toIso8601String()}";
        if (!processedTaskMonth.contains(taskMonthKey)) {
          try {
            var task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
            if (task.remainingDuration != null) {
              monthTotals[monthKey] = monthTotals[monthKey]! + task.remainingDuration!;
              processedTaskMonth.add(taskMonthKey);
            }
          } catch (_) {}
        }
      }
    }
    for (int m = 1; m <= 12; m++) {
      monthTotals.putIfAbsent(DateTime(now.year, m, 1), () => Duration.zero);
    }
    return monthTotals;
  }

  Map<DateTime, Duration> _currentData() {
    switch (_period) {
      case ProgressPeriod.week:
        return _weeklyData();
      case ProgressPeriod.month:
        return _monthlyData();
      case ProgressPeriod.year:
        return _yearlyMonthlyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // keep viewModel read for potential future use
    context.read<ProfileViewModel>();
    final totalDurations = _currentData();
    Duration totalDuration = totalDurations.values.fold(Duration.zero, (p, c) => p + c);
    // Saniyeleri kaldır: sadece saat ve dakika (veya sadece dakika)
    final int h = totalDuration.inHours;
    final int m = totalDuration.inMinutes.remainder(60);
    String durationText = h > 0 ? "$h${LocaleKeys.h.tr()} $m${LocaleKeys.m.tr()}" : "$m${LocaleKeys.m.tr()}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.main.withValues(alpha: 0.8),
            AppColors.main.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.main.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _period == ProgressPeriod.week
                        ? LocaleKeys.WeeklyLabel.tr()
                        : _period == ProgressPeriod.month
                            ? LocaleKeys.MonthlyLabel.tr()
                            : LocaleKeys.YearlyLabel.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    durationText,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _PeriodSwitcher(period: _period, onChanged: (p) => setState(() => _period = p)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: _ProgressBarChart(period: _period, data: totalDurations),
          ),
        ],
      ),
    );
  }
}

class _PeriodSwitcher extends StatelessWidget {
  final ProgressPeriod period;
  final ValueChanged<ProgressPeriod> onChanged;
  const _PeriodSwitcher({required this.period, required this.onChanged});

  Widget _btn(String label, ProgressPeriod p) {
    final bool selected = period == p;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => onChanged(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected ? AppColors.main : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(LocaleKeys.WeeklyLabel.tr(), ProgressPeriod.week),
        const SizedBox(width: 4),
        _btn(LocaleKeys.MonthlyLabel.tr(), ProgressPeriod.month),
        const SizedBox(width: 4),
        _btn(LocaleKeys.YearlyLabel.tr(), ProgressPeriod.year),
      ],
    );
  }
}

class _ProgressBarChart extends StatelessWidget {
  final ProgressPeriod period;
  final Map<DateTime, Duration> data;
  const _ProgressBarChart({required this.period, required this.data});

  @override
  Widget build(BuildContext context) {
    double maxHours = 0;
    List<DateTime> orderedKeys = data.keys.toList()..sort();
    DateTime now = DateTime.now();
    // Mevcut ekran genişliği (aylık görünümde bar width hesaplamak için)
    final double screenWidth = MediaQuery.of(context).size.width;
    double dynamicMonthBarWidth = 10; // default
    double dynamicMonthGroupSpace = 2; // default
    // Aylık görünümde etiketler: ilk gün, son gün ve her 3. gün
    if (period == ProgressPeriod.week) {
      DateTime monday = now.subtract(Duration(days: now.weekday - 1));
      orderedKeys = List.generate(7, (i) {
        final d = monday.add(Duration(days: i));
        return DateTime(d.year, d.month, d.day);
      });
    } else if (period == ProgressPeriod.month) {
      int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      orderedKeys = List.generate(daysInMonth, (i) => DateTime(now.year, now.month, i + 1));
      // Günlük barların hepsini tek ekrana sığdırmak için yaklaşık kullanılabilir genişlikten padding düş.
      // Container dış padding: sağ 16 sol 6 + parent 8 civarı => güvenli margin çıkar.
      double horizontalPadding = 32; // tahmini toplam boşluk
      double available = (screenWidth - horizontalPadding).clamp(200, 1600);
      // groupsSpace'i minimal tutup barWidth hesapla:
      dynamicMonthGroupSpace = 1.0;
      double rawWidth = (available - (daysInMonth - 1) * dynamicMonthGroupSpace) / daysInMonth;
      // Makul sınırlar
      dynamicMonthBarWidth = rawWidth.clamp(4.0, 14.0);
    } else {
      orderedKeys = List.generate(12, (i) => DateTime(now.year, i + 1, 1));
    }

    List<BarChartGroupData> groups = [];
    for (int i = 0; i < orderedKeys.length; i++) {
      final date = orderedKeys[i];
      double hours = (data[date]?.inSeconds.toDouble() ?? 0) / 3600;
      if (hours > 24) hours = hours % 24;
      if (hours > maxHours) maxHours = hours;
      bool isToday = date.day == now.day && date.month == now.month && date.year == now.year;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hours,
              width: period == ProgressPeriod.month ? dynamicMonthBarWidth : 18,
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: isToday ? [Colors.white, Colors.white.withValues(alpha: 0.9)] : [Colors.white.withValues(alpha: 0.7), Colors.white.withValues(alpha: 0.5)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            )
          ],
        ),
      );
    }

    Widget bottomTitle(double value, TitleMeta meta) {
      final int index = value.toInt();
      if (index < 0 || index >= orderedKeys.length) return const SizedBox();
      DateTime date = orderedKeys[index];
      bool isToday = date.day == now.day && date.month == now.month && date.year == now.year;
      String label;
      if (period == ProgressPeriod.week) {
        label = DateFormat('E', context.locale.languageCode).format(date);
      } else if (period == ProgressPeriod.month) {
        bool isFirst = index == 0;
        bool isLast = index == orderedKeys.length - 1;
        bool show = isFirst || isLast || isToday || (index % 3 == 0);
        if (!isToday) {
          // Bugünün yanındaki günler gösterilmesin (en az 1 gün boşluk)
          final todayIndex = orderedKeys.indexWhere((d) => d.day == now.day && d.month == now.month && d.year == now.year);
          if (todayIndex != -1 && (index == todayIndex - 1 || index == todayIndex + 1)) {
            // İlk/son hariç komşu günleri gizle
            if (!isFirst && !isLast) show = false;
          }
        }
        if (!show) return const SizedBox();
        label = date.day.toString();
      } else {
        label = DateFormat('MMM', context.locale.languageCode).format(date);
      }
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: period == ProgressPeriod.year ? 14 : 8,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: period == ProgressPeriod.year ? 10 : 11,
            color: isToday ? Colors.white : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    Widget leftTitle(double value, TitleMeta meta) {
      int hours = value.round();
      return Text(
        '$hours${LocaleKeys.h.tr()}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.white,
        ),
      );
    }

    final chart = BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              DateTime date = orderedKeys[group.x.toInt()];
              final dateFormat = DateFormat(period == ProgressPeriod.year ? 'MMM yyyy' : 'EEE, d MMM', context.locale.languageCode);
              final dateStr = dateFormat.format(date);
              final duration = data[period == ProgressPeriod.year ? DateTime(date.year, date.month, 1) : DateTime(date.year, date.month, date.day)] ?? Duration.zero;
              return BarTooltipItem(
                '$dateStr\n${duration.textShort2hour()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
            tooltipMargin: 8,
            tooltipPadding: const EdgeInsets.all(8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: bottomTitle,
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: leftTitle,
              interval: maxHours <= 4 ? 1 : (maxHours / 4),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Colors.white, width: 2),
            left: BorderSide(color: Colors.white, width: 2),
          ),
        ),
        barGroups: groups,
        maxY: maxHours,
        minY: 0,
        alignment: period == ProgressPeriod.month ? BarChartAlignment.start : BarChartAlignment.spaceAround,
        groupsSpace: period == ProgressPeriod.month ? dynamicMonthGroupSpace : 4,
      ),
    );
    return chart;
  }
}
