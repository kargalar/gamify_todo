import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Page/Task%20Detail%20Page/widget/progress_bar.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:gamify_todo/Provider/trait_provider.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Model/task_log_model.dart';
import 'package:intl/intl.dart';

class TaskLog {
  final String dateTime;
  final String duration;
  final String status;
  final int logId;

  TaskLog(this.dateTime, this.duration, this.status, this.logId);
}

class TaskDetailViewModel with ChangeNotifier {
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

  // TaskLogProvider'ı dinlemek için
  late final TaskLogProvider _taskLogProvider = TaskLogProvider();

  TaskDetailViewModel(this.taskModel);

  void initialize() {
    calculateStatistics();
    loadTraits();
    loadRecentLogs();

    // TaskLogProvider'ı dinle
    _taskLogProvider.addListener(_onTaskLogChanged);
  }

  @override
  void dispose() {
    // Listener'ı kaldır
    _taskLogProvider.removeListener(_onTaskLogChanged);
    super.dispose();
  }

  void _onTaskLogChanged() {
    // TaskLogProvider değiştiğinde logları yeniden yükle
    loadRecentLogs();
    notifyListeners();
  }

  void calculateStatistics() {
    // Log verilerine göre istatistikleri hesapla
    List<TaskLogModel> logs = [];

    // TaskProvider'dan seçili tarihi al
    final selectedDate = TaskProvider().selectedDate;
    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (taskModel.routineID != null) {
      // Rutin için logları al
      logs = TaskLogProvider().getLogsByRoutineId(taskModel.routineID!);

      // Sadece seçili tarihe ait logları filtrele
      logs = logs.where((log) {
        final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
        return logDate.isAtSameMomentAs(selectedDay); // Sadece seçili tarih
      }).toList();
    } else {
      // Tek task için logları al
      logs = TaskLogProvider().getLogsByTaskId(taskModel.id);

      // Sadece seçili tarihe ait logları filtrele
      logs = logs.where((log) {
        final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
        return logDate.isAtSameMomentAs(selectedDay); // Sadece seçili tarih
      }).toList();
    }

    // İstatistikleri sıfırla
    allTimeDuration = Duration.zero;
    allTimeCount = 0;
    completedTaskCount = 0;
    failedTaskCount = 0;

    // Logları işle
    for (var log in logs) {
      if (taskModel.type == TaskTypeEnum.TIMER && log.duration != null) {
        allTimeDuration += log.duration!;
      } else if (taskModel.type == TaskTypeEnum.COUNTER && log.count != null) {
        allTimeCount += log.count!;
      }

      if (log.status == TaskStatusEnum.COMPLETED) {
        completedTaskCount++;
      } else if (log.status == TaskStatusEnum.FAILED) {
        failedTaskCount++;
      }
    }

    // Rutin oluşturulma tarihini al
    if (taskModel.routineID != null) {
      taskRutinCreatedDate = TaskProvider().routineList.firstWhere((element) => element.id == taskModel.routineID).createdDate;
    } else {
      // Tek task için oluşturulma tarihi - taskDate'i kullan
      taskRutinCreatedDate = taskModel.taskDate;
    }
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

  double calculateTraitProgress(int traitId) {
    Duration totalDuration = Duration.zero;
    Duration completedDuration = Duration.zero;

    // Tüm logları al
    List<TaskLogModel> allLogs = TaskLogProvider().taskLogList;

    // TaskProvider'dan seçili tarihi al
    final selectedDate = TaskProvider().selectedDate;
    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    // Sadece seçili tarihe ait logları filtrele
    allLogs = allLogs.where((log) {
      final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      return logDate.isAtSameMomentAs(selectedDay); // Sadece seçili tarih
    }).toList();

    // Tüm taskları al
    List<TaskModel> allTasks = TaskProvider().taskList;

    // Trait ile ilgili taskları bul
    List<TaskModel> tasksWithTrait = allTasks.where((task) {
      return (task.attributeIDList?.contains(traitId) ?? false) || (task.skillIDList?.contains(traitId) ?? false);
    }).toList();

    // Her task için toplam süreyi hesapla
    for (var task in tasksWithTrait) {
      Duration taskDuration;
      if (task.type == TaskTypeEnum.TIMER) {
        taskDuration = task.remainingDuration ?? Duration.zero;
      } else if (task.type == TaskTypeEnum.COUNTER) {
        taskDuration = (task.remainingDuration ?? Duration.zero) * (task.targetCount ?? 1);
      } else {
        taskDuration = task.remainingDuration ?? Duration.zero;
      }

      totalDuration += taskDuration;

      // Bu task için logları bul
      List<TaskLogModel> taskLogs = allLogs.where((log) => log.taskId == task.id).toList();

      // Tamamlanmış loglar için süreyi hesapla
      for (var log in taskLogs) {
        if (log.status == TaskStatusEnum.COMPLETED) {
          if (task.type == TaskTypeEnum.TIMER && log.duration != null) {
            completedDuration += log.duration!;
          } else if (task.type == TaskTypeEnum.COUNTER && log.count != null) {
            completedDuration += (task.remainingDuration ?? Duration.zero) * log.count!;
          } else if (task.type == TaskTypeEnum.CHECKBOX) {
            completedDuration += task.remainingDuration ?? Duration.zero;
          }
        }
      }
    }

    if (totalDuration == Duration.zero) return 0.0;
    return completedDuration.inSeconds / totalDuration.inSeconds;
  }

  void loadRecentLogs() {
    // Get logs for this task or routine
    List<TaskLogModel> logs = [];

    // TaskProvider'dan seçili tarihi al
    final selectedDate = TaskProvider().selectedDate;
    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    if (taskModel.routineID != null) {
      // Get logs for the routine
      logs = TaskLogProvider().getLogsByRoutineId(taskModel.routineID!);

      // Sadece seçili tarihe ait logları filtrele
      logs = logs.where((log) {
        final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
        return logDate.isAtSameMomentAs(selectedDay); // Sadece seçili tarih
      }).toList();
    } else {
      // Get logs for the individual task
      logs = TaskLogProvider().getLogsByTaskId(taskModel.id);

      // Sadece seçili tarihe ait logları filtrele
      logs = logs.where((log) {
        final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
        return logDate.isAtSameMomentAs(selectedDay); // Sadece seçili tarih
      }).toList();
    }

    // Sort logs by date (newest first) with precise timestamp comparison including seconds and milliseconds
    logs.sort((a, b) => b.logDate.compareTo(a.logDate));

    // Convert to UI model
    List<TaskLog> tempLogs = [];

    for (int i = 0; i < logs.length && i < 10; i++) {
      final log = logs[i];

      // Format the date with seconds for precise time display
      String formattedDate = DateFormat('d MMMM yyyy HH:mm:ss').format(log.logDate);

      // Format the duration or count as a difference
      String progressText = "";

      if (log.duration != null) {
        // Pozitif veya negatif değerleri göster
        bool isPositive = !log.duration!.isNegative;
        int hours = isPositive ? log.duration!.inHours : -log.duration!.inHours;
        int minutes = isPositive ? log.duration!.inMinutes.remainder(60) : -log.duration!.inMinutes.remainder(60);
        String sign = isPositive ? "+" : "-";

        // Saat veya dakika 0 ise gösterme
        if (hours > 0 && minutes > 0) {
          progressText = "$sign${hours}h ${minutes}m";
        } else if (hours > 0) {
          progressText = "$sign${hours}h";
        } else if (minutes > 0) {
          progressText = "$sign${minutes}m";
        } else {
          // Sıfır durumu - işaret göster
          progressText = "${isPositive ? '+' : '-'}0m";
        }
      } else if (log.count != null) {
        // Pozitif veya negatif değerleri göster
        String sign = log.count! >= 0 ? "+" : "";
        progressText = "$sign${log.count}";
      }

      // Get status text
      String statusText = log.getStatusText();

      tempLogs.add(TaskLog(formattedDate, progressText, statusText, log.id));
    }

    recentLogs = tempLogs;

    // If no logs yet, provide empty list
    if (recentLogs.isEmpty) {
      recentLogs = [];
    }

    // Dinleyicilere bildir
    notifyListeners();
  }

  bool get hasTraits => attributeBars.isNotEmpty || skillBars.isNotEmpty;

  int get daysInProgress => DateTime.now().difference(taskRutinCreatedDate).inDays + 2;

  String get averagePerDay {
    Duration totalProgress = Duration.zero;

    if (taskModel.type == TaskTypeEnum.TIMER) {
      totalProgress = allTimeDuration;
    } else if (taskModel.type == TaskTypeEnum.COUNTER) {
      totalProgress = (taskModel.remainingDuration ?? Duration.zero) * allTimeCount;
    } else {
      // Checkbox için tamamlanmış log sayısı kadar süre
      totalProgress = (taskModel.remainingDuration ?? Duration.zero) * completedTaskCount;
    }

    if (daysInProgress <= 0) return Duration.zero.textShortDynamic();

    return (totalProgress / daysInProgress.abs()).textShortDynamic();
  }

  int get successRate => (completedTaskCount + failedTaskCount) == 0 ? 0 : ((completedTaskCount / (completedTaskCount + failedTaskCount)) * 100).toInt();
}
