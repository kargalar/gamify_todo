import 'package:flutter/material.dart';
import 'package:next_level/Core/duration_calculator.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class StreakCalendarDialog extends StatefulWidget {
  final HomeViewModel vm;

  const StreakCalendarDialog({super.key, required this.vm});

  @override
  State<StreakCalendarDialog> createState() => _StreakCalendarDialogState();
}

class _StreakCalendarDialogState extends State<StreakCalendarDialog> {
  late DateTime _currentYear;
  late int _minYear;
  late int _maxYear;
  late DateTime _minDate;

  @override
  void initState() {
    super.initState();
    _calculateDateRange();
    _currentYear = DateTime.now();
  }

  void _calculateDateRange() {
    final logs = TaskLogProvider().taskLogList;
    if (logs.isEmpty) {
      final now = DateTime.now();
      _minDate = DateTime(now.year, 1, 1);
      _minYear = now.year;
      _maxYear = now.year;
      return;
    }

    DateTime minDate = logs.first.logDate;
    DateTime maxDate = logs.first.logDate;

    for (final log in logs) {
      if (log.logDate.isBefore(minDate)) minDate = log.logDate;
      if (log.logDate.isAfter(maxDate)) maxDate = log.logDate;
    }

    _minDate = minDate;
    _minYear = minDate.year;
    _maxYear = maxDate.year;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: const Border(
              top: BorderSide(color: AppColors.dirtyWhite),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300]!.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'StreakCalendar'.tr(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Year Navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentYear.year > _minYear
                          ? () {
                              setState(() {
                                _currentYear = DateTime(_currentYear.year - 1);
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${_currentYear.year}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: _currentYear.year < _maxYear
                          ? () {
                              setState(() {
                                _currentYear = DateTime(_currentYear.year + 1);
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              // Calendar Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildYearlyCalendarGrid(_currentYear),
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Colors.green, 'Reached'.tr()),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.red, 'Missed'.tr()),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.orange, 'Vacation'.tr()),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.blue, 'Upcoming'.tr()),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.grey, 'NoData'.tr()),
                  ],
                ),
              ),

              // Statistics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildYearlyStatistics(_currentYear),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearlyCalendarGrid(DateTime year) {
    final daysInYear = DateTime(year.year + 1, 1, 1).difference(DateTime(year.year, 1, 1)).inDays;
    final crossAxisCount = (daysInYear / 16).ceil(); // Bir sütunda 9 kare

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: daysInYear,
      itemBuilder: (context, index) {
        final date = DateTime(year.year, 1, 1).add(Duration(days: index));
        final now = DateTime.now();
        final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
        final isVacation = DurationCalculator.isVacationDay(date);
        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
        final isBeforeMinDate = date.isBefore(_minDate);

        Color statusColor;

        if (isBeforeMinDate) {
          statusColor = Colors.grey;
        } else if (isFuture) {
          statusColor = Colors.blue;
        } else if (isVacation) {
          statusColor = Colors.orange;
        } else {
          try {
            final isMet = DurationCalculator.calculateStreakStatusForDate(date);
            statusColor = isMet ? Colors.green : Colors.red;
          } catch (e) {
            statusColor = Colors.grey;
          }
        }

        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isToday ? AppColors.green : statusColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(1),
            border: isToday ? Border.all(color: AppColors.white, width: 1) : null,
          ),
        );
      },
    );
  }

  Widget _buildYearlyStatistics(DateTime year) {
    final now = DateTime.now();
    final startOfYear = DateTime(year.year, 1, 1);
    final endOfYear = DateTime(year.year + 1, 1, 1).subtract(const Duration(days: 1));

    int totalDays = 0;
    int successfulDays = 0;

    for (int day = 0; day < endOfYear.difference(startOfYear).inDays + 1; day++) {
      final date = startOfYear.add(Duration(days: day));
      if (date.isAfter(DateTime(now.year, now.month, now.day)) || date.isBefore(_minDate)) continue;

      final isVacation = DurationCalculator.isVacationDay(date);
      if (isVacation) continue; // Tatil günlerini istatistiklere dahil etme

      totalDays++;
      try {
        final isMet = DurationCalculator.calculateStreakStatusForDate(date);
        if (isMet) {
          successfulDays++;
        }
      } catch (e) {
        // Veri yok
      }
    }

    final successRate = totalDays > 0 ? (successfulDays / totalDays * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            '${year.year} ${'Statistics'.tr()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Total'.tr(), '$totalDays'),
              _buildStatItem('Successful'.tr(), '$successfulDays'),
              _buildStatItem('Rate'.tr(), '%$successRate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.text)),
      ],
    );
  }
}
