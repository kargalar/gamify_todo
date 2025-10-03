import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/app_helper.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/sync_manager.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/offline_mode_provider.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper class to store task date change data for undo functionality
class _TaskDateChangeData {
  final DateTime? originalDate;
  final TaskStatusEnum? originalStatus;
  final bool? originalTimerActive;

  _TaskDateChangeData({
    required this.originalDate,
    required this.originalStatus,
    required this.originalTimerActive,
  });
}

// Helper class to store task completion data for undo functionality
class _TaskCompletionData {
  final TaskStatusEnum? previousStatus;

  _TaskCompletionData({
    required this.previousStatus,
  });
}

// Helper class to store task cancellation data for undo functionality
class _TaskCancellationData {
  final TaskStatusEnum? previousStatus;

  _TaskCancellationData({
    required this.previousStatus,
  });
}

// Helper class to store task failure data for undo functionality
class _TaskFailureData {
  final TaskStatusEnum? previousStatus;

  _TaskFailureData({
    required this.previousStatus,
  });
}

class TaskProvider with ChangeNotifier {
  // burayı singelton yaptım gayet de iyi oldu neden normalde de context den kullanıyoruz anlamadım. galiba "watch" için olabilir. sibelton kısmını global timer için yaptım.
  static final TaskProvider _instance = TaskProvider._internal();

  factory TaskProvider() {
    return _instance;
  }

  TaskProvider._internal() {
    // Uygulama başladığında showCompleted durumunu yükle
    loadShowCompletedState();
  }

  List<RoutineModel> routineList = [];

  List<TaskModel> taskList = [];
  // Undo functionality for deleted tasks and subtasks
  final Map<int, TaskModel> _deletedTasks = {};
  final Map<int, RoutineModel> _deletedRoutines = {};
  final Map<String, SubTaskModel> _deletedSubtasks = {}; // key: "taskId_subtaskId"
  final Map<String, Timer> _undoTimers = {};

  // Undo functionality for date changes
  final Map<int, _TaskDateChangeData> _dateChanges = {};
  // Undo functionality for task completion
  final Map<int, _TaskCompletionData> _completedTasks = {};

  // Undo functionality for task cancellation
  final Map<int, _TaskCancellationData> _cancelledTasks = {};

  // Undo functionality for task failure
  final Map<int, _TaskFailureData> _failedTasks = {};

  // Load categories when tasks are loaded
  Future<void> loadCategories() async {
    final categories = await ServerManager().getCategories();
    CategoryProvider().categoryList = categories;
  }

  // TODO: saat 00:00:00 geçtikten sonra hala dünü gösterecek muhtemelen her ana sayfaya gidişte. bunu düzelt. yani değişken uygulama açıldığında belirlendiği için 12 den sonra değişmeyecek.
  DateTime selectedDate = DateTime.now();
  bool showCompleted = false;

  // Uygulama başladığında showCompleted durumunu SharedPreferences'dan yükle
  Future<void> loadShowCompletedState() async {
    final prefs = await SharedPreferences.getInstance();
    showCompleted = prefs.getBool('show_completed') ?? false;
    notifyListeners();
  }

  Future<void> addTask(TaskModel taskModel) async {
    final int taskId = await ServerManager().addTask(taskModel: taskModel);

    taskModel.id = taskId;

    // Check if task is created with a past date and mark as overdue
    if (taskModel.taskDate != null) {
      final now = DateTime.now();
      final taskDateTime = taskModel.taskDate!.copyWith(
        hour: taskModel.time?.hour ?? 23,
        minute: taskModel.time?.minute ?? 59,
        second: 59,
      );

      if (taskDateTime.isBefore(now) && taskModel.status != TaskStatusEnum.DONE) {
        // Task date is in the past, mark as overdue only if not already completed
        debugPrint('Setting newly created task status to overdue due to past date: ID=${taskModel.id}, Title=${taskModel.title}');
        taskModel.status = TaskStatusEnum.OVERDUE;

        // Create log for overdue status
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: TaskStatusEnum.OVERDUE,
        );

        // Update the task in storage with overdue status
        ServerManager().updateTask(taskModel: taskModel);
      }
    }

    taskList.add(taskModel);

    // Sync to Firestore
    await SyncManager().syncTask(taskModel);

    if (taskModel.time != null) {
      checkNotification(taskModel);
    }

    // Update home widget when task is added
    await HomeWidgetService.updateAllWidgets();

