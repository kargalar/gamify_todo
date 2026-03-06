import 'package:flutter/foundation.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/task_log_model.dart';

@immutable
class TaskStreakStats {
  const TaskStreakStats({
    required this.totalDays,
    required this.completedDays,
    required this.completionPercentage,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int totalDays;
  final int completedDays;
  final double completionPercentage;
  final int currentStreak;
  final int longestStreak;

  static const empty = TaskStreakStats(
    totalDays: 0,
    completedDays: 0,
    completionPercentage: 0,
    currentStreak: 0,
    longestStreak: 0,
  );
}

class TaskStreakHelper {
  const TaskStreakHelper._();

  static TaskStreakStats calculateStats(
    List<TaskLogModel> logs, {
    DateTime? anchorDate,
  }) {
    final meaningfulLogs = logs.where((log) {
      if (log.status == TaskStatusEnum.ARCHIVED) {
        return false;
      }

      return log.duration != null || log.count != null || log.status != null;
    }).toList();

    if (meaningfulLogs.isEmpty) {
      return TaskStreakStats.empty;
    }

    final Map<DateTime, bool> dailyCompletion = {};
    for (final log in meaningfulLogs) {
      dailyCompletion[_normalize(log.logDate)] = true;
    }

    final sortedDates = dailyCompletion.keys.toList()..sort();
    if (sortedDates.isEmpty) {
      return TaskStreakStats.empty;
    }

    final firstDate = sortedDates.first;
    final lastDate = sortedDates.last;
    final totalDays = lastDate.difference(firstDate).inDays + 1;
    final completedDays = dailyCompletion.length;
    final percentage = (completedDays / totalDays * 100).clamp(0, 100).toDouble();

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final today = _normalize(DateTime.now());
    var effectiveAnchor = _normalize(anchorDate ?? today);
    if (effectiveAnchor.isAfterDay(today)) {
      effectiveAnchor = today;
    }

    var checkDate = effectiveAnchor;
    while (dailyCompletion.containsKey(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

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

    return TaskStreakStats(
      totalDays: totalDays,
      completedDays: completedDays,
      completionPercentage: percentage,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
