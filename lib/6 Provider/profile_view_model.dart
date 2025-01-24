import 'package:flutter/material.dart';
import 'package:gamify_todo/6%20Provider/task_provider.dart';
import 'package:gamify_todo/6%20Provider/trait_provider.dart';
import 'package:gamify_todo/7%20Enum/task_status_enum.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:gamify_todo/8%20Model/trait_model.dart';

class ProfileViewModel extends ChangeNotifier {
  // Weekly Progress Data
  Map<int, Map<DateTime, Duration>> getSkillDurations() {
    Map<int, Map<DateTime, Duration>> skillDurations = {};

    for (var task in TaskProvider().taskList) {
      if (task.taskDate.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
        if (task.skillIDList != null) {
          for (var skillId in task.skillIDList!) {
            skillDurations[skillId] ??= {};

            Duration taskDuration = _calculateTaskDuration(task);
            DateTime dateKey = DateTime(task.taskDate.year, task.taskDate.month, task.taskDate.day);
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
        ? (task.status == TaskStatusEnum.COMPLETED ? task.remainingDuration! : Duration.zero)
        : task.type == TaskTypeEnum.COUNTER
            ? task.remainingDuration! * task.currentCount!
            : task.currentDuration!;
  }

  // Best Days Analysis Data
  Map<String, dynamic> getBestDayAnalysis() {
    Map<int, Duration> dayTotals = {};
    Map<int, int> dayCount = {};

    for (var task in TaskProvider().taskList) {
      // TODO: belki burada -1 yazmak doğru olur. verileri kontrol et
      int weekday = task.taskDate.weekday;
      Duration taskDuration = task.remainingDuration!;

      dayTotals[weekday] = (dayTotals[weekday] ?? Duration.zero) + taskDuration;
      dayCount[weekday] = (dayCount[weekday] ?? 0) + 1;
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
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    var sortedTasks = TaskProvider().taskList.toList()..sort((a, b) => b.taskDate.compareTo(a.taskDate));

    for (var task in sortedTasks) {
      if (task.status == TaskStatusEnum.COMPLETED) {
        if (lastDate == null || task.taskDate.difference(lastDate).inDays == 1) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
        lastDate = task.taskDate;

        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

        if (DateTime.now().difference(task.taskDate).inDays <= 1) {
          currentStreak = tempStreak;
        }
      }
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  // Get total durations for all tasks (including tasks without traits)
  Map<DateTime, Duration> getTotalTaskDurations() {
    Map<DateTime, Duration> totalDurations = {};

    for (var task in TaskProvider().taskList) {
      if (task.status == TaskStatusEnum.COMPLETED) {
        DateTime date = DateTime(task.taskDate.year, task.taskDate.month, task.taskDate.day);
        Duration duration = _calculateTaskDuration(task);
        totalDurations[date] = (totalDurations[date] ?? Duration.zero) + duration;
      }
    }

    return totalDurations;
  }
}
