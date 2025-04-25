import 'package:flutter/material.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Enum/task_type_enum.dart';
import 'package:gamify_todo/Model/task_log_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Service/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskLogProvider with ChangeNotifier {
  static final TaskLogProvider _instance = TaskLogProvider._internal();

  factory TaskLogProvider() {
    return _instance;
  }

  TaskLogProvider._internal();

  List<TaskLogModel> taskLogList = [];

  Future<void> loadTaskLogs() async {
    taskLogList = await HiveService().getTaskLogs();
    notifyListeners();
  }

  Future<void> addTaskLog(
    TaskModel taskModel, {
    DateTime? customLogDate,
    Duration? customDuration,
    int? customCount,
    TaskStatusEnum? customStatus,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int logId = prefs.getInt("last_task_log_id") ?? 0;

    final TaskLogModel taskLog = TaskLogModel(
      id: logId + 1,
      taskId: taskModel.id,
      routineId: taskModel.routineID,
      logDate: customLogDate ?? DateTime.now(), // DateTime.now() already includes seconds and milliseconds
      taskTitle: taskModel.title,
      duration: customDuration ?? (taskModel.type == TaskTypeEnum.TIMER ? taskModel.currentDuration : null),
      count: customCount ?? (taskModel.type == TaskTypeEnum.COUNTER ? taskModel.currentCount : null),
      // Eğer customStatus açıkça null olarak verilmişse, bu checkbox'ın hiçbir durumunun seçili olmadığını gösterir
      // Ancak UI'da bu, hiçbir durumun seçili olmadığını gösterecek
      status: customStatus ?? taskModel.status,
    );

    await HiveService().addTaskLog(taskLog);
    taskLogList.add(taskLog);

    await prefs.setInt("last_task_log_id", taskLog.id);

    notifyListeners();
  }

  List<TaskLogModel> getLogsByTaskId(int taskId) {
    return taskLogList.where((log) => log.taskId == taskId).toList();
  }

  List<TaskLogModel> getLogsByRoutineId(int routineId) {
    return taskLogList.where((log) => log.routineId == routineId).toList();
  }

  List<TaskLogModel> getRecentLogs(int count) {
    // Sort logs by date (newest first) and return the specified count
    final sortedLogs = List<TaskLogModel>.from(taskLogList);
    sortedLogs.sort((a, b) => b.logDate.compareTo(a.logDate));

    return sortedLogs.take(count).toList();
  }
}
