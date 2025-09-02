import 'package:flutter/material.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/task_log_model.dart';

class ProfileViewModel extends ChangeNotifier {
  // Weekly Progress Data
  Map<int, Map<DateTime, Duration>> getSkillDurations() {
    Map<int, Map<DateTime, Duration>> skillDurations = {};

    for (var task in TaskProvider().taskList) {
      if (task.taskDate != null && task.taskDate!.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
        if (task.skillIDList != null) {
          for (var skillId in task.skillIDList!) {
            skillDurations[skillId] ??= {};

            Duration taskDuration = _calculateTaskDuration(task);
            DateTime dateKey = DateTime(task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
            skillDurations[skillId]![dateKey] = (skillDurations[skillId]![dateKey] ?? Duration.zero) + taskDuration;
          }
        }
      }
    }
    return skillDurations;
  }

  List<TraitModel> getTopSkills(BuildContext context, Map<int, Map<DateTime, Duration>> skillDurations) {
    List<TraitModel> topSkillsList = [];
    var sortedSkills = skillDurations.entries.toList()..sort((a, b) => b.value.values.fold<Duration>(Duration.zero, (p, c) => p + c).compareTo(a.value.values.fold<Duration>(Duration.zero, (p, c) => p + c)));

    for (var entry in sortedSkills.take(3)) {
      var skill = TraitProvider().traitList.firstWhere((s) => s.id == entry.key);
      topSkillsList.add(skill);
    }
    return topSkillsList;
  }

  Duration _calculateTaskDuration(task) {
    return task.type == TaskTypeEnum.CHECKBOX
        ? (task.status == TaskStatusEnum.DONE ? task.remainingDuration! : Duration.zero)
        : task.type == TaskTypeEnum.COUNTER
            ? task.remainingDuration! * task.currentCount!
            : task.currentDuration!;
  }

  // Best Days Analysis Data
  Map<String, dynamic> getBestDayAnalysis() {
    Map<int, Duration> dayTotals = {};
    Map<int, int> dayCount = {};

    for (var task in TaskProvider().taskList) {
      if (task.taskDate != null) {
        // TODO: belki burada -1 yazmak doğru olur. verileri kontrol et
        int weekday = task.taskDate!.weekday;
        Duration taskDuration = task.remainingDuration ?? Duration.zero;

        dayTotals[weekday] = (dayTotals[weekday] ?? Duration.zero) + taskDuration;
        dayCount[weekday] = (dayCount[weekday] ?? 0) + 1;
      }
    }

    int bestDay = 1;
    Duration bestAverage = Duration.zero;

    for (var entry in dayTotals.entries) {
      Duration average = entry.value ~/ dayCount[entry.key]!;
      if (average > bestAverage) {
        bestAverage = average;
        bestDay = entry.key;
      }
    }

    return {
      'bestDay': bestDay,
      'bestAverage': bestAverage,
    };
  }

  // Streak Analysis Data
  Map<String, int> getStreakAnalysis() {
    final streakSettings = StreakSettingsProvider();
    final vacationMode = VacationModeProvider();

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastProcessedDate;

    // Get all task logs and calculate daily durations
    Map<DateTime, Duration> dailyDurations = _calculateDailyDurations();

    // Sort dates in descending order (newest first)
    List<DateTime> sortedDates = dailyDurations.keys.toList()..sort((a, b) => b.compareTo(a));

    // Process each day to calculate streaks
    for (DateTime date in sortedDates) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final dayDuration = dailyDurations[dateOnly] ?? Duration.zero;
      final minimumHours = streakSettings.streakMinimumHours;

      // Check if this day counts for streak
      bool dayCountsForStreak = false;

      if (streakSettings.isVacationDay(dateOnly)) {
        // Vacation days always count for streak
        dayCountsForStreak = true;
      } else if (vacationMode.isVacationModeEnabled) {
        // If vacation mode is active, all days count for streak
        dayCountsForStreak = true;
      } else {
        // Normal day - check if minimum hours requirement is met
        final hoursWorked = dayDuration.inMinutes / 60.0;
        dayCountsForStreak = hoursWorked >= minimumHours;
      }

      if (dayCountsForStreak) {
        if (lastProcessedDate == null || dateOnly.difference(lastProcessedDate).inDays.abs() == 1) {
          // Consecutive day
          tempStreak++;
        } else if (dateOnly.difference(lastProcessedDate).inDays.abs() > 1) {
          // Gap in streak, reset
          tempStreak = 1;
        }
        lastProcessedDate = dateOnly;

        // Update longest streak
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }

        // Update current streak if this date is recent
        final daysSinceDate = DateTime.now().difference(dateOnly).inDays;
        if (daysSinceDate <= 1) {
          currentStreak = tempStreak;
        } else if (daysSinceDate == 2) {
          // Check if yesterday was covered by vacation/pass/holiday mode
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final yesterdayOnly = DateTime(yesterday.year, yesterday.month, yesterday.day);

          if (streakSettings.isVacationDay(yesterdayOnly) || vacationMode.isVacationModeEnabled) {
            currentStreak = tempStreak;
          }
        }
      } else {
        // Day doesn't count for streak
        if (lastProcessedDate != null && dateOnly.difference(lastProcessedDate).inDays.abs() == 1) {
          // Reset streak if this was supposed to be a consecutive day
          tempStreak = 0;
        }

        // Check if this affects current streak
        final daysSinceDate = DateTime.now().difference(dateOnly).inDays;
        if (daysSinceDate == 1) {
          // Yesterday didn't meet requirements, current streak is broken
          currentStreak = 0;
        }
      }
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  /// Calculate daily work durations based on task logs
  Map<DateTime, Duration> _calculateDailyDurations() {
    Map<DateTime, Duration> dailyDurations = {};
    List<TaskLogModel> allLogs = TaskLogProvider().taskLogList;

    for (var log in allLogs) {
      DateTime dateKey = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      dailyDurations[dateKey] ??= Duration.zero;

      if (log.duration != null) {
        // Timer tasks
        dailyDurations[dateKey] = dailyDurations[dateKey]! + log.duration!;
      } else if (log.count != null && log.count! > 0) {
        // Counter tasks
        try {
          var task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
          if (task.remainingDuration != null) {
            Duration countDuration = task.remainingDuration! * log.count!;
            dailyDurations[dateKey] = dailyDurations[dateKey]! + countDuration;
          }
        } catch (_) {}
      } else if (log.status == TaskStatusEnum.DONE) {
        // Checkbox tasks
        try {
          var task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
          if (task.remainingDuration != null) {
            dailyDurations[dateKey] = dailyDurations[dateKey]! + task.remainingDuration!;
          }
        } catch (_) {}
      }
    }

    return dailyDurations;
  }

  // Get total durations for all tasks based on logs for the current week
  Map<DateTime, Duration> getTotalTaskDurations() {
    Map<DateTime, Duration> totalDurations = {};

    // Get all logs
    List<TaskLogModel> allLogs = TaskLogProvider().taskLogList;

    // Calculate the start of the current week (Monday)
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    monday = DateTime(monday.year, monday.month, monday.day);

    // Calculate the end of the current week (Sunday)
    DateTime sunday = monday.add(const Duration(days: 6));
    sunday = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

    // Filter logs for the current week
    List<TaskLogModel> weekLogs = allLogs.where((log) {
      return log.logDate.isAfter(monday.subtract(const Duration(seconds: 1))) && log.logDate.isBefore(sunday.add(const Duration(seconds: 1)));
    }).toList();

    // Her görev için bir kez işlenmesini sağlamak için
    Set<String> processedTaskDates = {};

    // Process logs to calculate durations
    for (var log in weekLogs) {
      // Get the date part only
      DateTime dateKey = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      String taskDateKey = "${log.taskId}_${dateKey.toIso8601String()}";

      // Initialize if not exists
      totalDurations[dateKey] ??= Duration.zero;

      // Add duration based on log type
      if (log.duration != null) {
        // Timer task - timer logları direkt olarak süreyi içerir
        totalDurations[dateKey] = totalDurations[dateKey]! + log.duration!;
      } else if (log.count != null && log.count! > 0) {
        // Counter task - try to find the task to get the duration per count
        try {
          var task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
          if (task.remainingDuration != null) {
            // Her bir sayım için görevin süresini ekle (bir görev için günlük toplam)
            Duration countDuration = task.remainingDuration!;
            // Süreyi eklerken çok büyük değerler oluşmaması için kontrol
            if (log.count! <= 100) {
              // Makul bir üst sınır
              totalDurations[dateKey] = totalDurations[dateKey]! + (countDuration * log.count!);
            } else {
              // Çok büyük değerler için makul bir süre ekle
              totalDurations[dateKey] = totalDurations[dateKey]! + (countDuration * 5);
            }
          }
        } catch (e) {
          // Task might have been deleted, skip
        }
      } else if (log.status == TaskStatusEnum.DONE) {
        // Checkbox task - her tamamlanan görev için bir kez süre ekle
        // Aynı görev için aynı günde birden fazla log olabilir, bu yüzden kontrol ediyoruz
        if (!processedTaskDates.contains(taskDateKey)) {
          try {
            var task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
            if (task.remainingDuration != null) {
              totalDurations[dateKey] = totalDurations[dateKey]! + task.remainingDuration!;
              processedTaskDates.add(taskDateKey);
            }
          } catch (e) {
            // Task might have been deleted, skip
          }
        }
      }
    }

    return totalDurations;
  }
}
