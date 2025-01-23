import 'package:flutter/material.dart';
import 'package:gamify_todo/1%20Core/extensions.dart';
import 'package:gamify_todo/1%20Core/helper.dart';
import 'package:gamify_todo/5%20Service/notification_services.dart';
import 'package:gamify_todo/5%20Service/server_manager.dart';
import 'package:gamify_todo/5%20Service/home_widget_service.dart';
import 'package:gamify_todo/7%20Enum/task_status_enum.dart';
import 'package:gamify_todo/7%20Enum/task_type_enum.dart';
import 'package:gamify_todo/8%20Model/routine_model.dart';
import 'package:gamify_todo/8%20Model/task_model.dart';

class TaskProvider with ChangeNotifier {
  // burayı singelton yaptım gayet de iyi oldu neden normalde de context den kullanıyoruz anlamadım. galiba "watch" için olabilir. sibelton kısmını global timer için yaptım.
  static final TaskProvider _instance = TaskProvider._internal();

  factory TaskProvider() {
    return _instance;
  }

  TaskProvider._internal();

  List<RoutineModel> routineList = [];

  List<TaskModel> taskList = [];

  // TODO: saat 00:00:00 geçtikten sonra hala dünü gösterecek muhtemelen her ana sayfaya gidişte. bunu düzelt. yani değişken uygulama açıldığında belirlendiği için 12 den sonra değişmeyecek.
  DateTime selectedDate = DateTime.now();
  bool showCompleted = true;

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
      RoutineModel routine = routineList.where((element) => element.id == taskModel.routineID).first;

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
          task.remainingDuration = taskModel.remainingDuration;
          task.targetCount = taskModel.targetCount;
          task.isNotificationOn = taskModel.isNotificationOn;
          task.time = taskModel.time;
          task.priority = taskModel.priority;

          ServerManager().updateTask(taskModel: task);
        }
      }
    } else {
      final index = taskList.indexWhere((element) => element.id == taskModel.id);
      taskList[index] = taskModel;

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

  checkNotification(TaskModel taskModel) {
    if (taskModel.time != null && (taskModel.isNotificationOn || taskModel.isAlarmOn)) {
      if (taskModel.taskDate.copyWith(hour: taskModel.time!.hour, minute: taskModel.time!.minute, second: 0).isAfter(DateTime.now())) {
        NotificationService().scheduleNotification(
          id: taskModel.id,
          title: taskModel.title,
          desc: "Don't forget!",
          scheduledDate: taskModel.taskDate.copyWith(hour: taskModel.time!.hour, minute: taskModel.time!.minute, second: 0),
          isAlarm: taskModel.isAlarmOn,
        );
      } else {
        NotificationService().cancelNotificationOrAlarm(taskModel.id);
      }
    }
  }

  // iptal de kullanıcıya ceza yansıtılmayacak
  cancelTask(TaskModel taskModel) {
    if (taskModel.status == TaskStatusEnum.CANCEL) {
      if (taskModel.type == TaskTypeEnum.COUNTER && taskModel.currentCount! >= taskModel.targetCount!) {
        taskModel.status = TaskStatusEnum.COMPLETED;
      } else if (taskModel.type == TaskTypeEnum.TIMER && taskModel.currentDuration! >= taskModel.remainingDuration!) {
        taskModel.status = TaskStatusEnum.COMPLETED;
      } else {
        taskModel.status = null;
      }
    } else {
      taskModel.status = TaskStatusEnum.CANCEL;
    }

    ServerManager().updateTask(taskModel: taskModel);
    HomeWidgetService.updateTaskCount();

    // TODO: iptalde veya silem durumunda geri almak için mesaj çıkacak bir süre
    notifyListeners();
  }

  failedTask(TaskModel taskModel) {
    if (taskModel.status == TaskStatusEnum.FAILED) {
      taskModel.status = null;
    } else {
      taskModel.status = TaskStatusEnum.FAILED;
    }

    ServerManager().updateTask(taskModel: taskModel);
    HomeWidgetService.updateTaskCount();

    // TODO: iptalde veya silem durumunda geri almak için mesaj çıkacak bir süre
    notifyListeners();
  }

  // TODO: delete
  deleteTask(TaskModel taskModel) {
    taskList.remove(taskModel);

    ServerManager().deleteTask(id: taskModel.id);
    HomeWidgetService.updateTaskCount();

    NotificationService().cancelNotificationOrAlarm(taskModel.id);

    // TODO: iptalde veya silem durumunda geri almak için mesaj çıkacak bir süre
    notifyListeners();
  }

  // Delete routine
  Future<void> deleteRoutine(int routineID) async {
    final routineModel = routineList.firstWhere((element) => element.id == routineID);

    // Delete all associated tasks
    final tasksToDelete = taskList.where((task) => task.routineID == routineID).toList();
    for (final task in tasksToDelete) {
      NotificationService().cancelNotificationOrAlarm(task.id);
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
    taskModel.status = TaskStatusEnum.COMPLETED;

    ServerManager().updateTask(taskModel: taskModel);
    HomeWidgetService.updateTaskCount();
    // TODO: iptalde veya silem durumunda geri almak için mesaj çıkacak bir süre
    // TODO: arşivden çıkar ekle
    notifyListeners();
  }

  void changeShowCompleted() {
    showCompleted = !showCompleted;

    notifyListeners();
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
      tasks = taskList.where((task) => task.taskDate.isSameDay(date) && task.routineID == null && task.status == null && !(task.type == TaskTypeEnum.TIMER && task.isTimerActive == true)).toList();
    } else {
      tasks = taskList.where((task) => task.taskDate.isSameDay(date) && task.routineID == null).toList();
    }

    sortTasksByPriorityAndTime(tasks);
    return tasks;
  }

  List<TaskModel> getRoutineTasksForDate(DateTime date) {
    List<TaskModel> tasks;
    if (!showCompleted) {
      tasks = taskList.where((task) => task.taskDate.isSameDay(date) && task.routineID != null && task.status == null && !(task.type == TaskTypeEnum.TIMER && task.isTimerActive == true)).toList();
    } else {
      tasks = taskList.where((task) => task.taskDate.isSameDay(date) && task.routineID != null).toList();
    }

    sortTasksByPriorityAndTime(tasks);
    return tasks;
  }

  List<TaskModel> getGhostRoutineTasksForDate(DateTime date) {
    if (date.isBeforeOrSameDay(DateTime.now())) {
      return [];
    }

    List<TaskModel> tasks = routineList
        .where((routine) => routine.repeatDays.contains(date.weekday - 1) && routine.startDate.isBeforeOrSameDay(date) && !routine.isArchived)
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
            ))
        .toList();

    sortTasksByPriorityAndTime(tasks);
    return tasks;
  }
}
