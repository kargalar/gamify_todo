import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
// Removed direct widget dependency for cleaner MVVM
// import 'package:next_level/Page/Task Detail Page/widget/progress_bar.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:intl/intl.dart';

class TraitProgressData {
  final int traitId;
  final String title;
  final double progress; // 0..1
  final Color color;
  final String icon;
  const TraitProgressData({required this.traitId, required this.title, required this.progress, required this.color, required this.icon});
}

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
  List<TraitProgressData> attributeProgressList = [];
  List<TraitProgressData> skillProgressList = [];
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
    _taskLogProvider.addListener(_onTaskLogChanged);
  }

  @override
  void dispose() {
    _taskLogProvider.removeListener(_onTaskLogChanged);
    super.dispose();
  }

  void _onTaskLogChanged() {
    // Log değiştiğinde tüm istatistik ve trait progress yeniden hesapla
    calculateStatistics();
    refreshTraits();
    loadRecentLogs();
    notifyListeners();
  }

  // Traits'i yeniden hesaplamak için (tarih değişimi vb.) dışarıdan da çağrılabilir
  void refreshTraits() {
    attributeProgressList.clear();
    skillProgressList.clear();
    loadTraits();
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

    final completedTaskIds = <int>{};
    final failedTaskIds = <int>{};

    // Logları işle
    for (var log in logs) {
      if (taskModel.type == TaskTypeEnum.TIMER && log.duration != null) {
        allTimeDuration += log.duration!;
      } else if (taskModel.type == TaskTypeEnum.COUNTER && log.count != null) {
        allTimeCount += log.count!;
      }
      if (log.status == TaskStatusEnum.COMPLETED) {
        completedTaskIds.add(log.taskId);
      } else if (log.status == TaskStatusEnum.FAILED) {
        failedTaskIds.add(log.taskId);
      }
    }
    completedTaskCount = completedTaskIds.length;
    failedTaskCount = failedTaskIds.length;

    // Rutin oluşturulma tarihini al
    if (taskModel.routineID != null) {
      try {
        final routine = TaskProvider().routineList.firstWhere((element) => element.id == taskModel.routineID);
        taskRutinCreatedDate = routine.createdDate;
      } catch (e) {
        // If routine not found, use current date as fallback
        debugPrint('Routine with ID ${taskModel.routineID} not found in TaskProvider list');
        taskRutinCreatedDate = DateTime.now();
      }
    } else {
      // Tek task için oluşturulma tarihi - taskDate'i kullan
      taskRutinCreatedDate = taskModel.taskDate ?? DateTime.now();
    }
  }

  void loadTraits() {
    // Build attribute progress data
    if (taskModel.attributeIDList?.isNotEmpty ?? false) {
      for (final traitId in taskModel.attributeIDList!) {
        try {
          final trait = TraitProvider().traitList.firstWhere((t) => t.id == traitId);
          final progress = calculateTraitProgress(traitId);
          attributeProgressList.add(TraitProgressData(traitId: traitId, title: trait.title, progress: progress, color: trait.color, icon: trait.icon));
        } catch (_) {}
      }
    }
    // Build skill progress data
    if (taskModel.skillIDList?.isNotEmpty ?? false) {
      for (final traitId in taskModel.skillIDList!) {
        try {
          final trait = TraitProvider().traitList.firstWhere((t) => t.id == traitId);
          final progress = calculateTraitProgress(traitId);
          skillProgressList.add(TraitProgressData(traitId: traitId, title: trait.title, progress: progress, color: trait.color, icon: trait.icon));
        } catch (_) {}
      }
    }
  }

  double calculateTraitProgress(int traitId) {
    // İstenen: Bu task'ın söz konusu trait (attribute/skill) için GLOBAL toplam ilerlemeye katkı oranı.
    // Yani: currentTaskUnits / sum(allTasksWithTraitUnits)

    // 1. Trait'e sahip tüm taskları (routine bağımsız) al
    final tasksWithTrait = TaskProvider().taskList.where((t) => (t.attributeIDList?.contains(traitId) ?? false) || (t.skillIDList?.contains(traitId) ?? false)).toList();
    if (tasksWithTrait.isEmpty) return 0.0;

    // 2. İlgili logları filtrele (yalnızca trait'e sahip tasklar)
    final traitTaskIds = tasksWithTrait.map((e) => e.id).toSet();
    final logs = TaskLogProvider().taskLogList.where((log) => traitTaskIds.contains(log.taskId));

    // 3. Her task için units hesapla
    final Map<int, double> unitsPerTask = {for (final t in tasksWithTrait) t.id: 0.0};

    for (final t in tasksWithTrait) {
      double units = 0;
      final taskLogs = logs.where((l) => l.taskId == t.id);
      switch (t.type) {
        case TaskTypeEnum.TIMER:
          for (final l in taskLogs) {
            if (l.duration != null) units += l.duration!.inSeconds;
          }
          if (t.currentDuration != null && t.currentDuration!.inSeconds > 0) units += t.currentDuration!.inSeconds;
          break;
        case TaskTypeEnum.COUNTER:
          for (final l in taskLogs) {
            if (l.count != null) units += l.count!;
          }
          if (t.currentCount != null && t.currentCount! > 0) units += t.currentCount!;
          break;
        case TaskTypeEnum.CHECKBOX:
          final hasCompleted = taskLogs.any((l) => l.status == TaskStatusEnum.COMPLETED) || t.status == TaskStatusEnum.COMPLETED;
          if (hasCompleted) units = 1; // checkbox katkısı 1
          break;
      }
      unitsPerTask[t.id] = units;
    }

    // 4. Toplam ve mevcut task katkısı
    final totalUnits = unitsPerTask.values.fold<double>(0, (p, e) => p + e);
    if (totalUnits <= 0) return 0.0;
    final currentUnits = unitsPerTask[taskModel.id] ?? 0.0;
    return (currentUnits / totalUnits).clamp(0.0, 1.0);
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
      // Format: "d MMM yyyy HH:mm:ss" - Daha kompakt bir format
      String formattedDate = DateFormat('d MMM yyyy HH:mm:ss').format(log.logDate);

      // Format the duration or count as a difference
      String progressText = "";

      if (log.duration != null) {
        // Pozitif veya negatif değerleri göster
        bool isPositive = !log.duration!.isNegative;
        int hours = isPositive ? log.duration!.inHours : -log.duration!.inHours;
        int minutes = isPositive ? log.duration!.inMinutes.remainder(60) : -log.duration!.inMinutes.remainder(60);
        int seconds = isPositive ? log.duration!.inSeconds.remainder(60) : -log.duration!.inSeconds.remainder(60);
        String sign = isPositive ? "+" : "-";

        // Saat, dakika ve saniye değerlerini göster
        if (hours > 0) {
          // Saat varsa
          if (minutes > 0) {
            // Saat ve dakika varsa
            if (seconds > 0) {
              // Saat, dakika ve saniye varsa
              progressText = "$sign${hours}h ${minutes}m ${seconds}s";
            } else {
              // Saat ve dakika var, saniye yok
              progressText = "$sign${hours}h ${minutes}m";
            }
          } else {
            // Sadece saat varsa
            if (seconds > 0) {
              // Saat ve saniye varsa
              progressText = "$sign${hours}h ${seconds}s";
            } else {
              // Sadece saat varsa
              progressText = "$sign${hours}h";
            }
          }
        } else if (minutes > 0) {
          // Saat yok, dakika varsa
          if (seconds > 0) {
            // Dakika ve saniye varsa
            progressText = "$sign${minutes}m ${seconds}s";
          } else {
            // Sadece dakika varsa
            progressText = "$sign${minutes}m";
          }
        } else if (seconds > 0) {
          // Sadece saniye varsa
          progressText = "$sign${seconds}s";
        } else {
          // Sıfır durumu - işaret göster
          progressText = "${isPositive ? '+' : '-'}0s";
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

  bool get hasTraits => attributeProgressList.isNotEmpty || skillProgressList.isNotEmpty;

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
