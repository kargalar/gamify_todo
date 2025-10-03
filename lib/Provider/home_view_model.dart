import 'package:flutter/foundation.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_provider.dart';

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

  // Commands
  void changeSelectedDate(DateTime date) {
    TaskProvider().changeSelectedDate(date);
  }

  Future<void> toggleShowCompleted() async {
    await TaskProvider().changeShowCompleted();
  }

  void skipRoutinesForSelectedDate() {
    TaskProvider().skipRoutinesForDate(selectedDate);
  }

  void goToday() => changeSelectedDate(DateTime.now());

  // Queries
  List<TaskModel> getOverdueTasks() => TaskProvider().getOverdueTasks();

  List<dynamic> getTasksForDate(DateTime date) => TaskProvider().getTasksForDate(date);

  List<TaskModel> getPinnedTasksForToday() => TaskProvider().getPinnedTasksForToday();

  List<dynamic> getRoutineTasksForDate(DateTime date) => TaskProvider().getRoutineTasksForDate(date);

  List<dynamic> getGhostRoutineTasksForDate(DateTime date) => TaskProvider().getGhostRoutineTasksForDate(date);

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
