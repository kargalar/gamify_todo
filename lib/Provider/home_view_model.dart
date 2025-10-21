import 'package:flutter/foundation.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
// task_log model used via provider
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
// TaskProvider already used below via import in this file context
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';

/// HomeViewModel acts as the mediator between Home views and TaskProvider.
/// It exposes UI-ready state and commands without requiring BuildContext.
class HomeViewModel extends ChangeNotifier {
  late final VoidCallback _taskListener;
  late final VoidCallback _streakListener;

  HomeViewModel() {
    // Re-emit TaskProvider changes to rebuild Home views
    _taskListener = () => notifyListeners();
    TaskProvider().addListener(_taskListener);
    // Listen to StreakSettingsProvider changes so target updates when settings change
    _streakListener = () => notifyListeners();
    StreakSettingsProvider().addListener(_streakListener);
  }

  @override
  void dispose() {
    TaskProvider().removeListener(_taskListener);
    StreakSettingsProvider().removeListener(_streakListener);
    super.dispose();
  }

  // State
  DateTime get selectedDate => TaskProvider().selectedDate;

  bool get showCompleted => TaskProvider().showCompleted;

  bool get showArchived => TaskProvider().showArchived;

  String? get selectedCategoryId => TaskProvider().selectedCategoryId;

  List<dynamic> get taskCategories => CategoryProvider().categoryList;

  Map<int, int> get taskCounts {
    final counts = <int, int>{};
    final allTasks = TaskProvider().taskList;

    for (var category in taskCategories) {
      counts[category.id] = allTasks.where((task) => task.categoryId == category.id).length;
    }
    return counts;
  }

  // Commands
  void changeSelectedDate(DateTime date) {
    TaskProvider().changeSelectedDate(date);
  }

  Future<void> toggleShowCompleted() async {
    await TaskProvider().changeShowCompleted();
  }

  Future<void> toggleShowArchived() async {
    await TaskProvider().toggleShowArchived();
  }

  void setSelectedCategory(String? categoryId) {
    TaskProvider().setSelectedCategory(categoryId);
    notifyListeners();
  }

  void skipRoutinesForSelectedDate() {
    TaskProvider().skipRoutinesForDate(selectedDate);
  }

  void goToday() => changeSelectedDate(DateTime.now());

  // Queries
  List<TaskModel> getOverdueTasks() {
    final overdueTasks = TaskProvider().getOverdueTasks();
    if (selectedCategoryId == null) {
      return overdueTasks;
    }
    return overdueTasks.where((task) => task.categoryId == selectedCategoryId).toList();
  }

  List<dynamic> getTasksForDate(DateTime date) {
    final tasks = TaskProvider().getTasksForDate(date);
    if (selectedCategoryId == null) {
      return tasks;
    }
    return tasks.where((task) => task.categoryId == selectedCategoryId).toList();
  }

  List<TaskModel> getPinnedTasksForToday() {
    final pinnedTasks = TaskProvider().getPinnedTasksForToday();
    if (selectedCategoryId == null) {
      return pinnedTasks;
    }
    return pinnedTasks.where((task) => task.categoryId == selectedCategoryId).toList();
  }

  List<dynamic> getRoutineTasksForDate(DateTime date) {
    final routines = TaskProvider().getRoutineTasksForDate(date);
    if (selectedCategoryId == null) {
      return routines;
    }
    return routines.where((routine) => routine.categoryId == selectedCategoryId).toList();
  }

  List<dynamic> getGhostRoutineTasksForDate(DateTime date) {
    final ghostRoutines = TaskProvider().getGhostRoutineTasksForDate(date);
    if (selectedCategoryId == null) {
      return ghostRoutines;
    }
    return ghostRoutines.where((routine) => routine.categoryId == selectedCategoryId).toList();
  }

  List<TaskModel> getArchivedTasks() {
    final archivedTasks = TaskProvider().getArchivedTasks();
    if (selectedCategoryId == null) {
      return archivedTasks;
    }
    return archivedTasks.where((task) => task.categoryId == selectedCategoryId).toList();
  }

  List<RoutineModel> getArchivedRoutines() {
    final archivedRoutines = TaskProvider().getArchivedRoutines();
    if (selectedCategoryId == null) {
      return archivedRoutines;
    }
    return archivedRoutines.where((routine) => routine.categoryId == selectedCategoryId).toList();
  }

  // Paging helpers (kept UI-agnostic)
  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  int pageForDate({required DateTime baseDate, required DateTime targetDate, int referencePage = 1000}) {
    final int dayDiff = daysBetween(baseDate, targetDate);
    return referencePage + dayDiff;
  }

