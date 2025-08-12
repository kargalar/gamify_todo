import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Core/helper.dart';

class HomeWidgetService {
  static const String appGroupId = 'app.nextlevel.widget';
  static const String taskCountKey = 'taskCount';
  static const String taskTitlesKey = 'taskTitles';
  static const String taskDetailsKey = 'taskDetails';
  static const String totalWorkSecKey = 'totalWorkSec';
  static const String hideCompletedKey = 'hideCompleted';

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

      // Read hide flag (default false)
      final hideCompleted = await HomeWidget.getWidgetData<bool>(hideCompletedKey, defaultValue: false) ?? false;

      bool includeByStatus(t) {
        if (!hideCompleted) return true;
        return t.status == null; // only in-progress when hidden
      }

      final todayTasks = taskProvider.taskList.where((task) => task.taskDate?.isSameDay(today) == true && task.routineID == null && includeByStatus(task)).toList();

      final routineTasks = taskProvider.taskList.where((task) => task.taskDate?.isSameDay(today) == true && task.routineID != null && includeByStatus(task)).toList();

      final allIncompleteTasks = [...todayTasks, ...routineTasks];
      final incompleteTasks = allIncompleteTasks.length;

      // Get all task titles for display
      final taskTitles = allIncompleteTasks.map((task) => task.title).toList();

      // Build task details for progress display
      final taskDetails = allIncompleteTasks
          .map((task) => {
                'id': task.id,
                'title': task.title,
                'type': task.type.toString().split('.').last,
                'currentCount': task.currentCount ?? 0,
                'targetCount': task.targetCount ?? 0,
                'currentDurationSec': task.currentDuration?.inSeconds ?? 0,
                'targetDurationSec': task.remainingDuration?.inSeconds ?? 0,
                'isTimerActive': task.isTimerActive ?? false,
              })
          .toList();

      // Calculate today's total work time from TIMER tasks (sum of currentDuration)
      final todaysAllTasks = taskProvider.taskList.where((task) => task.taskDate?.isSameDay(today) == true).toList();
      final totalWorkSec = todaysAllTasks.where((t) => t.type == TaskTypeEnum.TIMER && t.currentDuration != null).fold<int>(0, (sum, t) => sum + (t.currentDuration!.inSeconds));

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
      await HomeWidget.saveWidgetData(taskDetailsKey, jsonEncode(taskDetails));
      await HomeWidget.saveWidgetData(totalWorkSecKey, totalWorkSec);
      await HomeWidget.saveWidgetData(hideCompletedKey, hideCompleted);
      debugPrint('Task titles saved: ${jsonEncode(taskTitles)}');
      debugPrint('Task details saved: ${jsonEncode(taskDetails)}');
      debugPrint('Total work seconds saved: $totalWorkSec');

      // Update widget
      debugPrint('Updating widget...');
      await HomeWidget.updateWidget(
        androidName: 'TaskWidgetProvider',
      );
      debugPrint('Widget update done with real task data');
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

  // Background callback for widget interactions
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    try {
      // Ensure Flutter bindings and Hive adapters are initialized for background isolate
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await Helper().registerAdapters();
      } catch (_) {}

      final action = uri?.queryParameters['action'] ?? '';
      if (action == 'toggleHideCompleted') {
        final current = await HomeWidget.getWidgetData<bool>(hideCompletedKey, defaultValue: false) ?? false;
        await HomeWidget.saveWidgetData(hideCompletedKey, !current);
        await updateAllWidgets();
        return;
      }

      // Handle per-item actions
      final taskIdStr = uri?.queryParameters['taskId'];
      final taskId = taskIdStr != null ? int.tryParse(taskIdStr) : null;
      if (taskId == null) {
        return;
      }

      // Load the task directly from Hive
      final tasks = await HiveService().getTasks();
      final index = tasks.indexWhere((t) => t.id == taskId);
      if (index == -1) {
        return;
      }
      final task = tasks[index];

      switch (action) {
        case 'incrementCounter':
          if (task.type.toString().contains('COUNTER')) {
            task.currentCount = (task.currentCount ?? 0) + 1;
            await ServerManager().updateTask(taskModel: task);
            await updateAllWidgets();
          }
          break;
        case 'toggleTimer':
          if (task.type.toString().contains('TIMER')) {
            // Initialize notifications just in case
            try {
              await NotificationService().init();
            } catch (_) {}
            GlobalTimer().startStopTimer(taskModel: task);
            await updateAllWidgets();
          }
          break;
      }
    } catch (e) {
      debugPrint('HomeWidget backgroundCallback error: $e');
    }
  }

  static Future<void> registerBackground() async {
    try {
      await HomeWidget.registerBackgroundCallback(backgroundCallback);
    } catch (e) {
      debugPrint('HomeWidget registerBackground error: $e');
    }
  }

  static Future<void> setupHomeWidget() async {
    try {
      debugPrint('Setting up home widget with app group ID: $appGroupId');
      await HomeWidget.setAppGroupId(appGroupId);
      await registerBackground();
      debugPrint('Home widget setup done successfully');
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

      debugPrint('Home widget reset done');
    } catch (e) {
      debugPrint('Error resetting home widget: $e');
    }
  }
}
