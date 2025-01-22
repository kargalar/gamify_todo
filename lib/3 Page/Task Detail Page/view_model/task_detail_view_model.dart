import 'package:flutter/material.dart';
import 'package:gamify_todo/1%20Core/extensions.dart';
import 'package:gamify_todo/3%20Page/Task%20Detail%20Page/widget/progress_bar.dart';
import 'package:gamify_todo/6%20Provider/task_provider.dart';
import 'package:gamify_todo/6%20Provider/trait_provider.dart';
import 'package:gamify_todo/7%20Enum/task_status_enum.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:gamify_todo/8%20Model/task_model.dart';

class TaskLog {
  final String dateTime;
  final String duration;

  TaskLog(this.dateTime, this.duration);
}

class TaskDetailViewModel {
  final TaskModel taskModel;
  Duration allTimeDuration = Duration.zero;
  int allTimeCount = 0;
  late DateTime taskRutinCreatedDate;
  List<Widget> attributeBars = [];
  List<Widget> skillBars = [];
  int completedTaskCount = 0;
  int failedTaskCount = 0;
  String bestHour = "15:00";
  String bestDay = "Wednesday";
  int longestStreak = 0;
  List<TaskLog> recentLogs = [];

  TaskDetailViewModel(this.taskModel);

  void initialize() {
    calculateStatistics();
    loadTraits();
    loadRecentLogs();
  }

  void calculateStatistics() {
    for (var task in TaskProvider().taskList) {
      if (task.routineID == taskModel.routineID) {
        if (taskModel.type == TaskTypeEnum.TIMER) {
          allTimeDuration += task.currentDuration!;
        } else if (taskModel.type == TaskTypeEnum.COUNTER) {
          allTimeCount += task.currentCount!;
        }

        if (task.status == TaskStatusEnum.COMPLETED) {
          completedTaskCount++;
        } else if (task.status == TaskStatusEnum.FAILED) {
          failedTaskCount++;
        }
      }
    }
    taskRutinCreatedDate = TaskProvider().routineList.firstWhere((element) => element.id == taskModel.routineID).createdDate;
  }

  void loadTraits() {
    if (taskModel.attributeIDList?.isNotEmpty ?? false) {
      attributeBars.addAll(
        taskModel.attributeIDList!.map((e) {
          final trait = TraitProvider().traitList.firstWhere((element) => element.id == e);

          // Calculate progress for attribute
          double progress = calculateTraitProgress(e);

          return ProgressBar(
            title: trait.title,
            progress: progress,
            color: trait.color,
            icon: trait.icon,
          );
        }),
      );
    }

    if (taskModel.skillIDList?.isNotEmpty ?? false) {
      skillBars.addAll(
        taskModel.skillIDList!.map((e) {
          final trait = TraitProvider().traitList.firstWhere((element) => element.id == e);

          // Calculate progress for skill
          double progress = calculateTraitProgress(e);

          return ProgressBar(
            title: trait.title,
            progress: progress,
            color: trait.color,
            icon: trait.icon,
          );
        }),
      );
    }
  }

  // TODO:
  double calculateTraitProgress(int traitId) {
    Duration totalDuration = Duration.zero;
    Duration completedDuration = Duration.zero;

    for (var task in TaskProvider().taskList) {
      bool hasThisTrait = (task.attributeIDList?.contains(traitId) ?? false) || (task.skillIDList?.contains(traitId) ?? false);

      if (hasThisTrait) {
        Duration taskDuration;
        if (task.type == TaskTypeEnum.TIMER) {
          taskDuration = task.remainingDuration ?? Duration.zero;
        } else if (task.type == TaskTypeEnum.COUNTER) {
          taskDuration = (task.remainingDuration ?? Duration.zero) * (task.targetCount ?? 1);
        } else {
          taskDuration = task.remainingDuration ?? Duration.zero;
        }

        totalDuration += taskDuration;

        if (task.status == TaskStatusEnum.COMPLETED) {
          completedDuration += taskDuration;
        }
      }
    }

    if (totalDuration == Duration.zero) return 0.0;
    return completedDuration.inSeconds / totalDuration.inSeconds;
  }

  void loadRecentLogs() {
    // TODO: Implement actual log loading
    recentLogs = List.generate(
      5,
      (index) => TaskLog("14 november 2024 15:14", "1h 5m"),
    );
  }

  bool get hasTraits => attributeBars.isNotEmpty || skillBars.isNotEmpty;

  int get daysInProgress => DateTime.now().difference(taskRutinCreatedDate).inDays + 2;

  String get averagePerDay => ((taskModel.type == TaskTypeEnum.TIMER ? allTimeDuration : (taskModel.remainingDuration! * allTimeCount)) / daysInProgress.abs()).textShortDynamic();

  int get successRate => (completedTaskCount + failedTaskCount) == 0 ? 0 : ((completedTaskCount / (completedTaskCount + failedTaskCount)) * 100).toInt();
}
