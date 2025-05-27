import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Core/extensions.dart';

class HomeWidgetService {
  static const String appGroupId = 'app.nextlevel.widget';
  static const String taskCountKey = 'taskCount';
  static const String taskTitlesKey = 'taskTitles';

  static Future<void> updateTaskCount() async {
    try {
      debugPrint('=== HOME WIDGET UPDATE START ===');

      // Setup widget first
      await setupHomeWidget();

      final taskProvider = TaskProvider();
      debugPrint('TaskProvider initialized, taskList length: ${taskProvider.taskList.length}');

      // Get today's tasks - we need to get incomplete tasks only
      final today = DateTime.now();
      debugPrint('Today date: $today');

      final todayTasks = taskProvider.taskList.where((task) => task.taskDate?.isSameDay(today) == true && task.routineID == null && task.status == null).toList();

      final routineTasks = taskProvider.taskList.where((task) => task.taskDate?.isSameDay(today) == true && task.routineID != null && task.status == null).toList();

      final allIncompleteTasks = [...todayTasks, ...routineTasks];
      final incompleteTasks = allIncompleteTasks.length;

      // Get all task titles for display
      final taskTitles = allIncompleteTasks.map((task) => task.title).toList();

      debugPrint('=== WIDGET DATA ===');
      debugPrint('Today tasks: ${todayTasks.length}');
      debugPrint('Routine tasks: ${routineTasks.length}');
      debugPrint('Total incomplete: $incompleteTasks');
      debugPrint('Task titles: $taskTitles');

      // Save widget data
      debugPrint('Saving widget data...');
      await HomeWidget.saveWidgetData(taskCountKey, incompleteTasks);
      debugPrint('Task count saved: $incompleteTasks');

      await HomeWidget.saveWidgetData(taskTitlesKey, jsonEncode(taskTitles));
      debugPrint('Task titles saved: ${jsonEncode(taskTitles)}');

      // Update widget
      debugPrint('Updating widget...');
      await HomeWidget.updateWidget(
        androidName: 'TaskWidgetProvider',
      );
      debugPrint('Widget update completed with real task data');
    } catch (e, stackTrace) {
      debugPrint('=== WIDGET UPDATE ERROR ===');
      debugPrint('Error updating task count widget: $e');
      debugPrint('Stack trace: $stackTrace');

      // Try to save error state
      try {
        await HomeWidget.saveWidgetData(taskCountKey, -1);
        await HomeWidget.updateWidget(androidName: 'TaskWidgetProvider');
        debugPrint('Error state saved to widget');
      } catch (errorSaveError) {
        debugPrint('Failed to save error state: $errorSaveError');
      }
    }
  }

  static Future<void> updateAllWidgets() async {
    await updateTaskCount();
  }

  static Future<void> setupHomeWidget() async {
    try {
      debugPrint('Setting up home widget with app group ID: $appGroupId');
      await HomeWidget.setAppGroupId(appGroupId);
      debugPrint('Home widget setup completed successfully');
    } catch (e) {
      debugPrint('Error setting up home widget: $e');
      rethrow;
    }
  }

  static Future<void> resetHomeWidget() async {
    try {
      debugPrint('=== RESETTING HOME WIDGET ===');

      // Clear all widget data
      await HomeWidget.saveWidgetData(taskCountKey, 0);
      await HomeWidget.saveWidgetData(taskTitlesKey, jsonEncode([]));

      // Update widget
      await HomeWidget.updateWidget(androidName: 'TaskWidgetProvider');

      debugPrint('Home widget reset completed');
    } catch (e) {
      debugPrint('Error resetting home widget: $e');
    }
  }
}
