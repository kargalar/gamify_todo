import 'dart:convert';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:hive/hive.dart' as hive;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level background entry point for AOT
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  await HomeWidgetService.backgroundCallback(uri);
}

@pragma('vm:entry-point')
class HomeWidgetService {
  static const String appGroupId = 'app.nextlevel.widget';
  static const String taskCountKey = 'taskCount';
  static const String taskTitlesKey = 'taskTitles';
  static const String taskDetailsKey = 'taskDetails';
  static const String totalWorkSecKey = 'totalWorkSec';
  static const String hideCompletedKey = 'hideCompleted';
  static Timer? _midnightTimer;

  /// Schedule a one-shot timer to refresh the widget right after local midnight
  static void scheduleNextMidnightRefresh() {
    try {
      _midnightTimer?.cancel();
      final now = DateTime.now();
      final nextMidnight = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      final delay = nextMidnight.difference(now) + const Duration(seconds: 1);
      debugPrint('Scheduling widget midnight refresh in ${delay.inSeconds}s (at $nextMidnight)');
      _midnightTimer = Timer(delay, () async {
        try {
          // Re-schedule for the following day as well
          scheduleNextMidnightRefresh();
          // Simply recalc and push data; task generation is handled elsewhere on app open
          await updateAllWidgets();
        } catch (e) {
          debugPrint('Midnight widget refresh failed: $e');
        }
      });
    } catch (e) {
      debugPrint('scheduleNextMidnightRefresh error: $e');
    }
  }

