import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

/// Progress summary card for trait details
class TraitProgressSummary extends StatelessWidget {
  final TraitModel traitModel;
  final Color selectedColor;
  final Duration totalDuration;

  const TraitProgressSummary({
    super.key,
    required this.traitModel,
    required this.selectedColor,
    required this.totalDuration,
  });

  Map<String, dynamic> _calculateStats() {
    final now = DateTime.now();

    // This week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));

    // This month
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // This year
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);

    Duration weekDuration = Duration.zero;
    Duration monthDuration = Duration.zero;
    Duration yearDuration = Duration.zero;
    int totalSessions = 0;

    final allLogs = TaskLogProvider().taskLogList;

    for (final log in allLogs) {
      final task = TaskProvider().taskList.firstWhere(
            (t) => t.id == log.id,
            orElse: () => TaskProvider().taskList.first,
          );

      final hasTrait = (task.attributeIDList?.contains(traitModel.id) ?? false) || (task.skillIDList?.contains(traitModel.id) ?? false);

      if (hasTrait) {
        totalSessions++;
        final duration = log.duration ?? Duration.zero;

        if (log.logDate.isAfter(weekStart) && log.logDate.isBefore(weekEnd)) {
          weekDuration += duration;
        }
        if (log.logDate.isAfter(monthStart) && log.logDate.isBefore(monthEnd)) {
          monthDuration += duration;
        }
        if (log.logDate.isAfter(yearStart) && log.logDate.isBefore(yearEnd)) {
          yearDuration += duration;
        }
      }
    }

    return {
      'week': weekDuration,
      'month': monthDuration,
      'year': yearDuration,
      'sessions': totalSessions,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final weekDuration = stats['week'] as Duration;
    final monthDuration = stats['month'] as Duration;
    final yearDuration = stats['year'] as Duration;
    final totalSessions = stats['sessions'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            selectedColor.withOpacity(0.2),
            selectedColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  traitModel.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalSessions ${LocaleKeys.Sessions.tr()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.text.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  LocaleKeys.WeeklyLabel.tr(),
                  weekDuration.textShort2hour(),
                  Icons.calendar_view_week,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  LocaleKeys.MonthlyLabel.tr(),
                  monthDuration.textShort2hour(),
                  Icons.calendar_month,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  LocaleKeys.YearlyLabel.tr(),
                  yearDuration.textShort2hour(),
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  LocaleKeys.AllTime.tr(),
                  totalDuration.textShort2hour(),
                  Icons.all_inclusive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: selectedColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.text.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
