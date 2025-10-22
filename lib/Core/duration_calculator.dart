import 'package:flutter/foundation.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';

/// DurationCalculator handles all duration-related calculations for HomeViewModel.
/// It aggregates durations from task logs, running timers, and provides breakdowns.
class DurationCalculator {
  /// Calculate total duration logged for the given date.
  /// Sums up durations from task logs and includes running timers' currentDuration.
  static Duration calculateTotalDurationForDate(DateTime date) {
    debugPrint('DurationCalculator: Calculating total duration for date: $date');

    // Aggregate from logs
    final logs = TaskLogProvider().taskLogList;
    Duration total = Duration.zero;

    // For checkbox tasks, ensure per-day uniqueness
    final Set<String> processedTaskDates = {};

    // Map to accumulate durations per task for counter tasks
    final Map<int, int> counterTaskCounts = {};

    for (final log in logs) {
      if (!(log.logDate.year == date.year && log.logDate.month == date.month && log.logDate.day == date.day)) continue;

      try {
        final task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);

        if (log.duration != null) {
          total += log.duration!;
          debugPrint('DurationCalculator: Added log duration: ${log.duration!.compactFormat()} for task ${task.title}');
        } else if (log.count != null && log.count! > 0) {
          if (task.remainingDuration != null) {
            final count = log.count! <= 100 ? log.count! : 5;
            final add = task.remainingDuration! * count;
            total += add;
            debugPrint('DurationCalculator: Added log count: $count * ${task.remainingDuration!.compactFormat()} = ${add.compactFormat()} for task ${task.title}');

            // For counter tasks, accumulate counts for breakdown
            if (task.type == TaskTypeEnum.COUNTER) {
              counterTaskCounts[task.id] = (counterTaskCounts[task.id] ?? 0) + count;
            }
          }
        } else if (log.status == null || log.status == TaskStatusEnum.DONE) {
          // Treat as checkbox DONE if applicable
          String key = "${log.taskId}_${log.logDate.year}-${log.logDate.month}-${log.logDate.day}";
          if (!processedTaskDates.contains(key)) {
            if (task.remainingDuration != null && log.status == TaskStatusEnum.DONE) {
              total += task.remainingDuration!;
              debugPrint('DurationCalculator: Added checkbox duration: ${task.remainingDuration!.compactFormat()} for task ${task.title}');
            }
            processedTaskDates.add(key);
          }
        }
      } catch (e) {
        debugPrint('DurationCalculator: Error processing log for task ${log.taskId}: $e');
      }
    }

    // Add running timers for tasks that are active on the date
    for (final task in TaskProvider().taskList) {
      if (task.isTimerActive == true && task.taskDate != null && task.taskDate!.isSameDay(date)) {
        total += task.currentDuration ?? Duration.zero;
        debugPrint('DurationCalculator: Added running timer: ${(task.currentDuration ?? Duration.zero).compactFormat()} for task ${task.title}');
      }
    }