  static Future<void> updateTaskCount() async {
    try {
      debugPrint('=== HOME WIDGET UPDATE START ===');

      // Setup widget first
      await setupHomeWidget();

      final taskProvider = TaskProvider();
      List<TaskModel> allTasks = taskProvider.taskList;
      // In background isolate or early startup, provider may be empty; fall back to Hive
      if (allTasks.isEmpty) {
        try {
          allTasks = await HiveService().getTasks();
          debugPrint('Using Hive tasks for widget update, count: ${allTasks.length}');
        } catch (e) {
          debugPrint('Failed to load tasks from Hive for widget update: $e');
        }
      }
      debugPrint('Task list length for widget: ${allTasks.length}');

      // Get today's date
      final today = DateTime.now();
      debugPrint('Today date: $today');

      // Read hide flag (default false)
      final hideCompleted = await HomeWidget.getWidgetData<bool>(hideCompletedKey, defaultValue: false) ?? false;

      // Check vacation mode from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isVacationMode = prefs.getBool('vacation_mode_enabled') ?? false;
      debugPrint('Vacation mode: $isVacationMode');

      // Helper function to check if task should be included
      bool includeTask(TaskModel t, {bool isRoutine = false, bool isOverdue = false}) {
        // OVERDUE tasks are ALWAYS shown (never hidden by hideCompleted)
        if (isOverdue) {
          return true;
        }

        // Hide completed tasks if flag is set (except active timers and overdue)
        if (hideCompleted) {
          final activeTimer = t.type == TaskTypeEnum.TIMER && (t.isTimerActive ?? false);
          if (t.status != null && !activeTimer) return false;
        }

        // Don't show routines if vacation mode is active
        if (isRoutine && isVacationMode) return false;

        return true;
      }

      // Get overdue tasks (non-routine, non-pinned, overdue status) - ALWAYS SHOWN
      final overdueTasks = allTasks.where((task) => task.status == TaskStatusEnum.OVERDUE && task.routineID == null && !task.isPinned && includeTask(task, isOverdue: true)).toList();

      // Get pinned tasks (all dates, non-routine, not done/cancelled/failed)
      final pinnedTasks = allTasks.where((task) => task.isPinned && task.routineID == null && task.status != TaskStatusEnum.DONE && task.status != TaskStatusEnum.CANCEL && task.status != TaskStatusEnum.FAILED && includeTask(task)).toList();

      // Get today's normal tasks (not pinned, not overdue, today's date)
      final todayTasks = allTasks.where((task) => task.taskDate?.isSameDay(today) == true && task.routineID == null && !task.isPinned && task.status != TaskStatusEnum.OVERDUE && includeTask(task)).toList();

      // Get today's routine tasks (only if not in vacation mode)
      final routineTasks = allTasks.where((task) => task.taskDate?.isSameDay(today) == true && task.routineID != null && includeTask(task, isRoutine: true)).toList();

      // Combine all tasks in order: overdue -> pinned -> normal -> routines
      final allIncompleteTasks = [...overdueTasks, ...pinnedTasks, ...todayTasks, ...routineTasks];
      final incompleteTasks = allIncompleteTasks.length;

      // Get all task titles for display
      final taskTitles = allIncompleteTasks.map((task) => task.title).toList();

      // Build task details for progress display with section info
      final taskDetails = <Map<String, dynamic>>[];

      // Add overdue tasks with section marker
      for (var task in overdueTasks) {
        taskDetails.add({
          'id': task.id,
          'title': task.title,
          'type': task.type.toString().split('.').last,
          'currentCount': task.currentCount ?? 0,
          'targetCount': task.targetCount ?? 0,
          'currentDurationSec': task.currentDuration?.inSeconds ?? 0,
          'targetDurationSec': task.remainingDuration?.inSeconds ?? 0,
          'isTimerActive': task.isTimerActive ?? false,
          'section': 'OVERDUE',
        });
      }

      // Add pinned tasks with section marker
      for (var task in pinnedTasks) {
        taskDetails.add({
          'id': task.id,
          'title': task.title,
          'type': task.type.toString().split('.').last,
          'currentCount': task.currentCount ?? 0,
          'targetCount': task.targetCount ?? 0,
          'currentDurationSec': task.currentDuration?.inSeconds ?? 0,
          'targetDurationSec': task.remainingDuration?.inSeconds ?? 0,
          'isTimerActive': task.isTimerActive ?? false,
          'section': 'PINNED',
        });
      }

      // Add normal tasks with section marker
      for (var task in todayTasks) {
        taskDetails.add({
          'id': task.id,
          'title': task.title,
          'type': task.type.toString().split('.').last,
          'currentCount': task.currentCount ?? 0,
          'targetCount': task.targetCount ?? 0,
          'currentDurationSec': task.currentDuration?.inSeconds ?? 0,
          'targetDurationSec': task.remainingDuration?.inSeconds ?? 0,
          'isTimerActive': task.isTimerActive ?? false,
          'section': 'TASKS',
        });
      }

      // Add routine tasks with section marker
      for (var task in routineTasks) {
        taskDetails.add({
          'id': task.id,
          'title': task.title,
          'type': task.type.toString().split('.').last,
          'currentCount': task.currentCount ?? 0,
          'targetCount': task.targetCount ?? 0,
          'currentDurationSec': task.currentDuration?.inSeconds ?? 0,
          'targetDurationSec': task.remainingDuration?.inSeconds ?? 0,
          'isTimerActive': task.isTimerActive ?? false,
          'section': 'ROUTINES',
        });
      }

      // Calculate today's total work time from TIMER tasks (sum of currentDuration)
      final todaysAllTasks = allTasks.where((task) => task.taskDate?.isSameDay(today) == true).toList();
      final totalWorkSec = todaysAllTasks.where((t) => t.type == TaskTypeEnum.TIMER && t.currentDuration != null).fold<int>(0, (sum, t) => sum + (t.currentDuration!.inSeconds));

      debugPrint('=== WIDGET DATA ===');
      debugPrint('Overdue tasks: ${overdueTasks.length}');
      debugPrint('Pinned tasks: ${pinnedTasks.length}');
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
      // Set app group for plugin in background isolate
      try {
        await HomeWidget.setAppGroupId(appGroupId);
      } catch (e) {
        debugPrint('HomeWidget setAppGroupId failed in background: $e');
      }
      // Initialize Hive once for background isolate with explicit path
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final hivePath = '${appDocDir.path}/NextLevel';
        await Directory(hivePath).create(recursive: true);
        try {
          hive.Hive.init(hivePath);
        } catch (e) {
          // Ignore if already initialized
          debugPrint('Hive.init may already be called: $e');
        }
        try {
          await Helper().registerAdapters();
        } catch (e) {
          // If adapters were already registered, continue
          debugPrint('registerAdapters warning (continuing): $e');
        }
      } catch (e) {
        debugPrint('Hive init failed in background: $e');
        // Proceed anyway; boxes may still be accessible if already open
      }

      // Ensure logs are loaded in this isolate so IDs and merges are correct
      try {
        await TaskLogProvider().loadTaskLogs();
      } catch (e) {
        debugPrint('TaskLogProvider.loadTaskLogs failed in background: $e');
      }

      debugPrint('=== WIDGET BACKGROUND CALLBACK ===');
      debugPrint('URI: $uri');
      debugPrint('Query params: ${uri?.queryParameters}');

      final action = uri?.queryParameters['action'] ?? '';
      debugPrint('Action: $action');

      if (action.isEmpty) {
        debugPrint('⚠️ WARNING: Action is empty! URI might be malformed.');
        return;
      }

      if (action == 'toggleHideCompleted') {
        debugPrint('Toggling hide completed...');
        final current = await HomeWidget.getWidgetData<bool>(hideCompletedKey, defaultValue: false) ?? false;
        await HomeWidget.saveWidgetData(hideCompletedKey, !current);
        await updateAllWidgets();
        debugPrint('Hide completed toggled to ${!current}');
        return;
      }

      if (action == 'refresh') {
        debugPrint('Refreshing widget...');
        // Explicit refresh requested by native side (e.g., date/time change)
        await updateAllWidgets();
        return;
      }

      // Handle per-item actions
      final taskIdStr = uri?.queryParameters['taskId'];
      final taskId = taskIdStr != null ? int.tryParse(taskIdStr) : null;
      final titleParam = uri?.queryParameters['title'];

      debugPrint('Task ID: $taskId, Title: $titleParam');

      // Load the task directly from Hive
      final tasks = await HiveService().getTasks();
      TaskModel? task;
      if (taskId != null && taskId > 0) {
        final matches = tasks.where((t) => t.id == taskId);
        if (matches.isNotEmpty) task = matches.first;
      }
      // Fallback by title for today's task if id missing or not found
      if (task == null && titleParam != null && titleParam.isNotEmpty) {
        final today = DateTime.now();
        try {
          task = tasks.firstWhere((t) => (t.title == titleParam) && (t.taskDate?.isSameDay(today) == true));
        } catch (_) {}
      }
      if (task == null) {
        debugPrint('HomeWidget background: task not found id=$taskId title=$titleParam');
        return;
      }

      debugPrint('✅ Task found: ${task.title} (type: ${task.type})');

      switch (action) {
        case 'toggleCheckbox':
          debugPrint('🔘 Toggling checkbox for task: ${task.title}');
          if (task.type.toString().contains('CHECKBOX')) {
            // Toggle completion with date-aware logic and logging similar to TaskActionHandler
            if (task.status == TaskStatusEnum.DONE) {
              // Uncomplete: decide between OVERDUE vs in-progress
              if (task.taskDate != null) {
                final now = DateTime.now();
                final taskDateTime = task.taskDate!.copyWith(
                  hour: task.time?.hour ?? 23,
                  minute: task.time?.minute ?? 59,
                  second: 59,
                );
                if (taskDateTime.isBefore(now)) {
                  task.status = TaskStatusEnum.OVERDUE;
                  await TaskLogProvider().addTaskLog(task, customStatus: TaskStatusEnum.OVERDUE);
                } else {
                  task.status = null;
                  await TaskLogProvider().addTaskLog(task, customStatus: null);
                }
              } else {
                task.status = null;
                await TaskLogProvider().addTaskLog(task, customStatus: null);
              }
              await ServerManager().updateTask(taskModel: task);
            } else {
              task.status = TaskStatusEnum.DONE;
              await TaskLogProvider().addTaskLog(task, customStatus: TaskStatusEnum.DONE);
              await ServerManager().updateTask(taskModel: task);
            }
            await updateAllWidgets();
          }
          break;
        case 'incrementCounter':
          debugPrint('➕ Incrementing counter for task: ${task.title}');
          if (task.type.toString().contains('COUNTER')) {
            final prev = task.currentCount ?? 0;
            task.currentCount = prev + 1;
            debugPrint('Counter incremented: $prev -> ${task.currentCount}');
            // Log the increment
            await TaskLogProvider().addTaskLog(task, customCount: 1);
            // If reached target, mark as done and log completion
            final target = task.targetCount ?? 0;
            if (target > 0 && (task.currentCount ?? 0) >= target && task.status != TaskStatusEnum.DONE) {
              task.status = TaskStatusEnum.DONE;
              await TaskLogProvider().addTaskLog(task, customStatus: TaskStatusEnum.DONE);
            }
            await ServerManager().updateTask(taskModel: task);
            await updateAllWidgets();
          }
          break;
        case 'toggleTimer':
          if (task.type.toString().contains('TIMER')) {
            // Initialize notifications just in case
            try {
              await NotificationService().init();
            } catch (e) {
              debugPrint('Notification init failed in background: $e');
            }
            debugPrint('Background: toggling timer for task id=${task.id} title=${task.title}');
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
      // Register the top-level entry point to ensure availability in AOT
      // ignore: deprecated_member_use
      await HomeWidget.registerBackgroundCallback(homeWidgetBackgroundCallback);
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
      // Also schedule a local midnight refresh while the app is alive
      scheduleNextMidnightRefresh();
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
