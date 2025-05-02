import 'package:flutter/material.dart';
import 'package:gamify_todo/Core/extensions.dart';
import 'package:gamify_todo/Core/helper.dart';
import 'package:gamify_todo/Service/global_timer.dart';
import 'package:gamify_todo/Service/notification_services.dart';
import 'package:gamify_todo/Service/server_manager.dart';
import 'package:gamify_todo/Service/home_widget_service.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/routine_model.dart';
import 'package:gamify_todo/Model/subtask_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Provider/category_provider.dart';
import 'package:gamify_todo/Provider/task_log_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (taskModel.routineID != null) {
      RoutineModel routine = routineList.firstWhere((element) => element.id == taskModel.routineID);

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

      ServerManager().updateRoutine(routineModel: routine);

      for (var task in taskList) {
        if (task.routineID == taskModel.routineID) {
          task.title = taskModel.title;
          task.description = taskModel.description;
          task.attributeIDList = taskModel.attributeIDList;
          task.skillIDList = taskModel.skillIDList;
          task.remainingDuration = task.taskDate.isSameDay(DateTime.now()) ? taskModel.remainingDuration : task.remainingDuration;
          task.targetCount = task.taskDate.isSameDay(DateTime.now()) ? taskModel.targetCount : task.targetCount;
          task.isNotificationOn = taskModel.isNotificationOn;
          task.time = taskModel.time;
          task.priority = taskModel.priority;

          if (task.isTimerActive != null && task.isTimerActive!) {
            GlobalTimer().startStopTimer(taskModel: task);
          }

          checkNotification(task);

          ServerManager().updateTask(taskModel: task);
        }
      }
    } else {
      final index = taskList.indexWhere((element) => element.id == taskModel.id);
      taskList[index] = taskModel;

      if (taskModel.isTimerActive != null && taskModel.isTimerActive!) {
        GlobalTimer().startStopTimer(taskModel: taskModel);
      }

      checkNotification(taskModel);

      ServerManager().updateTask(taskModel: taskModel);
    }

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
  }) async {
    DateTime? selectedDate = await Helper().selectDate(
      context: context,
      initialDate: taskModel.taskDate,
    );

    if (selectedDate != null) {
      if (taskModel.time != null) {
        selectedDate = selectedDate.copyWith(hour: taskModel.time!.hour, minute: taskModel.time!.minute);
      }

      if (taskModel.type == TaskTypeEnum.TIMER && taskModel.isTimerActive == true) {
        taskModel.isTimerActive = false;
      }
      taskModel.taskDate = selectedDate;

      ServerManager().updateTask(taskModel: taskModel);

      checkNotification(taskModel);
    }

    notifyListeners();
  }

  // Update task date without showing a dialog (for drag and drop functionality)
  void changeTaskDateWithoutDialog({
    required TaskModel taskModel,
    required DateTime newDate,
  }) {
    // Preserve the time if it exists
    if (taskModel.time != null) {
      newDate = newDate.copyWith(hour: taskModel.time!.hour, minute: taskModel.time!.minute);
    }

    // Stop timer if active
    if (taskModel.type == TaskTypeEnum.TIMER && taskModel.isTimerActive == true) {
      taskModel.isTimerActive = false;
    }

    // Update the task date
    taskModel.taskDate = newDate;

    // Update in storage
    ServerManager().updateTask(taskModel: taskModel);

    // Update notifications
    checkNotification(taskModel);

    notifyListeners();
  }

  // Task durumu değiştiğinde bildirimleri kontrol et
  void checkTaskStatusForNotifications(TaskModel taskModel) {
    // Eğer task tamamlandıysa, iptal edildiyse veya başarısız olduysa bildirimleri iptal et
    if (taskModel.status == TaskStatusEnum.COMPLETED || taskModel.status == TaskStatusEnum.CANCEL || taskModel.status == TaskStatusEnum.FAILED) {
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
    // Önce mevcut bildirimi iptal et
    NotificationService().cancelNotificationOrAlarm(taskModel.id);

    // Eğer task tamamlandıysa, iptal edildiyse veya başarısız olduysa bildirim oluşturma
    if (taskModel.status == TaskStatusEnum.COMPLETED || taskModel.status == TaskStatusEnum.CANCEL || taskModel.status == TaskStatusEnum.FAILED) {
      return;
    }

    // Bildirim veya alarm açıksa ve zaman ayarlanmışsa
    if (taskModel.time != null && (taskModel.isNotificationOn || taskModel.isAlarmOn)) {
      // Görev zamanı gelecekteyse bildirim planla
      DateTime taskDateTime = taskModel.taskDate.copyWith(hour: taskModel.time!.hour, minute: taskModel.time!.minute, second: 0);

      if (taskDateTime.isAfter(DateTime.now())) {
        NotificationService().scheduleNotification(
          id: taskModel.id,
          title: taskModel.title,
          desc: "Don't forget!",
          scheduledDate: taskDateTime,
          isAlarm: taskModel.isAlarmOn,
          earlyReminderMinutes: taskModel.earlyReminderMinutes,
        );
      }
    }
  }

  // iptal de kullanıcıya ceza yansıtılmayacak
  cancelTask(TaskModel taskModel) {
    if (taskModel.status == TaskStatusEnum.CANCEL) {
      // If already cancelled, set to null (in progress)
      taskModel.status = null;

      // Create log for the status change to null (in progress)
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: null, // null status means "in progress"
      );
    } else {
      // Set to cancelled, clearing any other status
      taskModel.status = TaskStatusEnum.CANCEL;

      // Create log for cancelled task
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.CANCEL,
      );
    }

    ServerManager().updateTask(taskModel: taskModel);
    HomeWidgetService.updateTaskCount();

    // Bildirim durumunu kontrol et
    checkTaskStatusForNotifications(taskModel);

    // TODO: iptalde veya silem durumunda geri almak için mesaj çıkacak bir süre
    notifyListeners();
  }

  failedTask(TaskModel taskModel) {
    if (taskModel.status == TaskStatusEnum.FAILED) {
      // If already failed, set to null (in progress)
      taskModel.status = null;

      // Create log for the status change to null (in progress)
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: null, // null status means "in progress"
      );
    } else {
      // Set to failed, clearing any other status
      taskModel.status = TaskStatusEnum.FAILED;

      // Create log for failed task
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.FAILED,
      );
    }

    ServerManager().updateTask(taskModel: taskModel);
    HomeWidgetService.updateTaskCount();

    // Bildirim durumunu kontrol et
    checkTaskStatusForNotifications(taskModel);

    // TODO: iptalde veya silem durumunda geri almak için mesaj çıkacak bir süre
    notifyListeners();
  }

  // Delete a task and its associated logs
  Future<void> deleteTask(TaskModel taskModel) async {
    // First delete all logs associated with this task
    await TaskLogProvider().deleteLogsByTaskId(taskModel.id);

    // Remove the task from the list
    taskList.remove(taskModel);

    // Delete the task from storage
    await ServerManager().deleteTask(id: taskModel.id);
    HomeWidgetService.updateTaskCount();

    // Cancel any notifications for this task
    NotificationService().cancelNotificationOrAlarm(taskModel.id);

    // TODO: iptalde veya silem durumunda geri almak için mesaj çıkacak bir süre
    notifyListeners();
  }

  // Delete routine
  Future<void> deleteRoutine(int routineID) async {
    final routineModel = routineList.firstWhere((element) => element.id == routineID);

    // Delete all logs associated with this routine
    await TaskLogProvider().deleteLogsByRoutineId(routineID);

    // Delete all associated tasks and their logs
    final tasksToDelete = taskList.where((task) => task.routineID == routineID).toList();
    for (final task in tasksToDelete) {
      // Delete logs for each task
      await TaskLogProvider().deleteLogsByTaskId(task.id);

      // Cancel notifications
      NotificationService().cancelNotificationOrAlarm(task.id);

      // Delete the task
      await ServerManager().deleteTask(id: task.id);
      taskList.remove(task);
    }

    // Delete the routine
    routineList.remove(routineModel);
    await ServerManager().deleteRoutine(id: routineModel.id);

    HomeWidgetService.updateTaskCount();
    notifyListeners();
  }

  // TODO: just for routine
  // ? rutin model mi task model mi
  completeRoutine(TaskModel taskModel) {
    // Clear any existing status before setting to COMPLETED
    taskModel.status = TaskStatusEnum.COMPLETED;

    ServerManager().updateTask(taskModel: taskModel);
    HomeWidgetService.updateTaskCount();

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

  // Subtask methods
  void addSubtask(TaskModel taskModel, String subtaskTitle) {
    taskModel.subtasks ??= [];

    // Generate a unique ID for the subtask
    int subtaskId = 1;
    if (taskModel.subtasks!.isNotEmpty) {
      subtaskId = taskModel.subtasks!.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    }

    final subtask = SubTaskModel(
      id: subtaskId,
      title: subtaskTitle,
    );

    taskModel.subtasks!.add(subtask);
    ServerManager().updateTask(taskModel: taskModel);

    notifyListeners();
  }

  void removeSubtask(TaskModel taskModel, SubTaskModel subtask) {
    if (taskModel.subtasks != null) {
      taskModel.subtasks!.removeWhere((s) => s.id == subtask.id);
      ServerManager().updateTask(taskModel: taskModel);

      notifyListeners();
    }
  }

  void toggleSubtaskCompletion(TaskModel taskModel, SubTaskModel subtask) {
    if (taskModel.subtasks != null) {
      final index = taskModel.subtasks!.indexWhere((s) => s.id == subtask.id);
      if (index != -1) {
        bool wasCompleted = taskModel.subtasks![index].isCompleted;
        taskModel.subtasks![index].isCompleted = !wasCompleted;
        ServerManager().updateTask(taskModel: taskModel);

        // Alt görev tamamlandığında log oluştur
        if (!wasCompleted) {
          // Alt görev tamamlandı
          TaskLogProvider().addTaskLog(
            taskModel,
            customStatus: TaskStatusEnum.COMPLETED,
          );
        }

        notifyListeners();
      }
    }
  }

  void updateSubtask(TaskModel taskModel, SubTaskModel subtask, String title, String? description) {
    if (taskModel.subtasks != null) {
      final index = taskModel.subtasks!.indexWhere((s) => s.id == subtask.id);
      if (index != -1) {
        // Update the subtask with new title and description
        taskModel.subtasks![index].title = title;
        taskModel.subtasks![index].description = description;

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
    if (!showCompleted) {
      tasks = taskList.where((task) => task.checkForThisDate(date, isRoutine: false, isCompleted: true)).toList();
    } else {
      tasks = taskList.where((task) => task.checkForThisDate(date, isRoutine: false, isCompleted: false)).toList();
    }

    sortTasksByPriorityAndTime(tasks);
    return tasks;
  }

  List<TaskModel> getRoutineTasksForDate(DateTime date) {
    List<TaskModel> tasks;
    if (!showCompleted) {
      tasks = taskList.where((task) => task.checkForThisDate(date, isRoutine: true, isCompleted: true)).toList();
    } else {
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
              subtasks: [],
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
      // First sort by date
      int dateCompare = a.taskDate.compareTo(b.taskDate);
      if (dateCompare != 0) return dateCompare;

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
      // First sort by date
      int dateCompare = a.taskDate.compareTo(b.taskDate);
      if (dateCompare != 0) return dateCompare;

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
}
