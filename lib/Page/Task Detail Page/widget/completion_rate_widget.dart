import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';

/// Completion rate widget showing success percentage
class CompletionRateWidget extends StatelessWidget {
  final TaskDetailViewModel viewModel;

  const CompletionRateWidget({
    super.key,
    required this.viewModel,
  });

  Map<String, dynamic> _calculateCompletionStats() {
    final logs = viewModel.taskModel.routineID != null ? TaskLogProvider().getLogsByRoutineId(viewModel.taskModel.routineID!) : TaskLogProvider().getLogsByTaskId(viewModel.taskModel.id);

    if (logs.isEmpty) {
      return {
        'totalDays': 0,
        'completedDays': 0,
        'percentage': 0.0,
        'currentStreak': 0,
        'longestStreak': 0,
      };
    }

    // Group logs by date
    final Map<DateTime, bool> dailyCompletion = {};
    for (final log in logs) {
      final date = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      dailyCompletion[date] = true;
    }

    // Calculate date range
    final sortedDates = dailyCompletion.keys.toList()..sort();
    if (sortedDates.isEmpty) {
      return {
        'totalDays': 0,
        'completedDays': 0,
        'percentage': 0.0,
        'currentStreak': 0,
        'longestStreak': 0,
      };
    }

    final firstDate = sortedDates.first;
    final lastDate = sortedDates.last;
    final totalDays = lastDate.difference(firstDate).inDays + 1;
    final completedDays = dailyCompletion.length;
    final percentage = (completedDays / totalDays * 100).clamp(0, 100);

    // Calculate streaks
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate current streak (from today backwards)
    DateTime checkDate = today;
    while (dailyCompletion.containsKey(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Calculate longest streak
    for (int i = 0; i < totalDays; i++) {
      final date = firstDate.add(Duration(days: i));
      if (dailyCompletion.containsKey(date)) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    return {
      'totalDays': totalDays,
      'completedDays': completedDays,
      'percentage': percentage,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateCompletionStats();
    final percentage = stats['percentage'] as double;
    final completedDays = stats['completedDays'] as int;
    final totalDays = stats['totalDays'] as int;
    final currentStreak = stats['currentStreak'] as int;
    final longestStreak = stats['longestStreak'] as int;

    return Column(
      children: [
        // Circular progress indicator
        SizedBox(
          height: 150,
          width: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.text.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage >= 80
                        ? AppColors.green
                        : percentage >= 50
                            ? AppColors.yellow
                            : AppColors.red,
                  ),
                ),
              ),
              // Percentage text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    LocaleKeys.Completed.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              Icons.calendar_today,
              '$completedDays / $totalDays',
              LocaleKeys.Days.tr(),
            ),
            _buildStatItem(
              context,
              Icons.local_fire_department,
              '$currentStreak',
              LocaleKeys.CurrentStreak.tr(),
            ),
            _buildStatItem(
              context,
              Icons.emoji_events,
              '$longestStreak',
              LocaleKeys.LongestStreak.tr(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.main,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.text.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
