import 'package:flutter/material.dart';
import 'package:gamify_todo/Enum/task_status_enum.dart';
import 'package:gamify_todo/Model/task_log_model.dart';
import 'package:gamify_todo/Model/task_model.dart';
import 'package:gamify_todo/Provider/task_provider.dart';
import 'package:gamify_todo/Service/hive_service.dart';
import 'package:gamify_todo/Service/server_manager.dart';
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
    final int lastLogId = prefs.getInt("last_task_log_id") ?? 0;

    // Find the highest ID among existing logs to ensure uniqueness
    int highestLogId = lastLogId;
    for (final log in taskLogList) {
      if (log.id > highestLogId) {
        highestLogId = log.id;
      }
    }

    final TaskLogModel taskLog = TaskLogModel(
      id: highestLogId + 1,
      taskId: taskModel.id,
      routineId: taskModel.routineID,
      logDate: customLogDate ?? DateTime.now(), // DateTime.now() already includes seconds and milliseconds
      taskTitle: taskModel.title,
      // Eğer customDuration açıkça verilmişse, o değeri kullan
      // Aksi takdirde, sadece checkbox olmayan ve customDuration null olan durumlarda taskModel.currentDuration kullan
      duration: customDuration,
      // Eğer customCount açıkça verilmişse, o değeri kullan
      // Aksi takdirde, sadece counter olan ve customCount null olan durumlarda taskModel.currentCount kullan
      count: customCount,
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

  // Delete all logs associated with a specific task
  Future<void> deleteLogsByTaskId(int taskId) async {
    // Get all logs for this task
    final logsToDelete = taskLogList.where((log) => log.taskId == taskId).toList();

    // Delete each log from Hive
    for (final log in logsToDelete) {
      await HiveService().deleteTaskLog(log.id);
      taskLogList.remove(log);
    }

    // Find the task in TaskProvider and reset its status to null
    final taskProvider = TaskProvider();
    final taskIndex = taskProvider.taskList.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      // Reset task status to null
      taskProvider.taskList[taskIndex].status = null;
      // Update task in storage
      await ServerManager().updateTask(taskModel: taskProvider.taskList[taskIndex]);
    }

    notifyListeners();
  }

  // Delete all logs associated with a specific routine
  Future<void> deleteLogsByRoutineId(int routineId) async {
    // Get all logs for this routine
    final logsToDelete = taskLogList.where((log) => log.routineId == routineId).toList();

    // Delete each log from Hive
    for (final log in logsToDelete) {
      await HiveService().deleteTaskLog(log.id);
      taskLogList.remove(log);
    }

    // Find all tasks associated with this routine and reset their status to null
    final taskProvider = TaskProvider();
    final tasksToReset = taskProvider.taskList.where((task) => task.routineID == routineId).toList();

    for (final task in tasksToReset) {
      // Reset task status to null
      task.status = null;
      // Update task in storage
      await ServerManager().updateTask(taskModel: task);
    }

    notifyListeners();
  }

  // Clear all logs from the provider (used when deleting all data)
  Future<void> clearAllLogs() async {
    taskLogList.clear();

    // Reset status of all tasks to null
    final taskProvider = TaskProvider();
    for (final task in taskProvider.taskList) {
      task.status = null;
      await ServerManager().updateTask(taskModel: task);
    }

    notifyListeners();
  }
}
