import 'package:flutter/foundation.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
// task_log model used via provider
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
// TaskProvider already used below via import in this file context
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Core/duration_calculator.dart';
import 'package:next_level/Service/logging_service.dart';

/// HomeViewModel acts as the mediator between Home views and TaskProvider.
/// It exposes UI-ready state and commands without requiring BuildContext.
class HomeViewModel extends ChangeNotifier {
  late final VoidCallback _taskListener;
  late final VoidCallback _streakListener;
  late final VoidCallback _taskLogListener;

  Duration? _todayTotalDuration;

  HomeViewModel() {
    // Re-emit TaskProvider changes to rebuild Home views
    _taskListener = () {
      _updateTodayTotalDuration();
      notifyListeners();
    };
    TaskProvider().addListener(_taskListener);
    // Listen to StreakSettingsProvider changes so target updates when settings change
    _streakListener = () {
      _updateTodayTotalDuration();
      notifyListeners();
    };
    StreakSettingsProvider().addListener(_streakListener);
    // Listen to TaskLogProvider changes for log updates
    _taskLogListener = () {
      _updateTodayTotalDuration();
      notifyListeners();
    };
    TaskLogProvider().addListener(_taskLogListener);

    _updateTodayTotalDuration();
  }

  @override
  void dispose() {
    TaskProvider().removeListener(_taskListener);
    StreakSettingsProvider().removeListener(_streakListener);
    TaskLogProvider().removeListener(_taskLogListener);
    super.dispose();
  }

  void _updateTodayTotalDuration() {
    _todayTotalDuration = DurationCalculator.calculateTotalDurationForDate(selectedDate);
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
    _updateTodayTotalDuration();
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
  Duration get todayTotalDuration => _todayTotalDuration ?? Duration.zero;

  String get todayTotalText => todayTotalDuration.compactFormat();

  // / Today's target: sum of today's tasks' target durations (remainingDuration) if available.
  // / Fallback to streak minimum hours (converted to Duration) or 1 hour.
  Duration get todayTargetDuration {
    return DurationCalculator.calculateTodayTargetDuration(selectedDate);
  }

  /// Streak minimum duration (from settings)
  Duration get streakDuration {
    final double hours = StreakSettingsProvider().streakMinimumHours;
    if (hours > 0) return Duration(minutes: (hours * 60).toInt());
    return const Duration(hours: 1);
  }

  /// Progress percent toward today's target (0..1)
  double get todayProgressPercent {
    if (streakDuration.inSeconds == 0) return 0.0;
    final double p = todayTotalDuration.inSeconds / streakDuration.inSeconds;
    if (p.isNaN || p.isInfinite) return 0.0;
    return p;
  }

  /// Breakdown of contributions for selected date: list of map with title and duration
  List<Map<String, dynamic>> todayContributions() {
    return DurationCalculator.getContributionsForDate(selectedDate);
  }

  /// Get streak statuses for last 5 days, today, and tomorrow
  List<Map<String, dynamic>> get streakStatuses {
    final statuses = DurationCalculator.getStreakStatuses();
    LogService.debug('HomeViewModel: Streak statuses: $statuses');
    return statuses;
  }
}
