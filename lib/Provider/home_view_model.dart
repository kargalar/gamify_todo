import 'package:flutter/foundation.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/category_provider.dart';

/// HomeViewModel acts as the mediator between Home views and TaskProvider.
/// It exposes UI-ready state and commands without requiring BuildContext.
class HomeViewModel extends ChangeNotifier {
  late final VoidCallback _taskListener;

  HomeViewModel() {
    // Re-emit TaskProvider changes to rebuild Home views
    _taskListener = () => notifyListeners();
    TaskProvider().addListener(_taskListener);
  }

  @override
  void dispose() {
    TaskProvider().removeListener(_taskListener);
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
}