    debugPrint('DurationCalculator: Total duration calculated: ${total.compactFormat()}');
    return total;
  }

  /// Get breakdown of contributions for the given date: list of maps with title and duration.
  static List<Map<String, dynamic>> getContributionsForDate(DateTime date) {
    debugPrint('DurationCalculator: Calculating contributions for date: $date');

    final Map<int, Duration> perTask = {};
    final Set<String> processedTaskDates = {};
    final Map<int, int> counterTaskCounts = {};

    // Aggregate logs for the date
    for (final log in TaskLogProvider().taskLogList) {
      if (!log.logDate.isSameDay(date)) continue;
      final int taskId = log.taskId;
      TaskModel? task;
      try {
        task = TaskProvider().taskList.firstWhere((x) => x.id == taskId);
      } catch (_) {
        continue;
      }
      Duration add = Duration.zero;
      if (log.duration != null) {
        add = log.duration!;
      } else if (log.count != null && log.count! > 0) {
        final per = task.remainingDuration ?? Duration.zero;
        final count = log.count! <= 100 ? log.count! : 5;
        add = per * count;

        if (task.type == TaskTypeEnum.COUNTER) {
          counterTaskCounts[task.id] = (counterTaskCounts[task.id] ?? 0) + count;
        }
      } else if (log.status == null || log.status == TaskStatusEnum.DONE) {
        add = task.remainingDuration ?? Duration.zero;
        // For checkbox, ensure uniqueness
        String key = "${taskId}_${log.logDate.year}-${log.logDate.month}-${log.logDate.day}";
        if (processedTaskDates.contains(key)) {
          add = Duration.zero; // Already processed
        } else {
          processedTaskDates.add(key);
        }
      }

      if (add > Duration.zero) {
        perTask[taskId] = (perTask[taskId] ?? Duration.zero) + add;
      }
    }

    // Include running timers for tasks scheduled on the date
    for (final t in TaskProvider().taskList) {
      if (t.isTimerActive == true && t.taskDate != null && t.taskDate!.isSameDay(date)) {
        perTask[t.id] = (perTask[t.id] ?? Duration.zero) + (t.currentDuration ?? Duration.zero);
      }
    }

    // Build list of contributions with titles
    final List<Map<String, dynamic>> list = [];
    perTask.forEach((taskId, duration) {
      try {
        final task = TaskProvider().taskList.firstWhere((t) => t.id == taskId);
        list.add({'title': task.title, 'duration': duration, 'task': task});
      } catch (_) {}
    });

    // Sort descending by duration
    list.sort((a, b) => (b['duration'] as Duration).compareTo(a['duration'] as Duration));
    debugPrint('DurationCalculator: Contributions calculated with ${list.length} items');
    return list;
  }

  /// Calculate today's target duration.
  static Duration calculateTodayTargetDuration(DateTime selectedDate) {
    Duration target = Duration.zero;
    final tasks = TaskProvider().taskList.where((t) => t.taskDate != null && t.taskDate!.isSameDay(selectedDate)).toList();
    for (final t in tasks) {
      if (t.remainingDuration != null) {
        if (t.type == TaskTypeEnum.COUNTER && t.targetCount != null) {
          target += t.remainingDuration! * t.targetCount!;
        } else {
          target += t.remainingDuration!;
        }
      }
    }

    if (target > Duration.zero) return target;

    // Fallback to streak minimum hours
    final double hours = StreakSettingsProvider().streakMinimumHours;
    if (hours > 0) return Duration(minutes: (hours * 60).toInt());

    return const Duration(hours: 1);
  }

  /// Calculate if the streak target was met for a given date
  static bool calculateStreakStatusForDate(DateTime date) {
    final totalDuration = calculateTotalDurationForDate(date);
    final targetDuration = calculateTodayTargetDuration(date);
    return totalDuration >= targetDuration;
  }

  /// Get streak status for the last 5 days, today, and tomorrow
  static List<Map<String, dynamic>> getStreakStatuses() {
    debugPrint('DurationCalculator: Getting streak statuses');
    final now = DateTime.now();
    final dates = [
      now.subtract(const Duration(days: 5)),
      now.subtract(const Duration(days: 4)),
      now.subtract(const Duration(days: 3)),
      now.subtract(const Duration(days: 2)),
      now.subtract(const Duration(days: 1)),
      now, // today
      now.add(const Duration(days: 1)), // tomorrow
    ];

    return dates.map((date) {
      final isFuture = date.isAfter(now);
      final isVacation = _isVacationDay(date);
      final isMet = isFuture || isVacation ? null : calculateStreakStatusForDate(date);
      debugPrint('DurationCalculator: Date ${date.toIso8601String()}, isFuture: $isFuture, isVacation: $isVacation, isMet: $isMet');
      return {
        'date': date,
        'isMet': isMet,
        'dayName': _getDayName(date),
        'isFuture': isFuture,
        'isVacation': isVacation,
      };
    }).toList();
  }

  static bool _isVacationDay(DateTime date) {
    final vacationWeekdays = StreakSettingsProvider().vacationWeekdays;
    // weekday: 1 = Monday, 2 = Tuesday, ..., 7 = Sunday
    // Convert to 0-based index for our Set (0 = Monday, 1 = Tuesday, ..., 6 = Sunday)
    final weekdayIndex = date.weekday - 1;
    return vacationWeekdays.contains(weekdayIndex);
  }

  static String _getDayName(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Bugün';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return 'Yarın';
    } else {
      final weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return weekdays[date.weekday - 1];
    }
  }
}