  DateTime dateForPage({required DateTime baseDate, required int pageIndex, int referencePage = 1000}) {
    final int diff = pageIndex - referencePage;
    return baseDate.add(Duration(days: diff));
  }

  void onPageChanged({required int pageIndex, required DateTime baseDate, int referencePage = 1000}) {
    final DateTime newDate = dateForPage(baseDate: baseDate, pageIndex: pageIndex, referencePage: referencePage);
    changeSelectedDate(newDate);
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Calculate total duration logged for the selected date (today by default)
  /// This sums up durations from task logs and includes running timers' currentDuration
  Duration get todayTotalDuration {
    final DateTime date = selectedDate;

    // Aggregate from logs
    final logs = TaskLogProvider().taskLogList;
    Duration total = Duration.zero;

    // For checkbox tasks we must ensure per-day uniqueness; use processed set
    final Set<String> processedTaskDates = {};

    for (final log in logs) {
      if (!(log.logDate.year == date.year && log.logDate.month == date.month && log.logDate.day == date.day)) continue;

      // Find corresponding task if needed
      try {
        final task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);

        if (log.duration != null) {
          total += log.duration!;
        } else if (log.count != null && log.count! > 0) {
          if (task.remainingDuration != null) {
            total += (task.remainingDuration! * (log.count! <= 100 ? log.count! : 5));
          }
        } else if (log.status == null || log.status == TaskStatusEnum.DONE) {
          // Treat as checkbox DONE if applicable
          String key = "${log.taskId}_${log.logDate.year}-${log.logDate.month}-${log.logDate.day}";
          if (!processedTaskDates.contains(key)) {
            if (task.remainingDuration != null && log.status == TaskStatusEnum.DONE) {
              total += task.remainingDuration!;
            }
            processedTaskDates.add(key);
          }
        }
      } catch (_) {
        // ignore missing tasks
      }
    }

    // Add running timers for tasks that are active today
    for (final task in TaskProvider().taskList) {
      if (task.isTimerActive == true && task.taskDate != null && task.taskDate!.isSameDay(date)) {
        total += task.currentDuration ?? Duration.zero;
      }
    }

    // Also include active store item timers if needed (optional)
    // Skipping store items for home total to keep scope limited to tasks.

    debugPrint('Today total duration for $date -> ${total.inSeconds} seconds (${total.textShort2hour()})');
    return total;
  }

  String get todayTotalText => todayTotalDuration.compactFormat();

  /// Today's target: sum of today's tasks' target durations (remainingDuration) if available.
  /// Fallback to streak minimum hours (converted to Duration) or 1 hour.
  Duration get todayTargetDuration {
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

  /// Streak minimum duration (from settings)
  Duration get streakDuration {
    final double hours = StreakSettingsProvider().streakMinimumHours;
    if (hours > 0) return Duration(minutes: (hours * 60).toInt());
    return const Duration(hours: 1);
  }

  /// Progress percent toward today's target (0..1)
  double get todayProgressPercent {
    final Duration target = todayTargetDuration;
    if (target.inSeconds == 0) return 0.0;
    final double p = todayTotalDuration.inSeconds / target.inSeconds;
    if (p.isNaN || p.isInfinite) return 0.0;
    return p.clamp(0.0, 1.0);
  }

  /// Breakdown of contributions for selected date: list of map with title and duration
  List<Map<String, dynamic>> todayContributions() {
    final DateTime date = selectedDate;
    final Map<int, Duration> perTask = {};

    // Aggregate logs for the date
    for (final log in TaskLogProvider().taskLogList) {
      if (!log.logDate.isSameDay(date)) continue;
      final int taskId = log.taskId;
      Duration add = Duration.zero;
      if (log.duration != null) {
        add = log.duration!;
      } else if (log.count != null && log.count! > 0) {
        try {
          final t = TaskProvider().taskList.firstWhere((x) => x.id == taskId);
          final per = t.remainingDuration ?? Duration.zero;
          add = per * (log.count! <= 100 ? log.count! : 5);
        } catch (_) {}
      } else if (log.status == null || log.status == TaskStatusEnum.DONE) {
        try {
          final t = TaskProvider().taskList.firstWhere((x) => x.id == taskId);
          add = t.remainingDuration ?? Duration.zero;
        } catch (_) {}
      }

      if (add > Duration.zero) {
        perTask[taskId] = (perTask[taskId] ?? Duration.zero) + add;
      }
    }

    // Include running timers for tasks scheduled today
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

    // sort descending by duration
    list.sort((a, b) => (b['duration'] as Duration).compareTo(a['duration'] as Duration));
    return list;
  }
}
