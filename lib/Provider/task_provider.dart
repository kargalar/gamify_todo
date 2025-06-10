import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Service/app_helper.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/server_manager.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
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

  // Load categories when tasks are loaded
  Future<void> loadCategories() async {
    final categories = await ServerManager().getCategories();
    CategoryProvider().categoryList = categories;
  }

  // TODO: saat 00:00:00 geçtikten sonra hala dünü gösterecek muhtemelen her ana sayfaya gidişte. bunu düzelt. yani değişken uygulama açıldığında belirlendiği için 12 den sonra değişmeyecek.
  DateTime selectedDate = DateTime.now();
  bool showCompleted = true;

  // Uygulama başladığında showCompleted durumunu SharedPreferences'dan yükle
  Future<void> loadShowCompletedState() async {
    final prefs = await SharedPreferences.getInstance();
    showCompleted = prefs.getBool('show_completed') ?? true;
    notifyListeners();
  }

  void addTask(TaskModel taskModel) async {
    final int taskId = await ServerManager().addTask(taskModel: taskModel);

    taskModel.id = taskId;

    taskList.add(taskModel);

    if (taskModel.time != null) {
      checkNotification(taskModel);
    }

    // Update home widget when task is added
    HomeWidgetService.updateAllWidgets();

    notifyListeners();
  }

  Future addRoutine(RoutineModel routineModel) async {
    final int routineId = await ServerManager().addRoutine(routineModel: routineModel);

    routineModel.id = routineId;

    routineList.add(routineModel);
  }

  void editTask({
    required TaskModel taskModel,
    required List<int> selectedDays,
  }) {
    debugPrint('Editing task: ID=${taskModel.id}, Title=${taskModel.title}');

    if (taskModel.routineID != null) {
      // Editing a task that belongs to a routine
      debugPrint('Task belongs to routine ID=${taskModel.routineID}');

      // Find the routine in the list
      RoutineModel routine = routineList.firstWhere((element) => element.id == taskModel.routineID);

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
      routine.isArchived = taskModel.status == TaskStatusEnum.COMPLETED ? true : false;
      routine.priority = taskModel.priority;
      routine.categoryId = taskModel.categoryId;
      routine.earlyReminderMinutes = taskModel.earlyReminderMinutes;

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
          task.remainingDuration = task.taskDate != null && task.taskDate!.isSameDay(DateTime.now()) ? taskModel.remainingDuration : task.remainingDuration;
          task.targetCount = task.taskDate != null && task.taskDate!.isSameDay(DateTime.now()) ? taskModel.targetCount : task.targetCount;
          task.isNotificationOn = taskModel.isNotificationOn;
          task.isAlarmOn = taskModel.isAlarmOn;
          task.time = taskModel.time;
          task.priority = taskModel.priority;
          task.categoryId = taskModel.categoryId;
          task.earlyReminderMinutes = taskModel.earlyReminderMinutes;
          task.location = taskModel.location;
          task.subtasks = taskModel.subtasks;

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
    } else {
      // Editing a standalone task
      debugPrint('Editing standalone task');

      // Find the task in the list and replace it
      final index = taskList.indexWhere((element) => element.id == taskModel.id);
      if (index != -1) {
        debugPrint('Found task in taskList at index $index: ID=${taskModel.id}');

        // Check if we're replacing with a new instance or using the existing one
        final bool isExistingInstance = identical(taskList[index], taskModel);
        debugPrint('Using existing task instance: $isExistingInstance');

        if (!isExistingInstance) {
          debugPrint('WARNING: Replacing task with new instance may lose Hive object identity');
          taskList[index] = taskModel;
        }

        // Handle timer if active
        if (taskModel.isTimerActive != null && taskModel.isTimerActive!) {
          GlobalTimer().startStopTimer(taskModel: taskModel);
        }

        // Update notifications
        checkNotification(taskModel);

        // Save the task to Hive
        debugPrint('Updating task in Hive: ID=${taskModel.id}');
        ServerManager().updateTask(taskModel: taskModel);
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
    }

    // Reset status to null when date is changed
    if (taskModel.status != null) {
      debugPrint('Resetting task status to null due to date change: ID=${taskModel.id}, Title=${taskModel.title}');
      taskModel.status = null;

      // Create log for the status change to null (in progress)
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: null, // null status means "in progress"
      );
    }

    taskModel.taskDate = selectedDate;

    ServerManager().updateTask(taskModel: taskModel);
    checkNotification(taskModel);

    if (showUndo) {
      // Show undo snackbar
      Helper().getUndoMessage(
        message: selectedDate != null ? "Task date changed" : "Task made dateless",
        onUndo: () => _undoDateChange(taskModel.id),
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
    }

    // Reset status to null when date is changed
    if (taskModel.status != null) {
      debugPrint('Resetting task status to null due to date change: ID=${taskModel.id}, Title=${taskModel.title}');
      taskModel.status = null;

      // Create log for the status change to null (in progress)
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: null, // null status means "in progress"
      );
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
        message: "Task date changed",
        onUndo: () => _undoDateChange(taskModel.id),
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
    if (taskModel.status == TaskStatusEnum.COMPLETED || taskModel.status == TaskStatusEnum.CANCEL || taskModel.status == TaskStatusEnum.FAILED || taskModel.status == TaskStatusEnum.OVERDUE) {
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
    if (taskModel.status == TaskStatusEnum.COMPLETED || taskModel.status == TaskStatusEnum.CANCEL || taskModel.status == TaskStatusEnum.FAILED || taskModel.status == TaskStatusEnum.OVERDUE) {
      debugPrint('Task has completed/cancelled/failed/overdue status, not scheduling notification');
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
    debugPrint('Canceling task: ID=${taskModel.id}, Title=${taskModel.title}');

    if (taskModel.status == TaskStatusEnum.CANCEL) {
      // If already cancelled, set to null (in progress)
      taskModel.status = null;
      debugPrint('Task was already canceled, setting to in-progress');

      // Create log for the status change to null (in progress)
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: null, // null status means "in progress"
      );
    } else {
      // Check if task was previously completed and subtract credit
      if (taskModel.status == TaskStatusEnum.COMPLETED && taskModel.remainingDuration != null) {
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
    debugPrint('Marking task as failed: ID=${taskModel.id}, Title=${taskModel.title}');

    if (taskModel.status == TaskStatusEnum.FAILED) {
      // If already failed, set to null (in progress)
      taskModel.status = null;
      debugPrint('Task was already failed, setting to in-progress');

      // Create log for the status change to null (in progress)
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: null, // null status means "in progress"
      );
    } else {
      // Check if task was previously completed and subtract credit
      if (taskModel.status == TaskStatusEnum.COMPLETED && taskModel.remainingDuration != null) {
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

  // Delete a task with undo functionality
  Future<void> deleteTask(int taskID) async {
    final task = taskList.firstWhere((task) => task.id == taskID);

    // Store the task for potential undo
    _deletedTasks[taskID] = task;

    // Remove from UI immediately
    taskList.removeWhere((task) => task.id == taskID);
    notifyListeners();

    // Show undo snackbar
    Helper().getUndoMessage(
      message: "Task deleted",
      onUndo: () => _undoDeleteTask(taskID),
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

      // Delete the task from storage
      await ServerManager().deleteTask(id: taskID);
      await HiveService().deleteTask(taskID);
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
    }

    // Remove from UI immediately
    routineList.remove(routineModel);
    taskList.removeWhere((task) => task.routineID == routineID);
    notifyListeners();

    // Show undo snackbar
    Helper().getUndoMessage(
      message: "Routine deleted",
      onUndo: () => _undoDeleteRoutine(routineID),
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

    // Clear any existing status before setting to COMPLETED
    taskModel.status = TaskStatusEnum.COMPLETED;

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

    // Create a log entry for the completed task
    TaskLogProvider().addTaskLog(
      taskModel,
      customStatus: TaskStatusEnum.COMPLETED,
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

    notifyListeners();
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
        notifyListeners();

        // Show undo snackbar
        Helper().getUndoMessage(
          message: "Subtask deleted",
          onUndo: () => _undoRemoveSubtask(taskModel, undoKey),
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
        notifyListeners();
      }
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

        // Alt görev tamamlandığında log oluştur
        if (isBeingCompleted) {
          // Alt görev tamamlandı
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: TaskStatusEnum.COMPLETED,
          );

          // Show undo message for subtask completion
          if (showUndo) {
            Helper().getUndoMessage(
              message: "Subtask completed",
              onUndo: () => toggleSubtaskCompletion(taskModel, subtask, showUndo: false),
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
      // For today: filter out completed tasks if showCompleted is false
      tasks = taskList.where((task) => task.checkForThisDate(date, isRoutine: false, isCompleted: true)).toList();
    } else {
      // For historical dates or when showCompleted is true: show all tasks
      tasks = taskList.where((task) => task.checkForThisDate(date, isRoutine: false, isCompleted: false)).toList();
    }

    sortTasksByPriorityAndTime(tasks);
    return tasks;
  }

  List<TaskModel> getRoutineTasksForDate(DateTime date) {
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
    taskModel.status = TaskStatusEnum.COMPLETED;

    // Award credits for completing the task
    if (taskModel.remainingDuration != null) {
      AppHelper().addCreditByProgress(taskModel.remainingDuration);
    }

    // Create log for completed checkbox task
    TaskLogProvider().addTaskLog(
      taskModel,
      customStatus: TaskStatusEnum.COMPLETED,
    );

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      debugPrint('Task saved after completion: ID=${taskModel.id}');
    } catch (e) {
      debugPrint('ERROR saving task after completion: $e');
    }

    ServerManager().updateTask(taskModel: taskModel);
    HomeWidgetService.updateAllWidgets();

    // Check task status for notifications
    checkTaskStatusForNotifications(taskModel);

    notifyListeners();

    if (showUndo) {
      // Show undo snackbar
      Helper().getUndoMessage(
        message: "Task completed",
        onUndo: () => _undoTaskCompletion(taskModel.id),
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
        final task = taskList[taskIndex];

        // Restore previous status
        task.status = completionData.previousStatus;

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

        // Update notifications
        checkNotification(task);

        // Create log entry for the status change
        TaskLogProvider().addTaskLog(
          task,
          customStatus: completionData.previousStatus,
        );

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
        task.status = null; // Set to active state
        await ServerManager().updateTask(taskModel: task);
      }
    }

    notifyListeners();
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
  }
}