    notifyListeners();
  }

  Future addRoutine(RoutineModel routineModel) async {
    final int routineId = await ServerManager().addRoutine(routineModel: routineModel);

    routineModel.id = routineId;

    routineList.add(routineModel);
  }

  Future<void> editTask({
    required TaskModel taskModel,
    required List<int> selectedDays,
  }) async {
    debugPrint('Editing task: ID=${taskModel.id}, Title=${taskModel.title}');

    if (taskModel.routineID != null) {
      // Editing a task that belongs to a routine
      debugPrint('Task belongs to routine ID=${taskModel.routineID}');

      // Find the routine in the list
      RoutineModel routine = routineList.firstWhere((element) => element.id == taskModel.routineID);

      // Preserve the original isArchived status - don't change it during edit
      bool originalIsArchived = routine.isArchived;

      // Update routine properties
      routine.title = taskModel.title;
      routine.description = taskModel.description;
      routine.type = taskModel.type;
      routine.time = taskModel.time;
      routine.isNotificationOn = taskModel.isNotificationOn;
      routine.remainingDuration = taskModel.remainingDuration;
      routine.targetCount = taskModel.targetCount;
      routine.repeatDays = selectedDays;
      routine.attirbuteIDList = taskModel.attributeIDList;
      routine.skillIDList = taskModel.skillIDList;
      routine.isArchived = originalIsArchived; // Preserve the original archive status
      routine.priority = taskModel.priority;
      routine.categoryId = taskModel.categoryId;
      routine.earlyReminderMinutes = taskModel.earlyReminderMinutes;

      // Update routine subtasks - these will be the template for future tasks
      routine.subtasks = taskModel.subtasks
          ?.map((subtask) => SubTaskModel(
                id: subtask.id,
                title: subtask.title,
                description: subtask.description,
                isCompleted: false, // Routine templates should have uncompleted subtasks
              ))
          .toList();

      // Save the routine to Hive
      debugPrint('Updating routine in Hive');
      ServerManager().updateRoutine(routineModel: routine);

      // Update all tasks associated with this routine
      for (var task in taskList) {
        if (task.routineID == taskModel.routineID) {
          // Update task properties
          task.title = taskModel.title;
          task.description = taskModel.description;
          task.attributeIDList = taskModel.attributeIDList;
          task.skillIDList = taskModel.skillIDList;

          // Update remainingDuration and targetCount for all tasks, but preserve current progress for today's task
          if (task.taskDate != null && task.taskDate!.isSameDay(DateTime.now())) {
            // For today's task, use the new values from taskModel
            task.remainingDuration = taskModel.remainingDuration;
            task.targetCount = taskModel.targetCount;
          } else {
            // For past and future tasks, also update to new values but preserve any progress
            // For future tasks, this ensures they get the updated targets
            // For past tasks, this keeps them consistent with the routine template
            task.remainingDuration = taskModel.remainingDuration;
            task.targetCount = taskModel.targetCount;
          }

          task.isNotificationOn = taskModel.isNotificationOn;
          task.isAlarmOn = taskModel.isAlarmOn;
          task.time = taskModel.time;
          task.priority = taskModel.priority;
          task.categoryId = taskModel.categoryId;
          task.earlyReminderMinutes = taskModel.earlyReminderMinutes;
          task.location = taskModel.location;

          // Update subtasks for all routine instances, but preserve completion status for past/present tasks
          if (taskModel.subtasks != null) {
            if (task.taskDate != null && task.taskDate!.isSameDay(DateTime.now())) {
              // For today's task, copy all subtasks including completion status
              task.subtasks = taskModel.subtasks
                  ?.map((subtask) => SubTaskModel(
                        id: subtask.id,
                        title: subtask.title,
                        description: subtask.description,
                        isCompleted: subtask.isCompleted,
                      ))
                  .toList();
            } else if (task.taskDate != null && task.taskDate!.isAfter(DateTime.now())) {
              // For future tasks, copy subtasks but reset completion status
              task.subtasks = taskModel.subtasks
                  ?.map((subtask) => SubTaskModel(
                        id: subtask.id,
                        title: subtask.title,
                        description: subtask.description,
                        isCompleted: false, // Reset completion for future tasks
                      ))
                  .toList();
            } else {
              // For past tasks, preserve existing completion status but update structure
              final existingSubtasks = task.subtasks ?? [];
              task.subtasks = taskModel.subtasks?.map((newSubtask) {
                // Find existing subtask with same ID to preserve completion status
                final existing = existingSubtasks.firstWhere(
                  (s) => s.id == newSubtask.id,
                  orElse: () => SubTaskModel(id: newSubtask.id, title: newSubtask.title, description: newSubtask.description),
                );
                return SubTaskModel(
                  id: newSubtask.id,
                  title: newSubtask.title,
                  description: newSubtask.description,
                  isCompleted: existing.isCompleted, // Preserve completion status
                );
              }).toList();
            }
          } else {
            task.subtasks = null;
          }

          // Handle timer if active
          if (task.isTimerActive != null && task.isTimerActive!) {
            GlobalTimer().startStopTimer(taskModel: task);
          }

          // Update notifications
          checkNotification(task);

          // Save the task to Hive
          debugPrint('Updating task in Hive: ID=${task.id}');
          ServerManager().updateTask(taskModel: task);
        }
      }

      // If the routine is no longer active for today, remove any task instances created for today.
      // Previously only the first matching task was removed which could leave ghost tasks.
      final today = DateTime.now();
      if (!routine.isActiveForThisDate(today)) {
        // Collect all tasks for this routine that are dated today
        final todayTasks = taskList.where((task) => task.routineID == routine.id && task.taskDate != null && task.taskDate!.isSameDay(today)).toList();
        if (todayTasks.isNotEmpty) {
          for (var t in todayTasks) {
            // Remove from in-memory list
            taskList.removeWhere((task) => task.id == t.id);

            // Cancel any scheduled notifications/alarms for the task
            NotificationService().cancelNotificationOrAlarm(t.id);
            NotificationService().cancelNotificationOrAlarm(t.id + 300000);
            if (t.type == TaskTypeEnum.TIMER) {
              NotificationService().cancelNotificationOrAlarm(-t.id);
              NotificationService().cancelNotificationOrAlarm(t.id + 100000);
              NotificationService().cancelNotificationOrAlarm(t.id + 200000);
            }

            // Remove from server/storage
            ServerManager().deleteTask(id: t.id);

            // Add a log entry (preserve history) for deletion if needed
            TaskLogProvider().addTaskLog(
              t,
              customStatus: TaskStatusEnum.CANCEL,
            );
          }

          // Update widgets after removals
          HomeWidgetService.updateAllWidgets();
        }
      }
    } else {
      // Editing a standalone task
      debugPrint('Editing standalone task');

      // Find the task in the list and update it to preserve Hive object identity
      final index = taskList.indexWhere((element) => element.id == taskModel.id);
      if (index != -1) {
        debugPrint('Found task in taskList at index $index: ID=${taskModel.id}');

        // Update the existing task properties to preserve Hive object identity
        final existingTask = taskList[index];

        // If user selected repeat days during edit of a standalone task, convert this task into a routine
        if (selectedDays.isNotEmpty && existingTask.routineID == null) {
          debugPrint('Converting standalone task to routine with days: $selectedDays');

          // Validate start date
          final startDate = taskModel.taskDate ?? DateTime.now();

          // Create a routine from the task
          final newRoutine = RoutineModel(
            title: taskModel.title,
            description: taskModel.description,
            type: taskModel.type,
            createdDate: DateTime.now(),
            startDate: startDate,
            time: taskModel.time,
            isNotificationOn: taskModel.isNotificationOn,
            isAlarmOn: taskModel.isAlarmOn,
            remainingDuration: taskModel.remainingDuration,
            targetCount: taskModel.targetCount,
            repeatDays: List<int>.from(selectedDays),
            attirbuteIDList: taskModel.attributeIDList,
            skillIDList: taskModel.skillIDList,
            isArchived: false,
            priority: taskModel.priority,
            categoryId: taskModel.categoryId,
            earlyReminderMinutes: taskModel.earlyReminderMinutes,
            subtasks: taskModel.subtasks
                ?.map((s) => SubTaskModel(
                      id: s.id,
                      title: s.title,
                      description: s.description,
                      isCompleted: false,
                    ))
                .toList(),
          );

          await addRoutine(newRoutine);

          // Replace the existing standalone task with a new TaskModel linked to the routine
          final TaskModel convertedTask = TaskModel(
            id: existingTask.id,
            routineID: newRoutine.id,
            title: taskModel.title,
            description: taskModel.description,
            type: taskModel.type,
            taskDate: taskModel.taskDate ?? startDate,
            time: taskModel.time,
            isNotificationOn: taskModel.isNotificationOn,
            isAlarmOn: taskModel.isAlarmOn,
            currentDuration: taskModel.type == TaskTypeEnum.TIMER ? (existingTask.currentDuration ?? Duration.zero) : null,
            remainingDuration: taskModel.remainingDuration,
            currentCount: taskModel.type == TaskTypeEnum.COUNTER ? (existingTask.currentCount ?? 0) : null,
            targetCount: taskModel.targetCount,
            isTimerActive: taskModel.type == TaskTypeEnum.TIMER ? (existingTask.isTimerActive ?? false) : null,
            attributeIDList: taskModel.attributeIDList,
            skillIDList: taskModel.skillIDList,
            status: null,
            priority: taskModel.priority,
            subtasks: taskModel.subtasks,
            location: taskModel.location,
            categoryId: taskModel.categoryId,
            showSubtasks: existingTask.showSubtasks,
            earlyReminderMinutes: taskModel.earlyReminderMinutes,
            attachmentPaths: taskModel.attachmentPaths,
          );

          // Replace in list to preserve ordering
          taskList[index] = convertedTask;

          // Save and sync updated task
          await ServerManager().updateTask(taskModel: convertedTask);

          // If today matches repeat days and startDate is today or before, ensure a task instance exists for today
          final today = DateTime.now();
          final isActiveToday = selectedDays.contains(today.weekday - 1) && !today.isBeforeDay(startDate);
          final hasTodayInstance = taskList.any((t) => t.routineID == newRoutine.id && t.taskDate != null && t.taskDate!.isSameDay(today));
          if (isActiveToday && !hasTodayInstance) {
            debugPrint('Creating today instance for converted routine');
            await _createTaskFromRoutine(newRoutine, today);
          }

          // Update notifications
          checkNotification(convertedTask);

          // Update widgets and notify
          await HomeWidgetService.updateAllWidgets();
          notifyListeners();
          return;
        }
        existingTask.title = taskModel.title;
        existingTask.description = taskModel.description;
        existingTask.taskDate = taskModel.taskDate;

        // Handle task status based on date change (similar to changeTaskDate logic)
        if (taskModel.taskDate == null) {
          // Task is being made dateless
          // Stop timer if active
          if (existingTask.type == TaskTypeEnum.TIMER && existingTask.isTimerActive == true) {
            existingTask.isTimerActive = false;
          }

          // Update task status to in progress if not completed
          if (existingTask.status != TaskStatusEnum.DONE) {
            debugPrint('Resetting task status to null due to dateless change: ID=${existingTask.id}, Title=${existingTask.title}');
            existingTask.status = null;

            // Create log for the status change to null (in progress)
            TaskLogProvider().addTaskLog(
              existingTask,
              customStatus: null, // null status means "in progress"
            );
          }
        } else {
          // Task has a specific date, check if it's in the past
          final now = DateTime.now();
          final taskDateTime = taskModel.taskDate!.copyWith(
            hour: existingTask.time?.hour ?? 23,
            minute: existingTask.time?.minute ?? 59,
            second: 59,
          );

          if (taskDateTime.isBefore(now)) {
            // Task date is in the past, mark as overdue if not already completed
            if (existingTask.status != TaskStatusEnum.DONE) {
              debugPrint('Setting task status to overdue due to past date: ID=${existingTask.id}, Title=${existingTask.title}');
              existingTask.status = TaskStatusEnum.OVERDUE;

              // Create log for overdue status
              TaskLogProvider().addTaskLog(
                existingTask,
                customStatus: TaskStatusEnum.OVERDUE,
              );
            }
          } else {
            // Task date is in the future or today, reset status to null (in progress) if not completed
            if (existingTask.status != TaskStatusEnum.DONE && existingTask.status != null) {
              debugPrint('Resetting task status to null due to date change: ID=${existingTask.id}, Title=${existingTask.title}');
              existingTask.status = null;

              // Create log for the status change to null (in progress)
              TaskLogProvider().addTaskLog(
                existingTask,
                customStatus: null, // null status means "in progress"
              );
            }
          }
        }

        existingTask.time = taskModel.time;
        existingTask.isNotificationOn = taskModel.isNotificationOn;
        existingTask.isAlarmOn = taskModel.isAlarmOn;
        existingTask.remainingDuration = taskModel.remainingDuration;
        existingTask.targetCount = taskModel.targetCount;
        existingTask.attributeIDList = taskModel.attributeIDList;
        existingTask.skillIDList = taskModel.skillIDList;
        existingTask.priority = taskModel.priority;
        existingTask.categoryId = taskModel.categoryId;
        existingTask.earlyReminderMinutes = taskModel.earlyReminderMinutes;
        existingTask.location = taskModel.location;
        existingTask.subtasks = taskModel.subtasks;
        existingTask.attachmentPaths = taskModel.attachmentPaths;

        // Handle timer if active
        if (existingTask.isTimerActive != null && existingTask.isTimerActive!) {
          GlobalTimer().startStopTimer(taskModel: existingTask);
        }

        // Update notifications
        checkNotification(existingTask);

        // Save the task to Hive with better error handling
        try {
          debugPrint('Saving existing task to preserve Hive identity: ID=${existingTask.id}');
          await ServerManager().updateTask(taskModel: existingTask);
          debugPrint('Task successfully saved: ID=${existingTask.id}');
        } catch (e) {
          debugPrint('ERROR saving task: ID=${existingTask.id}, Error: $e');
          // Even if save fails, keep the changes in memory for now
        }
      } else {
        debugPrint('ERROR: Task not found in taskList: ID=${taskModel.id}');
      }
    }

    // Update home widget when task is edited
    HomeWidgetService.updateAllWidgets();

    // Notify listeners to update UI
    notifyListeners();
  }

  void updateItems() {
    notifyListeners();
  }

  void changeSelectedDate(DateTime selectedDateZ) {
    selectedDate = selectedDateZ;

    notifyListeners();
  }

  Future<void> changeTaskDate({
    required BuildContext context,
    required TaskModel taskModel,
    bool showUndo = true,
  }) async {
    DateTime? selectedDate = await Helper().selectDateWithQuickActions(
      context: context,
      initialDate: taskModel.taskDate,
    );

    // Check if user cancelled the dialog
    if (selectedDate == null) return;

    // Check if user selected "dateless" (epoch time marker)
    final bool isDateless = selectedDate.millisecondsSinceEpoch == 0;

    // Store original data for undo
    if (showUndo) {
      _dateChanges[taskModel.id] = _TaskDateChangeData(
        originalDate: taskModel.taskDate,
        originalStatus: taskModel.status,
        originalTimerActive: taskModel.isTimerActive,
      );
    }

    // Handle the selection
    if (!isDateless) {
      // User selected a specific date
      if (taskModel.time != null) {
        selectedDate = selectedDate.copyWith(hour: taskModel.time!.hour, minute: taskModel.time!.minute);
      }
    } else {
      // User selected dateless option
      selectedDate = null;
    }

    if (taskModel.type == TaskTypeEnum.TIMER && taskModel.isTimerActive == true) {
      taskModel.isTimerActive = false;
    } // Update task status based on the selected date
    if (selectedDate != null) {
      // Check if the selected date is in the past
      final now = DateTime.now();
      final selectedDateTime = selectedDate.copyWith(
        hour: taskModel.time?.hour ?? 23,
        minute: taskModel.time?.minute ?? 59,
        second: 59,
      );

      if (selectedDateTime.isBefore(now)) {
        // Task date is in the past, mark as overdue
        debugPrint('Setting task status to overdue due to past date: ID=${taskModel.id}, Title=${taskModel.title}');
        taskModel.status = TaskStatusEnum.OVERDUE;

        // Create log for overdue status
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: TaskStatusEnum.OVERDUE,
        );
      } else {
        // Task date is in the future or today, reset status to null (in progress)
        if (taskModel.status != null) {
          debugPrint('Resetting task status to null due to date change: ID=${taskModel.id}, Title=${taskModel.title}');
          taskModel.status = null;

          // Create log for the status change to null (in progress)
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: null, // null status means "in progress"
          );
        }
      }
    } else {
      // Dateless task, reset status to null
      if (taskModel.status != null) {
        debugPrint('Resetting task status to null due to dateless change: ID=${taskModel.id}, Title=${taskModel.title}');
        taskModel.status = null;

        // Create log for the status change to null (in progress)
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: null, // null status means "in progress"
        );
      }
    }

    taskModel.taskDate = selectedDate;

    ServerManager().updateTask(taskModel: taskModel);
    checkNotification(taskModel);

    if (showUndo) {
      // Show undo snackbar
      Helper().getUndoMessage(
        message: selectedDate != null ? LocaleKeys.TaskDateChanged.tr() : LocaleKeys.TaskMadeDateless.tr(),
        onUndo: () => _undoDateChange(taskModel.id),
        statusColor: selectedDate != null ? AppColors.main : AppColors.orange,
        statusWord: selectedDate != null ? LocaleKeys.Changed.tr() : LocaleKeys.Dateless.tr(),
        taskName: taskModel.title,
        dateInfo: selectedDate != null ? 'tarihi ${DateFormat('dd MMMM yyyy', 'tr').format(selectedDate)} olarak değiştirildi' : null,
        taskModel: taskModel, // Task'ı göster
      );

      // Set timer for permanent change
      _undoTimers['date_${taskModel.id}'] = Timer(const Duration(seconds: 3), () {
        _permanentlyChangeDateData(taskModel.id);
      });
    }

    // Update home widget when task date is changed
    HomeWidgetService.updateAllWidgets();

    notifyListeners();

    // Update home widget when task date is changed
    HomeWidgetService.updateAllWidgets();

    notifyListeners();
  }

  // Update task date without showing a dialog (for drag and drop functionality)
  void changeTaskDateWithoutDialog({
    required TaskModel taskModel,
    required DateTime newDate,
    bool showUndo = true,
  }) {
    debugPrint('Changing task date without dialog: ID=${taskModel.id}, Title=${taskModel.title}');

    // Preserve the time if it exists
    if (taskModel.time != null) {
      newDate = newDate.copyWith(hour: taskModel.time!.hour, minute: taskModel.time!.minute);
    }

    // Store original data for undo
    if (showUndo) {
      _dateChanges[taskModel.id] = _TaskDateChangeData(
        originalDate: taskModel.taskDate,
        originalStatus: taskModel.status,
        originalTimerActive: taskModel.isTimerActive,
      );
    }

    // Stop timer if active
    if (taskModel.type == TaskTypeEnum.TIMER && taskModel.isTimerActive == true) {
      taskModel.isTimerActive = false;
    } // Update task status based on the new date
    final now = DateTime.now();
    final newDateTime = newDate.copyWith(
      hour: taskModel.time?.hour ?? 23,
      minute: taskModel.time?.minute ?? 59,
      second: 59,
    );

    if (newDateTime.isBefore(now)) {
      // Task date is in the past, mark as overdue
      debugPrint('Setting task status to overdue due to past date: ID=${taskModel.id}, Title=${taskModel.title}');
      taskModel.status = TaskStatusEnum.OVERDUE;

      // Create log for overdue status
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.OVERDUE,
      );
    } else {
      // Task date is in the future or today, reset status to null (in progress)
      if (taskModel.status != null) {
        debugPrint('Resetting task status to null due to date change: ID=${taskModel.id}, Title=${taskModel.title}');
        taskModel.status = null;

        // Create log for the status change to null (in progress)
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: null, // null status means "in progress"
        );
      }
    }

    // Update the task date
    taskModel.taskDate = newDate;

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      debugPrint('Task saved after date change: ID=${taskModel.id}');
    } catch (e) {
      debugPrint('ERROR saving task after date change: $e');
    }

    // Update in storage
    ServerManager().updateTask(taskModel: taskModel);

    // Update notifications
    checkNotification(taskModel);

    if (showUndo) {
      // Show undo snackbar
      Helper().getUndoMessage(
        message: LocaleKeys.TaskDateChanged.tr(),
        onUndo: () => _undoDateChange(taskModel.id),
        statusColor: AppColors.main,
        statusWord: LocaleKeys.Changed.tr(),
        taskName: taskModel.title,
        dateInfo: 'tarihi ${DateFormat('dd MMMM yyyy', 'tr').format(newDate)} olarak değiştirildi',
        taskModel: taskModel, // Task'ı göster
      );

      // Set timer for permanent change
      _undoTimers['date_${taskModel.id}'] = Timer(const Duration(seconds: 3), () {
        _permanentlyChangeDateData(taskModel.id);
      });
    }

    // Update home widget when task date is changed
    HomeWidgetService.updateAllWidgets();

    notifyListeners();
  }

  // Task durumu değiştiğinde bildirimleri kontrol et
  void checkTaskStatusForNotifications(TaskModel taskModel) {
    // Eğer task tamamlandıysa, iptal edildiyse, başarısız olduysa veya tarihi geçmişse bildirimleri iptal et
    if (taskModel.status == TaskStatusEnum.DONE || taskModel.status == TaskStatusEnum.CANCEL || taskModel.status == TaskStatusEnum.FAILED || taskModel.status == TaskStatusEnum.OVERDUE) {
      // Task bildirimi iptal et
      NotificationService().cancelNotificationOrAlarm(taskModel.id);

      // Erken hatırlatma bildirimini iptal et
      NotificationService().cancelNotificationOrAlarm(taskModel.id + 300000);

      // Timer bildirimi iptal et (eğer varsa)
      if (taskModel.type == TaskTypeEnum.TIMER) {
        NotificationService().cancelNotificationOrAlarm(-taskModel.id);
        NotificationService().cancelNotificationOrAlarm(taskModel.id + 100000);
        NotificationService().cancelNotificationOrAlarm(taskModel.id + 200000);
      }
    } else {
      // Task durumu null ise (aktif) ve bildirim ayarları açıksa bildirimi yeniden planla
      checkNotification(taskModel);
    }
  }

  checkNotification(TaskModel taskModel) {
    debugPrint('=== checkNotification Debug ===');
    debugPrint('Task: ${taskModel.title} (ID: ${taskModel.id})');
    debugPrint('Time: ${taskModel.time}');
    debugPrint('Date: ${taskModel.taskDate}');
    debugPrint('Notification on: ${taskModel.isNotificationOn}');
    debugPrint('Alarm on: ${taskModel.isAlarmOn}');
    debugPrint('Status: ${taskModel.status}');

    // Önce mevcut bildirimi iptal et
    NotificationService().cancelNotificationOrAlarm(taskModel.id);

    // Eğer task tamamlandıysa, iptal edildiyse, başarısız olduysa veya tarihi geçmişse bildirim oluşturma
    if (taskModel.status == TaskStatusEnum.DONE || taskModel.status == TaskStatusEnum.CANCEL || taskModel.status == TaskStatusEnum.FAILED || taskModel.status == TaskStatusEnum.OVERDUE) {
      debugPrint('Task has done/cancelled/failed/overdue status, not scheduling notification');
      return;
    }

    // Bildirim veya alarm açıksa ve zaman ayarlanmışsa ve tarih ayarlanmışsa
    if (taskModel.time != null && taskModel.taskDate != null && (taskModel.isNotificationOn || taskModel.isAlarmOn)) {
      // Görev zamanı gelecekteyse bildirim planla
      DateTime taskDateTime = taskModel.taskDate!.copyWith(hour: taskModel.time!.hour, minute: taskModel.time!.minute, second: 0);

      debugPrint('Task DateTime: $taskDateTime');
      debugPrint('Current DateTime: ${DateTime.now()}');
      debugPrint('Is future: ${taskDateTime.isAfter(DateTime.now())}');

      if (taskDateTime.isAfter(DateTime.now())) {
        debugPrint('✓ Scheduling notification for: $taskDateTime');
        NotificationService().scheduleNotification(
          id: taskModel.id,
          title: taskModel.title,
          desc: "Don't forget!",
          scheduledDate: taskDateTime,
          isAlarm: taskModel.isAlarmOn,
          earlyReminderMinutes: taskModel.earlyReminderMinutes,
        );
      } else {
        debugPrint('✗ Task time is in the past, not scheduling notification');
      }
    } else {
      debugPrint('✗ Notification conditions not met (time: ${taskModel.time}, date: ${taskModel.taskDate}, notif: ${taskModel.isNotificationOn}, alarm: ${taskModel.isAlarmOn})');
    }
  }

  // iptal de kullanıcıya ceza yansıtılmayacak
  cancelTask(TaskModel taskModel) {
    debugPrint('Canceling task: ID=${taskModel.id}, Title=${taskModel.title}, Current Status=${taskModel.status}');
    if (taskModel.status == TaskStatusEnum.CANCEL) {
      debugPrint('Task is already CANCELED, checking date for overdue logic');
      // If already cancelled, check if task should be overdue based on date
      if (taskModel.taskDate != null) {
        final now = DateTime.now();
        final taskDateTime = taskModel.taskDate!.copyWith(
          hour: taskModel.time?.hour ?? 23,
          minute: taskModel.time?.minute ?? 59,
          second: 59,
        );

        debugPrint('Now: $now');
        debugPrint('Task DateTime: $taskDateTime');
        debugPrint('Is task date before now: ${taskDateTime.isBefore(now)}');

        if (taskDateTime.isBefore(now) && taskModel.status != TaskStatusEnum.DONE) {
          // Task date is in the past, mark as overdue only if not already completed
          debugPrint('Task was canceled but date is past, setting to overdue: ID=${taskModel.id}');
          taskModel.status = TaskStatusEnum.OVERDUE;

          // Create log for overdue status
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: TaskStatusEnum.OVERDUE,
          );
        } else {
          // Task date is in the future or today, set to in progress
          taskModel.status = null;
          debugPrint('Task was canceled but date is future/today, setting to in-progress: ID=${taskModel.id}');

          // Create log for the status change to null (in progress)
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: null, // null status means "in progress"
          );
        }
      } else {
        // Dateless task, set to in progress
        taskModel.status = null;
        debugPrint('Task was canceled but dateless, setting to in-progress: ID=${taskModel.id}');

        // Create log for the status change to null (in progress)
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: null, // null status means "in progress"
        );
      }
    } else {
      // Check if task was previously completed and subtract credit
      if (taskModel.status == TaskStatusEnum.DONE && taskModel.remainingDuration != null) {
        AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
      }

      // Set to cancelled, clearing any other status
      taskModel.status = TaskStatusEnum.CANCEL;
      debugPrint('Setting task to canceled');

      // Create log for cancelled task
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.CANCEL,
      );
    }

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      debugPrint('Task saved after status change: ID=${taskModel.id}');
    } catch (e) {
      debugPrint('ERROR saving task after status change: $e');
    }

    ServerManager().updateTask(taskModel: taskModel);
    HomeWidgetService.updateAllWidgets();

    // Bildirim durumunu kontrol et
    checkTaskStatusForNotifications(taskModel);

    // TODO: iptalde veya silem durumunda geri almak için mesaj çıkacak bir süre
    notifyListeners();
  }

  failedTask(TaskModel taskModel) {
    debugPrint('Marking task as failed: ID=${taskModel.id}, Title=${taskModel.title}, Current Status=${taskModel.status}');
    if (taskModel.status == TaskStatusEnum.FAILED) {
      debugPrint('Task is already FAILED, checking date for overdue logic');
      // If already failed, check if task should be overdue based on date
      if (taskModel.taskDate != null) {
        final now = DateTime.now();
        final taskDateTime = taskModel.taskDate!.copyWith(
          hour: taskModel.time?.hour ?? 23,
          minute: taskModel.time?.minute ?? 59,
          second: 59,
        );

        debugPrint('Now: $now');
        debugPrint('Task DateTime: $taskDateTime');
        debugPrint('Is task date before now: ${taskDateTime.isBefore(now)}');

        if (taskDateTime.isBefore(now) && taskModel.status != TaskStatusEnum.DONE) {
          // Task date is in the past, mark as overdue only if not already completed
          debugPrint('Task was failed but date is past, setting to overdue: ID=${taskModel.id}');
          taskModel.status = TaskStatusEnum.OVERDUE;

          // Create log for overdue status
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: TaskStatusEnum.OVERDUE,
          );
        } else {
          // Task date is in the future or today, set to in progress
          taskModel.status = null;
          debugPrint('Task was failed but date is future/today, setting to in-progress: ID=${taskModel.id}');

          // Create log for the status change to null (in progress)
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: null, // null status means "in progress"
          );
        }
      } else {
        // Dateless task, set to in progress
        taskModel.status = null;
        debugPrint('Task was failed but dateless, setting to in-progress: ID=${taskModel.id}');

        // Create log for the status change to null (in progress)
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: null, // null status means "in progress"
        );
      }
    } else {
      // Check if task was previously completed and subtract credit
      if (taskModel.status == TaskStatusEnum.DONE && taskModel.remainingDuration != null) {
        AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
      }

      // Set to failed, clearing any other status
      taskModel.status = TaskStatusEnum.FAILED;
      debugPrint('Setting task to failed');

      // Create log for failed task
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.FAILED,
      );
    }

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      debugPrint('Task saved after status change: ID=${taskModel.id}');
    } catch (e) {
      debugPrint('ERROR saving task after status change: $e');
    }

    ServerManager().updateTask(taskModel: taskModel);
    HomeWidgetService.updateAllWidgets();

    // Bildirim durumunu kontrol et
    checkTaskStatusForNotifications(taskModel);

    // TODO: iptalde veya silem durumunda geri almak için mesaj çıkacak bir süre
    notifyListeners();
  }

  /// Mark all routine tasks for the given date as skipped (Pas Geç).
  /// This sets their status to CANCEL so they won't be marked as FAILED
  /// by the daily routine processor when the next day arrives.
  Future<void> skipRoutinesForDate(DateTime date) async {
    try {
      final tasksToSkip = taskList.where((task) => task.routineID != null && task.taskDate != null && task.taskDate!.isSameDay(date) && task.status == null).toList();
      if (tasksToSkip.isEmpty) {
        Helper().getMessage(message: LocaleKeys.SkipRoutineNone.tr());
        return;
      }

      for (final task in tasksToSkip) {
        // Mark as cancelled so daily processor won't mark as failed
        task.status = TaskStatusEnum.CANCEL;

        // Create log entry for cancellation
        TaskLogProvider().addTaskLog(
          task,
          customStatus: TaskStatusEnum.CANCEL,
        );

        // Persist changes
        await ServerManager().updateTask(taskModel: task);

        // Cancel any scheduled notifications/alarms
        try {
          NotificationService().cancelNotificationOrAlarm(task.id);
          NotificationService().cancelNotificationOrAlarm(task.id + 300000);
          if (task.type == TaskTypeEnum.TIMER) {
            NotificationService().cancelNotificationOrAlarm(-task.id);
            NotificationService().cancelNotificationOrAlarm(task.id + 100000);
            NotificationService().cancelNotificationOrAlarm(task.id + 200000);
          }
        } catch (e) {
          debugPrint('Error cancelling notifications for skipped routine task: $e');
        }
      }

      // Update home widgets and notify UI
      HomeWidgetService.updateAllWidgets();
      notifyListeners();

      Helper().getMessage(message: LocaleKeys.SkipRoutineSuccess.tr());
    } catch (e) {
      debugPrint('Error while skipping routines for date $date: $e');
      Helper().getMessage(message: 'Hata: $e');
    }
  }

  // Delete a task with undo functionality
  Future<void> deleteTask(int taskID) async {
    final task = taskList.firstWhere((task) => task.id == taskID);

    // Store the task for potential undo
    _deletedTasks[taskID] = task; // Remove from UI immediately
    taskList.removeWhere((task) => task.id == taskID);
    notifyListeners();

    // Show undo snackbar
    Helper().getUndoMessage(
      message: LocaleKeys.TaskDeleted.tr(),
      onUndo: () => _undoDeleteTask(taskID),
      statusColor: AppColors.red,
      statusWord: LocaleKeys.Deleted.tr(),
      taskName: task.title,
      taskModel: task, // Task detay sayfasına gitmek için
    );

    // Set timer for permanent deletion
    _undoTimers['task_$taskID'] = Timer(const Duration(seconds: 3), () async {
      await _permanentlyDeleteTask(taskID);
    });
  }

  // Permanently delete a task
  Future<void> _permanentlyDeleteTask(int taskID) async {
    // Clean up undo data
    final task = _deletedTasks.remove(taskID);
    _undoTimers.remove('task_$taskID');
    if (task != null) {
      // First delete all logs associated with this task
      await TaskLogProvider().deleteLogsByTaskId(taskID);

      // Delete the task from storage (this also calls HiveService().deleteTask())
      await ServerManager().deleteTask(id: taskID);

      // Delete from Firestore only if offline mode is disabled
      if (!OfflineModeProvider().shouldDisableFirebase()) {
        SyncManager().deleteTaskFromFirestore(taskID);
      } else {
        debugPrint('Offline mode enabled, skipping Firestore deletion for task: $taskID');
      }

      await HomeWidgetService.updateTaskCount();

      // Cancel any notifications for this task
      await NotificationService().cancelNotificationOrAlarm(taskID);
    }
  }

  // Undo task deletion
  void _undoDeleteTask(int taskID) {
    final task = _deletedTasks.remove(taskID);
    final timer = _undoTimers.remove('task_$taskID');

    if (task != null && timer != null) {
      timer.cancel();
      taskList.add(task);
      notifyListeners();
    }
  }

  // Delete routine with undo functionality
  Future<void> deleteRoutine(int routineID) async {
    final routineModel = routineList.firstWhere((element) => element.id == routineID);
    final associatedTasks = taskList.where((task) => task.routineID == routineID).toList();

    // Store the routine and associated tasks for potential undo
    _deletedRoutines[routineID] = routineModel;
    for (final task in associatedTasks) {
      _deletedTasks[task.id] = task;
    } // Remove from UI immediately
    routineList.remove(routineModel);
    taskList.removeWhere((task) => task.routineID == routineID);
    notifyListeners(); // Show undo snackbar
    Helper().getUndoMessage(
      message: LocaleKeys.RoutineDeleted.tr(),
      onUndo: () => _undoDeleteRoutine(routineID),
      statusColor: AppColors.red,
      statusWord: LocaleKeys.Deleted.tr(),
      taskName: routineModel.title,
      taskModel: associatedTasks.isNotEmpty ? associatedTasks.first : null, // İlk task'ı göster
    );

    // Set timer for permanent deletion
    _undoTimers['routine_$routineID'] = Timer(const Duration(seconds: 3), () async {
      await _permanentlyDeleteRoutine(routineID);
    });
  }

  // Permanently delete a routine
  Future<void> _permanentlyDeleteRoutine(int routineID) async {
    // Clean up undo data
    final routine = _deletedRoutines.remove(routineID);
    _undoTimers.remove('routine_$routineID');

    if (routine != null) {
      // Delete all logs associated with this routine
      await TaskLogProvider().deleteLogsByRoutineId(routineID);

      // Delete all associated tasks and their logs
      final tasksToDelete = _deletedTasks.values.where((task) => task.routineID == routineID).toList();
      for (final task in tasksToDelete) {
        // Delete logs for each task
        await TaskLogProvider().deleteLogsByTaskId(task.id);

        // Cancel notifications
        NotificationService().cancelNotificationOrAlarm(task.id);

        // Delete the task
        await ServerManager().deleteTask(id: task.id);
        _deletedTasks.remove(task.id);
      }

      // Delete the routine
      await ServerManager().deleteRoutine(id: routine.id);
      HomeWidgetService.updateTaskCount();
    }
  }

  // Undo routine deletion
  void _undoDeleteRoutine(int routineID) {
    final routine = _deletedRoutines.remove(routineID);
    final timer = _undoTimers.remove('routine_$routineID');

    if (routine != null && timer != null) {
      timer.cancel();
      routineList.add(routine);

      // Restore associated tasks
      final associatedTasks = _deletedTasks.values.where((task) => task.routineID == routineID).toList();
      for (final task in associatedTasks) {
        taskList.add(task);
        _deletedTasks.remove(task.id);
      }

      notifyListeners();
    }
  }

  // TODO: just for routine
  // ? rutin model mi task model mi
  completeRoutine(TaskModel taskModel) {
    debugPrint('Completing routine task: ID=${taskModel.id}, Title=${taskModel.title}');

    // Clear any existing status before setting to DONE
    taskModel.status = TaskStatusEnum.DONE;

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      debugPrint('Task saved after completion: ID=${taskModel.id}');
    } catch (e) {
      debugPrint('ERROR saving task after completion: $e');
    }

    ServerManager().updateTask(taskModel: taskModel);
    HomeWidgetService.updateAllWidgets();

    // Bildirim durumunu kontrol et
    checkTaskStatusForNotifications(taskModel);

    // Create a log entry for the done task
    TaskLogProvider().addTaskLog(
      taskModel,
      customStatus: TaskStatusEnum.DONE,
    );

    // TODO: iptalde veya silem durumunda geri almak için mesaj çıkacak bir süre
    // TODO: arşivden çıkar ekle
    notifyListeners();
  }

  Future<void> changeShowCompleted() async {
    showCompleted = !showCompleted;

    // Değişikliği SharedPreferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_completed', showCompleted);

    notifyListeners();
  }

  // Toggle subtask visibility for a specific task
  void toggleTaskSubtaskVisibility(TaskModel taskModel) {
    taskModel.showSubtasks = !taskModel.showSubtasks;

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      debugPrint('Task saved after toggling subtask visibility: ID=${taskModel.id}');
    } catch (e) {
      debugPrint('ERROR saving task after toggling subtask visibility: $e');
    }

    ServerManager().updateTask(taskModel: taskModel);
    notifyListeners();
  }

  // Subtask methods
  void addSubtask(TaskModel taskModel, String subtaskTitle, [String? description]) {
    debugPrint('Adding subtask to task: ID=${taskModel.id}, Title=${taskModel.title}');

    taskModel.subtasks ??= [];

    // Generate a unique ID for the subtask
    int subtaskId = 1;
    if (taskModel.subtasks!.isNotEmpty) {
      subtaskId = taskModel.subtasks!.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    }

    final subtask = SubTaskModel(
      id: subtaskId,
      title: subtaskTitle,
      description: description,
    );

    taskModel.subtasks!.add(subtask);

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      debugPrint('Task saved after adding subtask: ID=${taskModel.id}');
    } catch (e) {
      debugPrint('ERROR saving task after adding subtask: $e');
    }
    ServerManager().updateTask(taskModel: taskModel);

    // If this is a routine task, propagate subtask changes to other instances
    if (taskModel.routineID != null) {
      _propagateSubtaskChangesToRoutineInstances(taskModel);
    }

    notifyListeners();
  }

  // Propagate subtask changes to all instances of a routine
  void _propagateSubtaskChangesToRoutineInstances(TaskModel sourceTask) {
    if (sourceTask.routineID == null) return;

    debugPrint('Propagating subtask changes for routine ID=${sourceTask.routineID}');
    final now = DateTime.now();

    // First, update the routine template so future ghost routines get the changes
    final routineIndex = routineList.indexWhere((routine) => routine.id == sourceTask.routineID);
    if (routineIndex != -1) {
      debugPrint('Updating routine template with subtask changes');
      routineList[routineIndex].subtasks = sourceTask.subtasks
          ?.map((subtask) => SubTaskModel(
                id: subtask.id,
                title: subtask.title,
                description: subtask.description,
                isCompleted: false, // Routine templates should have uncompleted subtasks
              ))
          .toList();

      // Save the updated routine
      ServerManager().updateRoutine(routineModel: routineList[routineIndex]);
    }

    // Update all tasks with the same routineID
    for (var task in taskList) {
      if (task.routineID == sourceTask.routineID && task.id != sourceTask.id) {
        // Check if this is a future task or current/past task
        final isFutureTask = task.taskDate != null && task.taskDate!.isAfter(now);

        // Create a deep copy of subtasks with appropriate completion status
        task.subtasks = sourceTask.subtasks
            ?.map((subtask) => SubTaskModel(
                  id: subtask.id,
                  title: subtask.title,
                  description: subtask.description,
                  // For future tasks, reset completion status; for current/past tasks, preserve it
                  isCompleted: isFutureTask ? false : subtask.isCompleted,
                ))
            .toList();

        // Save the updated task
        try {
          task.save();
          debugPrint('Task saved after subtask propagation: ID=${task.id}');
        } catch (e) {
          debugPrint('ERROR saving task after subtask propagation: $e');
        }

        ServerManager().updateTask(taskModel: task);
      }
    }
  }

  void removeSubtask(TaskModel taskModel, SubTaskModel subtask, {bool showUndo = true}) {
    if (taskModel.subtasks != null) {
      debugPrint('Removing subtask from task: TaskID=${taskModel.id}, SubtaskID=${subtask.id}');

      if (showUndo) {
        // Store the subtask for potential undo
        final undoKey = '${taskModel.id}_${subtask.id}';
        _deletedSubtasks[undoKey] = subtask;

        // Remove from UI immediately
        taskModel.subtasks!.removeWhere((s) => s.id == subtask.id);

        // Save the task to ensure changes are persisted
        try {
          taskModel.save();
          debugPrint('Task saved after removing subtask: ID=${taskModel.id}');
        } catch (e) {
          debugPrint('ERROR saving task after removing subtask: $e');
        }
        ServerManager().updateTask(taskModel: taskModel);

        // If this is a routine task, propagate subtask changes to other instances
        if (taskModel.routineID != null) {
          _propagateSubtaskChangesToRoutineInstances(taskModel);
        }

        notifyListeners(); // Show undo snackbar
        Helper().getUndoMessage(
          message: LocaleKeys.SubtaskDeleted.tr(),
          onUndo: () => _undoRemoveSubtask(taskModel, undoKey),
          statusColor: AppColors.red,
          statusWord: LocaleKeys.Deleted.tr(),
          taskName: subtask.title,
          taskModel: taskModel, // Ana task'ı göster
        );

        // Set timer for permanent deletion
        _undoTimers['subtask_$undoKey'] = Timer(const Duration(seconds: 3), () {
          _permanentlyRemoveSubtask(undoKey);
        });
      } else {
        // Direct removal without undo
        taskModel.subtasks!.removeWhere((s) => s.id == subtask.id);

        // Save the task to ensure changes are persisted
        try {
          taskModel.save();
          debugPrint('Task saved after removing subtask: ID=${taskModel.id}');
        } catch (e) {
          debugPrint('ERROR saving task after removing subtask: $e');
        }
        ServerManager().updateTask(taskModel: taskModel);

        // If this is a routine task, propagate subtask changes to other instances
        if (taskModel.routineID != null) {
          _propagateSubtaskChangesToRoutineInstances(taskModel);
        }

        notifyListeners();
      }
    }
  }

  void clearSubtasks(TaskModel taskModel) {
    if (taskModel.subtasks != null && taskModel.subtasks!.isNotEmpty) {
      debugPrint('Clearing all subtasks from task: TaskID=${taskModel.id}');

      // Clear the list
      taskModel.subtasks!.clear();

      // Save the task to ensure changes are persisted
      try {
        taskModel.save();
        debugPrint('Task saved after clearing subtasks: ID=${taskModel.id}');
      } catch (e) {
        debugPrint('ERROR saving task after clearing subtasks: $e');
      }
      ServerManager().updateTask(taskModel: taskModel);

      // If this is a routine task, propagate subtask changes to other instances
      if (taskModel.routineID != null) {
        _propagateSubtaskChangesToRoutineInstances(taskModel);
      }

      notifyListeners();
    }
  }

  // Permanently remove a subtask
  void _permanentlyRemoveSubtask(String undoKey) {
    _deletedSubtasks.remove(undoKey);
    _undoTimers.remove('subtask_$undoKey');
  }

  // Undo subtask removal
  void _undoRemoveSubtask(TaskModel taskModel, String undoKey) {
    final subtask = _deletedSubtasks.remove(undoKey);
    final timer = _undoTimers.remove('subtask_$undoKey');

    if (subtask != null && timer != null) {
      timer.cancel();
      taskModel.subtasks ??= [];
      taskModel.subtasks!.add(subtask);

      // Save the task to ensure changes are persisted
      try {
        taskModel.save();
        debugPrint('Task saved after restoring subtask: ID=${taskModel.id}');
      } catch (e) {
        debugPrint('ERROR saving task after restoring subtask: $e');
      }
      ServerManager().updateTask(taskModel: taskModel);

      // If this is a routine task, propagate subtask changes to other instances
      if (taskModel.routineID != null) {
        _propagateSubtaskChangesToRoutineInstances(taskModel);
      }

      notifyListeners();
    }
  }

  void toggleSubtaskCompletion(TaskModel taskModel, SubTaskModel subtask, {bool showUndo = true}) {
    if (taskModel.subtasks != null) {
      final index = taskModel.subtasks!.indexWhere((s) => s.id == subtask.id);
      if (index != -1) {
        bool wasCompleted = taskModel.subtasks![index].isCompleted;
        bool isBeingCompleted = !wasCompleted;

        taskModel.subtasks![index].isCompleted = !wasCompleted;

        debugPrint('Toggling subtask completion: TaskID=${taskModel.id}, SubtaskID=${subtask.id}, Completed=${!wasCompleted}');

        // Save the task to ensure changes are persisted
        try {
          taskModel.save();
          debugPrint('Task saved after toggling subtask: ID=${taskModel.id}');
        } catch (e) {
          debugPrint('ERROR saving task after toggling subtask: $e');
        }
        ServerManager().updateTask(taskModel: taskModel);

        // If this is a routine task, propagate subtask changes to other instances
        if (taskModel.routineID != null) {
          _propagateSubtaskChangesToRoutineInstances(taskModel);
        } // Alt görev tamamlandığında log oluştur
        if (isBeingCompleted) {
          // Alt görev tamamlandı
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: TaskStatusEnum.DONE,
          );

          // Show undo message for subtask completion
          if (showUndo) {
            Helper().getUndoMessage(
              // TODO: localization
              message: "Subtask marked as done",
              onUndo: () => toggleSubtaskCompletion(taskModel, subtask, showUndo: false),
              statusColor: AppColors.green,
              // TODO: localization
              statusWord: "done",
              taskName: subtask.title,
              taskModel: taskModel, // Ana task'ı göster
            );
          }
        }

        notifyListeners();
      }
    }
  }

  void updateSubtask(TaskModel taskModel, SubTaskModel subtask, String title, String? description) {
    if (taskModel.subtasks != null) {
      final index = taskModel.subtasks!.indexWhere((s) => s.id == subtask.id);
      if (index != -1) {
        debugPrint('Updating subtask: TaskID=${taskModel.id}, SubtaskID=${subtask.id}');

        // Update the subtask with new title and description
        taskModel.subtasks![index].title = title;
        taskModel.subtasks![index].description = description;

        // Save the task to ensure changes are persisted
        try {
          taskModel.save();
          debugPrint('Task saved after updating subtask: ID=${taskModel.id}');
        } catch (e) {
          debugPrint('ERROR saving task after updating subtask: $e');
        }

        // Save changes to server
        ServerManager().updateTask(taskModel: taskModel);

        // If this is a routine task, propagate subtask changes to other instances
        if (taskModel.routineID != null) {
          _propagateSubtaskChangesToRoutineInstances(taskModel);
        }

        notifyListeners();
      }
    }
  }

  // Öncelik ve zamana göre sıralama fonksiyonu
  void sortTasksByPriorityAndTime(List<TaskModel> tasks) {
    tasks.sort((a, b) {
      // Tamamlanmış, iptal edilmiş ve başarısız görevleri en alta koy
      if (a.status != null && b.status == null) return 1;
      if (a.status == null && b.status != null) return -1;

      // Önce önceliğe göre sırala
      int priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Öncelikler eşitse zamana göre sırala
      if (a.time != null && b.time != null) {
        return (a.time!.hour * 60 + a.time!.minute).compareTo(b.time!.hour * 60 + b.time!.minute);
      } else if (a.time != null) {
        return -1;
      } else if (b.time != null) {
        return 1;
      }
      return 0;
    });
  }

  List<TaskModel> getTasksForDate(DateTime date) {
    List<TaskModel> tasks;

    // Only apply showCompleted filter for today's date, not for historical dates
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

    if (isToday && !showCompleted) {
      // For today: filter out done tasks if showCompleted is false
      // Also exclude pinned tasks as they will be shown separately
      tasks = taskList.where((task) => task.checkForThisDate(date, isRoutine: false, isCompleted: true) && !task.isPinned).toList();
    } else {
      // For historical dates or when showCompleted is true: show all tasks
      // For non-today dates, don't separate pinned tasks
      tasks = taskList.where((task) => task.checkForThisDate(date, isRoutine: false, isCompleted: false)).toList();
    }

    sortTasksByPriorityAndTime(tasks);
    return tasks;
  }

  /// Get all pinned tasks (past, present, dateless) to show on today's view
  List<TaskModel> getPinnedTasksForToday() {
    // Get all pinned non-routine tasks regardless of date
    // Include: today's tasks, past tasks, future tasks, and dateless tasks
    final pinnedTasks = taskList.where((task) => task.isPinned && task.routineID == null && task.status != TaskStatusEnum.DONE && task.status != TaskStatusEnum.CANCEL && task.status != TaskStatusEnum.FAILED).toList();

    debugPrint('Found ${pinnedTasks.length} pinned tasks (all dates)');
    for (var task in pinnedTasks) {
      debugPrint('  - Pinned task: ${task.title} (Date: ${task.taskDate})');
    }

    sortTasksByPriorityAndTime(pinnedTasks);
    return pinnedTasks;
  }

  List<TaskModel> getRoutineTasksForDate(DateTime date) {
    // Check if vacation mode is enabled
    if (VacationModeProvider().isVacationModeEnabled) {
      return [];
    }

    List<TaskModel> tasks;

    // Only apply showCompleted filter for today's date, not for historical dates
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

    if (isToday && !showCompleted) {
      // For today: filter out completed tasks if showCompleted is false
      tasks = taskList.where((task) => task.checkForThisDate(date, isRoutine: true, isCompleted: true)).toList();
    } else {
      // For historical dates or when showCompleted is true: show all tasks
      tasks = taskList.where((task) => task.checkForThisDate(date, isRoutine: true, isCompleted: false)).toList();
    }

    sortTasksByPriorityAndTime(tasks);
    return tasks;
  }

  List<TaskModel> getGhostRoutineTasksForDate(DateTime date) {
    // Check if vacation mode is enabled
    if (VacationModeProvider().isVacationModeEnabled) {
      return [];
    }

    if (date.isBeforeOrSameDay(DateTime.now())) {
      return [];
    }

    List<TaskModel> tasks = routineList
        .where((routine) => routine.isActiveForThisDate(date))
        .map((routine) => TaskModel(
              routineID: routine.id,
              title: routine.title,
              description: routine.description,
              type: routine.type,
              taskDate: date,
              time: routine.time,
              isNotificationOn: routine.isNotificationOn,
              isAlarmOn: routine.isAlarmOn,
              currentDuration: routine.type == TaskTypeEnum.TIMER ? Duration.zero : null,
              remainingDuration: routine.remainingDuration,
              currentCount: routine.type == TaskTypeEnum.COUNTER ? 0 : null,
              targetCount: routine.targetCount,
              isTimerActive: routine.type == TaskTypeEnum.TIMER ? false : null,
              attributeIDList: routine.attirbuteIDList,
              skillIDList: routine.skillIDList,
              priority: routine.priority,
              categoryId: routine.categoryId,
              subtasks: routine.subtasks,
            ))
        .toList();

    sortTasksByPriorityAndTime(tasks);
    return tasks;
  }

  // Get all tasks with a specific category ID
  List<TaskModel> getTasksByCategoryId(int categoryId) {
    // Filter tasks by category ID
    List<TaskModel> tasks = taskList.where((task) => task.categoryId == categoryId).toList();

    // Sort tasks by date, priority, and time
    tasks.sort((a, b) {
      // First sort by date (null dates at the top)
      if (a.taskDate == null && b.taskDate == null) {
        // Both null, no sorting needed for date
      } else if (a.taskDate == null) {
        return -1; // a is null, so it comes first
      } else if (b.taskDate == null) {
        return 1; // b is null, so it comes first
      } else {
        // Both have dates, compare them
        int dateCompare = a.taskDate!.compareTo(b.taskDate!);
        if (dateCompare != 0) return dateCompare;
      }

      // If same date, sort by status (active tasks first)
      if (a.status != null && b.status == null) return 1;
      if (a.status == null && b.status != null) return -1;

      // Then by priority
      int priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Finally by time if available
      if (a.time != null && b.time != null) {
        return (a.time!.hour * 60 + a.time!.minute).compareTo(b.time!.hour * 60 + b.time!.minute);
      } else if (a.time != null) {
        return -1;
      } else if (b.time != null) {
        return 1;
      }

      return 0;
    });

    return tasks;
  }

  // Get all tasks regardless of category
  List<TaskModel> getAllTasks() {
    // Get all tasks
    List<TaskModel> tasks = List.from(taskList);

    // Sort tasks by date, priority, and time
    tasks.sort((a, b) {
      // First sort by date (null dates at the top)
      if (a.taskDate == null && b.taskDate == null) {
        // Both null, no sorting needed for date
      } else if (a.taskDate == null) {
        return -1; // a is null, so it comes first
      } else if (b.taskDate == null) {
        return 1; // b is null, so it comes first
      } else {
        // Both have dates, compare them
        int dateCompare = a.taskDate!.compareTo(b.taskDate!);
        if (dateCompare != 0) return dateCompare;
      }

      // If same date, sort by status (active tasks first)
      if (a.status != null && b.status == null) return 1;
      if (a.status == null && b.status != null) return -1;

      // Then by priority
      int priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Finally by time if available
      if (a.time != null && b.time != null) {
        return (a.time!.hour * 60 + a.time!.minute).compareTo(b.time!.hour * 60 + b.time!.minute);
      } else if (a.time != null) {
        return -1;
      } else if (b.time != null) {
        return 1;
      }

      return 0;
    });

    return tasks;
  }

  // Date change undo methods
  void _permanentlyChangeDateData(int taskId) {
    _dateChanges.remove(taskId);
    _undoTimers.remove('date_$taskId');
  }

  void _undoDateChange(int taskId) {
    final changeData = _dateChanges.remove(taskId);
    final timer = _undoTimers.remove('date_$taskId');

    if (changeData != null && timer != null) {
      timer.cancel();

      // Find the task and restore its original data
      final taskIndex = taskList.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = taskList[taskIndex];

        // Restore original values
        task.taskDate = changeData.originalDate;
        task.status = changeData.originalStatus;
        task.isTimerActive = changeData.originalTimerActive;

        // Save the task to ensure changes are persisted
        try {
          task.save();
          debugPrint('Task saved after undoing date change: ID=${task.id}');
        } catch (e) {
          debugPrint('ERROR saving task after undoing date change: $e');
        }

        // Update in storage
        ServerManager().updateTask(taskModel: task);

        // Update notifications
        checkNotification(task);

        // If status was restored, create a log entry
        if (changeData.originalStatus != null) {
          TaskLogProvider().addTaskLog(
            task,
            customStatus: changeData.originalStatus,
          );
        }

        notifyListeners();
      }
    }
  }

  // Complete a task with undo functionality
  void completeTaskWithUndo(TaskModel taskModel, {bool showUndo = true}) {
    debugPrint('Completing checkbox task with undo: ID=${taskModel.id}, Title=${taskModel.title}');

    if (showUndo) {
      // Store the previous status for potential undo
      _completedTasks[taskModel.id] = _TaskCompletionData(
        previousStatus: taskModel.status,
      );
    }

    // Mark task as completed
    taskModel.status = TaskStatusEnum.DONE;

    // Award credits for completing the task
    if (taskModel.remainingDuration != null) {
      AppHelper().addCreditByProgress(taskModel.remainingDuration);
    }

    // Create log for completed checkbox task
    TaskLogProvider().addTaskLog(
      taskModel,
      customStatus: TaskStatusEnum.DONE,
    );

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      debugPrint('Task saved after completion: ID=${taskModel.id}');
    } catch (e) {
      debugPrint('ERROR saving task after completion: $e');
    }

    ServerManager().updateTask(taskModel: taskModel);

    // Sync to Firebase immediately
    SyncManager().syncTask(taskModel);

    HomeWidgetService.updateAllWidgets();

    // Check task status for notifications
    checkTaskStatusForNotifications(taskModel);

    notifyListeners();

    if (showUndo) {
      // Show undo snackbar
      Helper().getUndoMessage(
        message: "Task marked as done",
        onUndo: () => _undoTaskCompletion(taskModel.id),
        statusColor: AppColors.green,
        statusWord: "done",
        taskName: taskModel.title,
        taskModel: taskModel, // Task'ı göster
      );

      // Set timer for permanent completion
      _undoTimers['completion_${taskModel.id}'] = Timer(const Duration(seconds: 3), () {
        _permanentlyCompleteTask(taskModel.id);
      });
    }
  }

  // Permanently complete a task (remove undo data)
  void _permanentlyCompleteTask(int taskId) {
    _completedTasks.remove(taskId);
    _undoTimers.remove('completion_$taskId');
  }

  // Undo task completion
  void _undoTaskCompletion(int taskId) {
    final completionData = _completedTasks.remove(taskId);
    final timer = _undoTimers.remove('completion_$taskId');

    if (completionData != null && timer != null) {
      timer.cancel();

      // Find the task and restore its previous status
      final taskIndex = taskList.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = taskList[taskIndex]; // Restore previous status, but check for overdue if previous was null
        if (completionData.previousStatus == null) {
          // Check if task should be overdue based on date
          if (task.taskDate != null) {
            final now = DateTime.now();
            final taskDateTime = task.taskDate!.copyWith(
              hour: task.time?.hour ?? 23,
              minute: task.time?.minute ?? 59,
              second: 59,
            );

            if (taskDateTime.isBefore(now)) {
              // Task date is in the past, mark as overdue
              debugPrint('Undoing completion but date is past, setting to overdue: ID=${task.id}');
              task.status = TaskStatusEnum.OVERDUE;

              // Create log entry for overdue status
              TaskLogProvider().addTaskLog(
                task,
                customStatus: TaskStatusEnum.OVERDUE,
              );
            } else {
              // Task date is in the future or today, set to in progress
              task.status = null;

              // Create log entry for the status change
              TaskLogProvider().addTaskLog(
                task,
                customStatus: null,
              );
            }
          } else {
            // Dateless task, set to in progress
            task.status = null;

            // Create log entry for the status change
            TaskLogProvider().addTaskLog(
              task,
              customStatus: null,
            );
          }
        } else {
          // Restore previous status as is
          task.status = completionData.previousStatus;

          // Create log entry for the status change
          TaskLogProvider().addTaskLog(
            task,
            customStatus: completionData.previousStatus,
          );
        }

        // Subtract credit for undoing completion
        if (task.remainingDuration != null) {
          AppHelper().addCreditByProgress(-task.remainingDuration!);
        }

        // Save the task to ensure changes are persisted
        try {
          task.save();
          debugPrint('Task saved after undoing completion: ID=${task.id}');
        } catch (e) {
          debugPrint('ERROR saving task after undoing completion: $e');
        }

        // Update in storage
        ServerManager().updateTask(taskModel: task);

        // Sync to Firebase immediately
        SyncManager().syncTask(task);

        // Update notifications
        checkNotification(task);

        notifyListeners();
      }
    }
  }

  // Unarchive routine
  Future<void> unarchiveRoutine(int routineID) async {
    debugPrint('Unarchiving routine: ID=$routineID');

    final routineModel = routineList.firstWhere((element) => element.id == routineID);

    // Mark routine as not archived
    routineModel.isArchived = false;

    // Update the routine
    await ServerManager().updateRoutine(routineModel: routineModel);

    // Mark all related tasks as active (null status) if they were archived
    final associatedTasks = taskList.where((task) => task.routineID == routineID).toList();
    for (final task in associatedTasks) {
      if (task.status == TaskStatusEnum.ARCHIVED) {
        // Check if task should be overdue based on date
        if (task.taskDate != null) {
          final now = DateTime.now();
          final taskDateTime = task.taskDate!.copyWith(
            hour: task.time?.hour ?? 23,
            minute: task.time?.minute ?? 59,
            second: 59,
          );

          if (taskDateTime.isBefore(now)) {
            // Task date is in the past, mark as failed (since it's a routine task)
            task.status = TaskStatusEnum.FAILED;
            debugPrint('Unarchived routine task but date is past, setting to failed: ID=${task.id}');

            // Create log for the status change to failed
            TaskLogProvider().addTaskLog(
              task,
              customStatus: TaskStatusEnum.FAILED,
            );
          } else {
            // Task date is in the future or today, set to active state
            task.status = null;
            debugPrint('Unarchived routine task with future/today date, setting to active: ID=${task.id}');

            // Create log for the status change to active
            TaskLogProvider().addTaskLog(
              task,
              customStatus: null,
            );
          }
        } else {
          // No date set, set to active state
          task.status = null;
          debugPrint('Unarchived routine task without date, setting to active: ID=${task.id}');

          // Create log for the status change to active
          TaskLogProvider().addTaskLog(
            task,
            customStatus: null,
          );
        }

        // Fix null values for task properties that might be corrupted during archiving
        if (task.type == TaskTypeEnum.TIMER) {
          if (task.isTimerActive == null) {
            task.isTimerActive = false;
            debugPrint('Fixed null isTimerActive for timer task: ID=${task.id}');
          }
          if (task.currentDuration == null) {
            task.currentDuration = Duration.zero;
            debugPrint('Fixed null currentDuration for timer task: ID=${task.id}');
          }
          if (task.remainingDuration == null) {
            task.remainingDuration = const Duration(minutes: 30); // Default 30 minutes
            debugPrint('Fixed null remainingDuration for timer task: ID=${task.id}');
          }
        } else if (task.type == TaskTypeEnum.COUNTER) {
          if (task.currentCount == null) {
            task.currentCount = 0;
            debugPrint('Fixed null currentCount for counter task: ID=${task.id}');
          }
          if (task.targetCount == null) {
            task.targetCount = 1;
            debugPrint('Fixed null targetCount for counter task: ID=${task.id}');
          }
        }

        await ServerManager().updateTask(taskModel: task);
      }
    }

    // Create tasks for the current period if needed
    // This ensures that if a routine is unarchived, it will create new tasks from today onwards
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if routine should be active today and create task if it doesn't exist
    if (routineModel.isActiveForThisDate(today)) {
      final todayTaskExists = taskList.any((task) => task.routineID == routineID && task.taskDate != null && task.taskDate!.year == today.year && task.taskDate!.month == today.month && task.taskDate!.day == today.day);

      if (!todayTaskExists) {
        debugPrint('Creating new task for unarchived routine today: ${routineModel.title}');
        // Create task for today
        await _createTaskFromRoutine(routineModel, today);
      }
    }

    notifyListeners();
  }

  // Helper method to create a task from a routine for a specific date
  Future<void> _createTaskFromRoutine(RoutineModel routine, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final int lastTaskId = prefs.getInt("last_task_id") ?? 0;
    final int newTaskId = lastTaskId + 1;

    final TaskModel task = TaskModel(
      id: newTaskId,
      title: routine.title,
      description: routine.description,
      taskDate: date,
      status: null,
      type: routine.type,
      isNotificationOn: routine.isNotificationOn,
      isAlarmOn: routine.isAlarmOn,
      priority: routine.priority,
      routineID: routine.id,
      time: routine.time,
      attributeIDList: routine.attirbuteIDList,
      skillIDList: routine.skillIDList,
      categoryId: routine.categoryId,
      remainingDuration: routine.remainingDuration,
      targetCount: routine.targetCount,
      subtasks: routine.subtasks
          ?.map((subtask) => SubTaskModel(
                id: subtask.id,
                title: subtask.title,
                description: subtask.description,
                isCompleted: false,
              ))
          .toList(),
      earlyReminderMinutes: routine.earlyReminderMinutes,
    );

    // Add to task list and save
    taskList.add(task);
    await ServerManager().addTask(taskModel: task);
    await prefs.setInt("last_task_id", newTaskId);

    // Set up notifications if needed
    checkNotification(task);

    debugPrint('Created new task from routine: ID=$newTaskId, Title=${task.title}');
  }

  // Get overdue tasks (only for display purposes, not filtered by date)
  List<TaskModel> getOverdueTasks() {
    List<TaskModel> overdueTasks = taskList.where((task) => task.status == TaskStatusEnum.OVERDUE && task.routineID == null).toList();

    sortTasksByPriorityAndTime(overdueTasks);
    return overdueTasks;
  }

  // Get archived routines
  List<RoutineModel> getArchivedRoutines() {
    return routineList.where((routine) => routine.isArchived).toList();
  } // Show undo message for task failure

  void showTaskFailureUndo(TaskModel taskModel) {
    showTaskFailureUndoWithPreviousStatus(taskModel, taskModel.status);
  }

  // Show undo message for task failure with previous status
  void showTaskFailureUndoWithPreviousStatus(TaskModel taskModel, TaskStatusEnum? previousStatus) {
    // Store the previous status for potential undo
    _failedTasks[taskModel.id] = _TaskFailureData(
      previousStatus: previousStatus,
    );

    // Show undo snackbar
    Helper().getUndoMessage(
      message: "Task marked as failed",
      onUndo: () => _undoTaskFailure(taskModel.id),
      statusColor: AppColors.red,
      statusWord: "failed",
      taskName: taskModel.title,
      taskModel: taskModel, // Task'ı göster
    );

    // Set timer for permanent failure
    _undoTimers['failure_${taskModel.id}'] = Timer(const Duration(seconds: 3), () {
      _permanentlyFailTask(taskModel.id);
    });
  }

  // Show undo message for task cancellation
  void showTaskCancellationUndo(TaskModel taskModel) {
    showTaskCancellationUndoWithPreviousStatus(taskModel, taskModel.status);
  }

  // Show undo message for task cancellation with previous status
  void showTaskCancellationUndoWithPreviousStatus(TaskModel taskModel, TaskStatusEnum? previousStatus) {
    // Store the previous status for potential undo
    _cancelledTasks[taskModel.id] = _TaskCancellationData(
      previousStatus: previousStatus,
    ); // Show undo snackbar
    Helper().getUndoMessage(
      // TODO: localization
      message: "Task marked as cancelled",
      onUndo: () => _undoTaskCancellation(taskModel.id),
      statusColor: AppColors.purple,
      // TODO: localization
      statusWord: "cancelled",
      taskName: taskModel.title,
      taskModel: taskModel, // Task'ı göster
    );

    // Set timer for permanent cancellation
    _undoTimers['cancellation_${taskModel.id}'] = Timer(const Duration(seconds: 3), () {
      _permanentlyCancelTask(taskModel.id);
    });
  }

  // Undo task failure
  void _undoTaskFailure(int taskId) {
    final failureData = _failedTasks.remove(taskId);
    final timer = _undoTimers.remove('failure_$taskId');

    if (failureData != null && timer != null) {
      timer.cancel();

      // Find the task and restore its previous status
      final taskIndex = taskList.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = taskList[taskIndex];

        // Restore previous status, but check for overdue if previous was null
        if (failureData.previousStatus == null) {
          // Check if task should be overdue based on date
          if (task.taskDate != null) {
            final now = DateTime.now();
            final taskDateTime = task.taskDate!.copyWith(
              hour: task.time?.hour ?? 23,
              minute: task.time?.minute ?? 59,
              second: 59,
            );

            if (taskDateTime.isBefore(now)) {
              // Task date is in the past, mark as overdue
              debugPrint('Undoing failure but date is past, setting to overdue: ID=${task.id}');
              task.status = TaskStatusEnum.OVERDUE;

              // Create log entry for overdue status
              TaskLogProvider().addTaskLog(
                task,
                customStatus: TaskStatusEnum.OVERDUE,
              );
            } else {
              // Task date is in the future or today, set to in progress
              task.status = null;

              // Create log entry for the status change
              TaskLogProvider().addTaskLog(
                task,
                customStatus: null,
              );
            }
          } else {
            // No date set, restore to null
            task.status = null;

            // Create log entry for the status change
            TaskLogProvider().addTaskLog(
              task,
              customStatus: null,
            );
          }
        } else {
          // Restore to previous non-null status
          task.status = failureData.previousStatus;

          // Create log entry for the status change
          TaskLogProvider().addTaskLog(
            task,
            customStatus: failureData.previousStatus,
          );
        }

        // Save the task
        try {
          task.save();
          debugPrint('Task saved after undoing failure: ID=${task.id}');
        } catch (e) {
          debugPrint('ERROR saving task after undoing failure: $e');
        }

        // Update in storage
        ServerManager().updateTask(taskModel: task);

        // Sync to Firebase immediately
        SyncManager().syncTask(task);

        // Update notifications
        checkNotification(task);

        // Create log entry for the status change
        TaskLogProvider().addTaskLog(
          task,
          customStatus: failureData.previousStatus,
        );

        // Update UI
        notifyListeners();
      }
    }
  }

  // Undo task cancellation
  void _undoTaskCancellation(int taskId) {
    final cancellationData = _cancelledTasks.remove(taskId);
    final timer = _undoTimers.remove('cancellation_$taskId');

    if (cancellationData != null && timer != null) {
      timer.cancel();

      // Find the task and restore its previous status
      final taskIndex = taskList.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = taskList[taskIndex];

        // Restore previous status, but check for overdue if previous was null
        if (cancellationData.previousStatus == null) {
          // Check if task should be overdue based on date
          if (task.taskDate != null) {
            final now = DateTime.now();
            final taskDateTime = task.taskDate!.copyWith(
              hour: task.time?.hour ?? 23,
              minute: task.time?.minute ?? 59,
              second: 59,
            );

            if (taskDateTime.isBefore(now)) {
              // Task date is in the past, mark as overdue
              debugPrint('Undoing cancellation but date is past, setting to overdue: ID=${task.id}');
              task.status = TaskStatusEnum.OVERDUE;

              // Create log entry for overdue status
              TaskLogProvider().addTaskLog(
                task,
                customStatus: TaskStatusEnum.OVERDUE,
              );
            } else {
              // Task date is in the future or today, set to in progress
              task.status = null;

              // Create log entry for the status change
              TaskLogProvider().addTaskLog(
                task,
                customStatus: null,
              );
            }
          } else {
            // No date set, restore to null
            task.status = null;

            // Create log entry for the status change
            TaskLogProvider().addTaskLog(
              task,
              customStatus: null,
            );
          }
        } else {
          // Restore to previous non-null status
          task.status = cancellationData.previousStatus;

          // Create log entry for the status change
          TaskLogProvider().addTaskLog(
            task,
            customStatus: cancellationData.previousStatus,
          );
        }

        // Save the task
        try {
          task.save();
          debugPrint('Task saved after undoing cancellation: ID=${task.id}');
        } catch (e) {
          debugPrint('ERROR saving task after undoing cancellation: $e');
        }

        // Update in storage
        ServerManager().updateTask(taskModel: task);

        // Sync to Firebase immediately
        SyncManager().syncTask(task);

        // Update notifications
        checkNotification(task);

        // Create log entry for the status change
        TaskLogProvider().addTaskLog(
          task,
          customStatus: cancellationData.previousStatus,
        ); // Update UI
        notifyListeners();
      }
    }
  }

  // Permanently fail a task (remove undo data)
  void _permanentlyFailTask(int taskId) {
    _undoTimers.remove('failure_$taskId');
  }

  // Permanently cancel a task (remove undo data)
  void _permanentlyCancelTask(int taskId) {
    _undoTimers.remove('cancellation_$taskId');
  }
}
